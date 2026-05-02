const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    walletId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Wallet',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['credit', 'debit'],
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    description: {
      type: String,
      required: true,
    },
    referenceType: {
      type: String,
      enum: ['order', 'delivery', 'referral', 'topup', 'withdrawal', 'reward', 'premium', 'refund'],
      default: 'order',
    },
    referenceId: {
      type: String,
      default: '',
    },
    balanceAfter: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ walletId: 1, createdAt: -1 });
transactionSchema.index({ referenceType: 1, referenceId: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
