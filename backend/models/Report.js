const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema(
  {
    reporterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    targetType: {
      type: String,
      enum: ['post', 'user', 'comment', 'shop', 'story', 'reel'],
      required: true,
    },
    targetId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
    },
    reason: {
      type: String,
      enum: ['spam', 'harassment', 'nudity', 'misinformation', 'violence', 'hate_speech', 'scam', 'copyright', 'inappropriate', 'other'],
      required: true,
    },
    description: {
      type: String,
      default: '',
      maxlength: 500,
    },
    status: {
      type: String,
      enum: ['pending', 'reviewed', 'actioned', 'dismissed'],
      default: 'pending',
    },
    adminNote: {
      type: String,
      default: '',
    },
    actionTaken: {
      type: String,
      enum: ['none', 'content_hidden', 'content_deleted', 'user_warned', 'user_banned'],
      default: 'none',
    },
  },
  { timestamps: true }
);

reportSchema.index({ targetType: 1, targetId: 1 });
reportSchema.index({ status: 1, createdAt: -1 });
reportSchema.index({ reporterId: 1 });
// Prevent duplicate reports from same user on same target
reportSchema.index({ reporterId: 1, targetType: 1, targetId: 1 }, { unique: true });

module.exports = mongoose.model('Report', reportSchema);
