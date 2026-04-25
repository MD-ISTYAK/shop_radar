const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['new_post', 'offer', 'story', 'token_update', 'shop_open', 'follow', 'like', 'comment', 'delivery', 'reply', 'mention', 'story_view', 'reel_like'],
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    body: {
      type: String,
      default: '',
    },
    // New fields for strict Social architecture
    actorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    postId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
    },
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    read: {
      type: Boolean,
      default: false,
    },
    // Alias for strict schema
    isRead: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

// Pre-save hook to keep read and isRead synced
notificationSchema.pre('save', function (next) {
  if (this.isModified('isRead') && !this.isModified('read')) {
    this.read = this.isRead;
  }
  if (this.isModified('read') && !this.isModified('isRead')) {
    this.isRead = this.read;
  }
  next();
});

notificationSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
