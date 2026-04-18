const mongoose = require('mongoose');

const badgeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    badgeName: {
      type: String,
      required: true,
      enum: [
        'explorer',        // Visit 10 different shops
        'foodie',           // Check in at 5 food shops
        'saver',            // Use 5 price-comparison deals
        'trendsetter',      // 3 reviews go viral (10+ upvotes)
        'super_shopper',    // 50 orders placed
        'shopradar_hero',   // Top referrer of the month
        'first_review',     // Write first review
        'social_butterfly', // Follow 20 shops
        'deal_hunter',      // Save 10 deals
        'loyal_customer',   // 30-day streak check-ins
      ],
    },
    earnedAt: {
      type: Date,
      default: Date.now,
    },
    criteria: {
      type: String,
      default: '',
    },
    progress: {
      type: Number,
      default: 0,
    },
    target: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

// One badge per user per badge type
badgeSchema.index({ userId: 1, badgeName: 1 }, { unique: true });

module.exports = mongoose.model('Badge', badgeSchema);
