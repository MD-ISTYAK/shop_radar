const mongoose = require('mongoose');

const moderationLogSchema = new mongoose.Schema(
  {
    adminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    videoId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
    },
    targetUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    action: {
      type: String,
      enum: ['approved', 'deleted', 'hidden', 'strike_added', 'user_banned', 'user_unbanned', 'visibility_changed'],
      required: true,
    },
    reason: {
      type: String,
      default: '',
    },
    previousStatus: {
      type: String,
      default: '',
    },
    newStatus: {
      type: String,
      default: '',
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  { timestamps: true }
);

moderationLogSchema.index({ adminId: 1, createdAt: -1 });
moderationLogSchema.index({ videoId: 1 });
moderationLogSchema.index({ targetUserId: 1 });
moderationLogSchema.index({ action: 1, createdAt: -1 });

module.exports = mongoose.model('ModerationLog', moderationLogSchema);
