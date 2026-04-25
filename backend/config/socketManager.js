const jwt = require('jsonwebtoken');
const User = require('../models/User');

let io = null;
const connectedUsers = new Map(); // userId -> socketId

const initSocket = (server) => {
  const { Server } = require('socket.io');
  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  // Auth middleware for socket connections
  io.use((socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.query.token;
    if (!token) return next(new Error('Authentication required'));

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.id;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`🔌 User connected: ${socket.userId}`);

    // Join user-specific room
    socket.join(`user:${socket.userId}`);
    connectedUsers.set(socket.userId, socket.id);

    // Update user online status
    const updateOnlineStatus = async (isOnline) => {
      try {
        await User.findByIdAndUpdate(socket.userId, {
          isOnline,
          lastSeen: new Date()
        });
        // Broadcast to friends/chats that this user is online/offline
        io.emit('user:statusChange', {
          userId: socket.userId,
          isOnline,
          lastSeen: new Date()
        });
      } catch (err) {
        console.error('Error updating online status:', err);
      }
    };

    updateOnlineStatus(true);

    // Join shop room (for owners)
    socket.on('join:shop', (shopId) => {
      socket.join(`shop:${shopId}`);
      console.log(`👤 User ${socket.userId} joined shop:${shopId}`);
    });

    // Join delivery tracking room
    socket.on('join:delivery', (deliveryId) => {
      socket.join(`delivery:${deliveryId}`);
    });

    // Delivery partner location update
    socket.on('delivery:location', (data) => {
      // Broadcast to everyone tracking this delivery
      io.to(`delivery:${data.deliveryId}`).emit('delivery:locationUpdate', {
        deliveryId: data.deliveryId,
        lat: data.lat,
        lng: data.lng,
        timestamp: Date.now(),
      });
    });

    // Queue updates (owner advances queue)
    socket.on('queue:advance', (data) => {
      io.to(`shop:${data.shopId}`).emit('queue:update', {
        shopId: data.shopId,
        currentToken: data.currentToken,
        totalWaiting: data.totalWaiting,
      });
    });

    // Shop status change
    socket.on('shop:statusChange', (data) => {
      io.to(`shop:${data.shopId}`).emit('shop:statusUpdate', {
        shopId: data.shopId,
        status: data.status,
        crowdLevel: data.crowdLevel,
      });
    });

    // Live stream events
    socket.on('stream:start', (data) => {
      socket.join(`stream:${data.shopId}`);
      io.to(`shop:${data.shopId}`).emit('stream:started', {
        shopId: data.shopId,
        streamerId: socket.userId,
      });
    });

    socket.on('stream:comment', (data) => {
      io.to(`stream:${data.shopId}`).emit('stream:newComment', {
        userId: socket.userId,
        text: data.text,
        timestamp: Date.now(),
      });
    });

    socket.on('stream:end', (data) => {
      io.to(`stream:${data.shopId}`).emit('stream:ended', {
        shopId: data.shopId,
      });
      socket.leave(`stream:${data.shopId}`);
    });

    socket.on('disconnect', () => {
      console.log(`🔌 User disconnected: ${socket.userId}`);
      connectedUsers.delete(socket.userId);
      updateOnlineStatus(false);
    });

    // Message status updates
    socket.on('message:received', async (data) => {
      // data: { messageId, senderId }
      try {
        const Message = require('../models/Message');
        await Message.findByIdAndUpdate(data.messageId, { status: 'delivered' });
        
        io.to(`user:${data.senderId}`).emit('message:statusUpdate', {
          messageId: data.messageId,
          status: 'delivered'
        });
      } catch (err) {
        console.error('Error updating message received status:', err);
      }
    });

    socket.on('message:seen', async (data) => {
      // data: { conversationId, senderId }
      try {
        const Message = require('../models/Message');
        // Mark all messages in this conversation as seen for the sender
        await Message.updateMany(
          { conversationId: data.conversationId, receiverId: socket.userId, status: { $ne: 'seen' } },
          { status: 'seen', read: true }
        );
        
        io.to(`user:${data.senderId}`).emit('message:statusUpdate', {
          conversationId: data.conversationId,
          status: 'seen'
        });
      } catch (err) {
        console.error('Error updating message seen status:', err);
      }
    });
  });

  return io;
};

const getIO = () => {
  if (!io) throw new Error('Socket.io not initialized');
  return io;
};

// Helper to send notification to a specific user
const sendToUser = (userId, event, data) => {
  if (io) {
    io.to(`user:${userId}`).emit(event, data);
  }
};

// Helper to broadcast to a shop room
const sendToShop = (shopId, event, data) => {
  if (io) {
    io.to(`shop:${shopId}`).emit(event, data);
  }
};

module.exports = { initSocket, getIO, sendToUser, sendToShop };
