const Message = require('../models/Message');
const Shop = require('../models/Shop');
const User = require('../models/User');
const { sendToUser } = require('../config/socketManager');

// @desc    Send a message (user to shop or shop to user)
// @route   POST /api/chat/send
const sendMessage = async (req, res, next) => {
  try {
    let { receiverId, shopId, text, sharedPostId, sharedStoryId } = req.body;
    const senderId = req.user._id;

    // Fallback: If shopId is missing but user is a shop, find their shop
    if (!shopId && req.user.accountType === 'shop') {
      const myShop = await Shop.findOne({ ownerId: senderId });
      if (myShop) shopId = myShop._id;
    }

    let mediaUrl = '';
    let mediaType = 'text';

    if (req.file) {
      mediaUrl = req.file.path;
      if (req.file.mimetype.startsWith('video/')) {
        mediaType = 'video';
      } else if (req.file.mimetype.startsWith('audio/')) {
        mediaType = 'audio';
      } else {
        mediaType = 'image';
      }
    }

    if ((!text || !text.trim()) && !mediaUrl) {
      return res.status(400).json({ success: false, message: 'Message text or media is required' });
    }
    if (!receiverId) {
      return res.status(400).json({ success: false, message: 'receiverId is required' });
    }

    const conversationId = Message.getConversationId(senderId.toString(), receiverId);

    const message = await Message.create({
      conversationId,
      senderId,
      receiverId,
      shopId: shopId || null,
      text: text ? text.trim() : '',
      mediaUrl,
      mediaType,
      sharedPostId: sharedPostId || null,
      sharedStoryId: sharedStoryId || null,
    });

    await message.populate('senderId', 'name');

    // Notify receiver via socket
    sendToUser(receiverId, 'notification:new', {
      type: 'message',
      title: `New message from ${req.user.name}`,
      body: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
      data: {
        conversationId,
        senderId: senderId.toString(),
        messageId: message._id,
      }
    });

    // Also emit message directly if they are in the chat
    sendToUser(receiverId, 'message:new', message);

    res.status(201).json({ success: true, data: message });
  } catch (error) {
    next(error);
  }
};

// @desc    Get conversations list (unique chats)
// @route   GET /api/chat/conversations
const getConversations = async (req, res, next) => {
  try {
    const userId = req.user._id.toString();

    // Get the latest message from each conversation the user is part of
    const conversations = await Message.aggregate([
      {
        $match: {
          $or: [
            { senderId: req.user._id },
            { receiverId: req.user._id },
          ],
        },
      },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: '$conversationId',
          lastMessage: { $first: '$$ROOT' },
          unreadCount: {
            $sum: {
              $cond: [
                { $and: [
                  { $eq: ['$receiverId', req.user._id] },
                  { $eq: ['$read', false] },
                ]},
                1,
                0,
              ],
            },
          },
        },
      },
      { $sort: { 'lastMessage.createdAt': -1 } },
    ]);

    // Populate the other user and shop info
    const populatedConversations = await Promise.all(
      conversations.map(async (conv) => {
        const msg = conv.lastMessage;
        const otherUserId = msg.senderId.toString() === userId ? msg.receiverId : msg.senderId;
        
        // Use Promise.all for faster secondary lookups
        const [otherUser, shop] = await Promise.all([
          User.findById(otherUserId).select('name username phone profilePic avatar isOnline lastSeen'),
          (async () => {
            let sId = msg.shopId;
            // Fallback 1: If last message has no shopId, find ANY message in this conversation with a shopId
            if (!sId) {
              const msgWithShop = await Message.findOne({ conversationId: conv._id, shopId: { $ne: null } }).select('shopId');
              if (msgWithShop) sId = msgWithShop.shopId;
            }
            // Fallback 2: If still no shopId and user is shop owner, use their shop
            if (!sId && req.user.accountType === 'shop') {
              const Shop = require('../models/Shop');
              const myShop = await Shop.findOne({ ownerId: userId }).select('_id');
              if (myShop) sId = myShop._id;
            }
            
            if (!sId) return null;
            const Shop = require('../models/Shop');
            return await Shop.findById(sId).select('shopName logo ownerId');
          })()
        ]);

        return {
          conversationId: conv._id,
          otherUser: otherUser ? {
            _id: otherUser._id,
            name: otherUser.name,
            username: otherUser.username,
            phone: otherUser.phone,
            profilePic: otherUser.profilePic || otherUser.avatar,
            isOnline: otherUser.isOnline,
            lastSeen: otherUser.lastSeen,
          } : null,
          shop: shop ? { _id: shop._id, shopName: shop.shopName, logo: shop.logo, ownerId: shop.ownerId } : null,
          lastMessage: {
            text: msg.text,
            mediaType: msg.mediaType,
            createdAt: msg.createdAt,
            isMine: msg.senderId.toString() === userId,
          },
          unreadCount: conv.unreadCount,
        };
      })
    );

    res.status(200).json({ success: true, data: populatedConversations });
  } catch (error) {
    next(error);
  }
};

// @desc    Get messages in a conversation
// @route   GET /api/chat/messages/:conversationId?page=&limit=
const getMessages = async (req, res, next) => {
  try {
    const { conversationId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const messages = await Message.find({ conversationId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('senderId', 'name username profilePic avatar')
      .populate('sharedPostId', 'media videoUrl type content caption')
      .populate('sharedStoryId', 'mediaUrl mediaType caption');

    // Mark received messages as read
    await Message.updateMany(
      { conversationId, receiverId: req.user._id, read: false },
      { read: true }
    );

    res.status(200).json({
      success: true,
      count: messages.length,
      data: messages.reverse(), // oldest first for display
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Start a conversation with a shop (get or create)
// @route   POST /api/chat/start
const startConversation = async (req, res, next) => {
  try {
    const { shopId } = req.body;
    const userId = req.user._id.toString();

    const shop = await Shop.findById(shopId);
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });

    const ownerId = shop.ownerId.toString();
    if (ownerId === userId) {
      return res.status(400).json({ success: false, message: 'Cannot chat with your own shop' });
    }

    const conversationId = Message.getConversationId(userId, ownerId);
    const owner = await User.findById(ownerId).select('name username phone profilePic avatar isOnline lastSeen');

    res.status(200).json({
      success: true,
      data: {
        conversationId,
        otherUser: {
          _id: owner._id,
          name: owner.name,
          username: owner.username,
          phone: owner.phone,
          profilePic: owner.profilePic || owner.avatar,
          isOnline: owner.isOnline,
          lastSeen: owner.lastSeen,
        },
        shop: { _id: shop._id, shopName: shop.shopName, logo: shop.logo, ownerId: shop.ownerId },
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { sendMessage, getConversations, getMessages, startConversation };
