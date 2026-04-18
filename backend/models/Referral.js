const mongoose = require('mongoose');

const referralSchema = new mongoose.Schema(
  {
    referrerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    refereeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    referralCode: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'rewarded'],
      default: 'pending',
    },
    rewardType: {
      type: String,
      enum: ['wallet_credit', 'premium_days', 'badge'],
      default: 'wallet_credit',
    },
    rewardAmount: {
      type: Number,
      default: 50, // ₹50 default referral reward
    },
    completedAt: {
      type: Date,
      default: null,
    },
    rewardedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

referralSchema.index({ referrerId: 1, createdAt: -1 });
referralSchema.index({ refereeId: 1 }, { unique: true });
referralSchema.index({ referralCode: 1 });

module.exports = mongoose.model('Referral', referralSchema);
