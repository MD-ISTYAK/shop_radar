const Message = require('../models/Message');
const Shop = require('../models/Shop');
const User = require('../models/User');

// @desc    Send a message (user to shop or shop to user)
// @route   POST /api/chat/send
const sendMessage = async (req, res, next) => {
  try {
    const { receiverId, shopId, text } = req.body;
    const senderId = req.user._id;

    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Message text is required' });
    }
    if (!receiverId || !shopId) {
      return res.status(400).json({ success: false, message: 'receiverId and shopId are required' });
    }

    const conversationId = Message.getConversationId(senderId.toString(), receiverId);

    const message = await Message.create({
      conversationId,
      senderId,
      receiverId,
      shopId,
      text: text.trim(),
    });

    await message.populate('senderId', 'name');

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
        const otherUser = await User.findById(otherUserId).select('name phone');
        const shop = await Shop.findById(msg.shopId).select('shopName logo ownerId');

        return {
          conversationId: conv._id,
          otherUser: otherUser ? { _id: otherUser._id, name: otherUser.name, phone: otherUser.phone } : null,
          shop: shop ? { _id: shop._id, shopName: shop.shopName, logo: shop.logo, ownerId: shop.ownerId } : null,
          lastMessage: {
            text: msg.text,
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
      .populate('senderId', 'name');

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
    const owner = await User.findById(ownerId).select('name phone');

    res.status(200).json({
      success: true,
      data: {
        conversationId,
        otherUser: { _id: owner._id, name: owner.name },
        shop: { _id: shop._id, shopName: shop.shopName, logo: shop.logo, ownerId: shop.ownerId },
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { sendMessage, getConversations, getMessages, startConversation };
