const mongoose = require('mongoose');

const followSchema = new mongoose.Schema(
  {
    // The user performing the follow
    followerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // The user being followed (can be a regular user or shop account)
    followingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // Backward compat: if following a shop, store the shopId too
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
    },
  },
  { timestamps: true }
);

// CRITICAL: unique compound index to prevent duplicate follows
followSchema.index({ followerId: 1, followingId: 1 }, { unique: true });
// Fast lookup: "who follows this user?"
followSchema.index({ followingId: 1 });
// Backward compat: shop follows
followSchema.index({ followerId: 1, shopId: 1 }, { sparse: true });

module.exports = mongoose.model('Follow', followSchema);
