const mongoose = require('mongoose');

const tokenSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    tokenNumber: {
      type: Number,
      required: true,
    },
    status: {
      type: String,
      enum: ['waiting', 'serving', 'completed', 'cancelled'],
      default: 'waiting',
    },
    estimatedWaitMinutes: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

tokenSchema.index({ shopId: 1, status: 1, tokenNumber: 1 });

module.exports = mongoose.model('Token', tokenSchema);
