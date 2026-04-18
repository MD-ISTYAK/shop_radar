const mongoose = require('mongoose');

const dealSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: [true, 'Deal title is required'],
      trim: true,
      maxlength: 200,
    },
    description: {
      type: String,
      default: '',
      maxlength: 1000,
    },
    image: {
      type: String,
      default: '',
    },
    originalPrice: {
      type: Number,
      default: 0,
    },
    dealPrice: {
      type: Number,
      default: 0,
    },
    discountPercent: {
      type: Number,
      default: 0,
    },
    expiresAt: {
      type: Date,
      required: [true, 'Deal expiry is required'],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    engagementCount: {
      type: Number,
      default: 0,
    },
    savedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    category: {
      type: String,
      default: 'general',
    },
  },
  { timestamps: true }
);

dealSchema.index({ shopId: 1, isActive: 1 });
dealSchema.index({ expiresAt: 1 });
dealSchema.index({ engagementCount: -1 });

module.exports = mongoose.model('Deal', dealSchema);
