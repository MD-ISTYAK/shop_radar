const mongoose = require('mongoose');

const checkInSchema = new mongoose.Schema(
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
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number],
        required: true,
      },
    },
    microRating: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    loyaltyPointsEarned: {
      type: Number,
      default: 5,
    },
  },
  { timestamps: true }
);

checkInSchema.index({ shopId: 1, createdAt: -1 });
checkInSchema.index({ userId: 1, createdAt: -1 });
checkInSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('CheckIn', checkInSchema);
