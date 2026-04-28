const mongoose = require('mongoose');

const storySchema = new mongoose.Schema(
  {
    // User-centric: who created the story
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // Backward compat
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
    },
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    mediaUrl: {
      type: String,
      required: true,
    },
    // Backward compat alias
    imageUrl: {
      type: String,
      default: '',
    },
    mediaType: {
      type: String,
      enum: ['image', 'video'],
      default: 'image',
    },
    caption: {
      type: String,
      default: '',
      maxlength: 200,
    },
    // Interactive Elements (Polls, Links, Mentions, Questions, etc.)
    interactiveElements: [
      {
        type: { type: String }, // 'poll', 'mention', 'link', 'question', 'location', 'countdown', 'hashtag'
        x: { type: Number },
        y: { type: Number },
        scale: { type: Number, default: 1 },
        rotation: { type: Number, default: 0 },
        data: { type: mongoose.Schema.Types.Mixed }, // Custom data per sticker
      }
    ],
    // Background Music
    music: {
      songId: { type: String },
      url: { type: String },
      title: { type: String },
      artist: { type: String },
      duration: { type: Number },
      startTime: { type: Number, default: 0 },
    },
    viewers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    expiresAt: {
      type: Date,
      required: true,
      default: () => new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
    },
    isHidden: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

// TTL index — MongoDB auto-deletes documents when expiresAt is reached
storySchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
storySchema.index({ userId: 1, expiresAt: 1 });
storySchema.index({ shopId: 1, createdAt: -1 }); // backward compat

module.exports = mongoose.model('Story', storySchema);
