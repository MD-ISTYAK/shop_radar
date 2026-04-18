const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    rating: {
      type: Number,
      required: [true, 'Rating is required'],
      min: 1,
      max: 5,
    },
    text: {
      type: String,
      default: '',
      maxlength: 2000,
    },
    images: {
      type: [String],
      default: [],
    },
    upvotes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    ownerReply: {
      text: { type: String, default: '' },
      repliedAt: { type: Date, default: null },
    },
    isHidden: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

// One review per user per shop
reviewSchema.index({ userId: 1, shopId: 1 }, { unique: true });
reviewSchema.index({ shopId: 1, createdAt: -1 });

module.exports = mongoose.model('Review', reviewSchema);
