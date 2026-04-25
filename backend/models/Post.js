const mongoose = require('mongoose');

const postSchema = new mongoose.Schema(
  {
    // User-centric: the author of the post
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // Backward compat: shop reference (populated for shop posts)
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
    },
    // Backward compat: owner reference
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    caption: {
      type: String,
      default: '',
      maxlength: 2200, // per spec
    },
    // Alias for backward compatibility
    content: {
      type: String,
      default: '',
    },
    media: [
      {
        type: { type: String, enum: ['image', 'video'], required: true },
        url: { type: String, required: true }, // Optimized Cloudinary URL
        thumbnailUrl: { type: String, default: '' }, // For videos
      },
    ],
    // Backward compat fields
    mediaUrl: { type: String, default: '' },
    mediaType: { type: String, enum: ['image', 'video'], default: 'image' },
    images: { type: [String], default: [] },
    videoUrl: { type: String, default: '' },
    thumbnailUrl: { type: String, default: '' },

    // Denormalized user data for faster feed loading
    userSnapshot: {
      username: { type: String, default: '' },
      avatarUrl: { type: String, default: '' },
    },
    type: {
      type: String,
      enum: ['post', 'reel'],
      default: 'post',
    },
    hashTags: {
      type: [String],
      default: [],
    },
    likesCount: {
      type: Number,
      default: 0,
    },
    commentsCount: {
      type: Number,
      default: 0,
    },
    savedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    shares: {
      type: Number,
      default: 0,
    },
    viewCount: {
      type: Number,
      default: 0,
    },
    duration: {
      type: Number,
      default: 0, // video duration in seconds (for reels)
    },
    isHidden: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

// Pre-validate hook for backward compatibility
postSchema.pre('validate', function (next) {
  if (this.isModified('caption') && !this.isModified('content')) {
    this.content = this.caption;
  }
  if (this.isModified('content') && !this.isModified('caption')) {
    this.caption = this.content;
  }
  next();
});

// Indexes per tech spec
postSchema.index({ userId: 1, createdAt: -1 });
postSchema.index({ createdAt: -1 }); // discovery feed
postSchema.index({ shopId: 1, createdAt: -1 }); // backward compat
postSchema.index({ type: 1, createdAt: -1 });

module.exports = mongoose.model('Post', postSchema);
