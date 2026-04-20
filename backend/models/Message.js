const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: String,
      required: true,
      index: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // Optional: shop context for shop-related messages
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
    },
    text: {
      type: String,
      default: '',
      maxlength: 2000,
    },
    // Media support for DMs
    mediaUrl: {
      type: String,
      default: '',
    },
    mediaType: {
      type: String,
      enum: ['text', 'image', 'video', 'audio'],
      default: 'text',
    },
    read: {
      type: Boolean,
      default: false,
    },
    status: {
      type: String,
      enum: ['sent', 'delivered', 'seen'],
      default: 'sent',
    },
  },
  { timestamps: true }
);

// Compound index for fast conversation lookups
messageSchema.index({ conversationId: 1, createdAt: 1 });

// Static method to generate consistent conversation ID from two user IDs
messageSchema.statics.getConversationId = function (userId1, userId2) {
  return [userId1, userId2].sort().join('_');
};

module.exports = mongoose.model('Message', messageSchema);
