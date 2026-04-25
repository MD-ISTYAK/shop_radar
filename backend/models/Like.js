const mongoose = require('mongoose');

const likeSchema = new mongoose.Schema(
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

// Compound unique index to prevent duplicate likes
likeSchema.index({ postId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('Like', likeSchema);
