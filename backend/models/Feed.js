const mongoose = require('mongoose');

const feedSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    postId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
      required: true,
    },
  },
  { timestamps: true }
);

// Precomputed feed is fetched by userId and sorted by time
feedSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Feed', feedSchema);
