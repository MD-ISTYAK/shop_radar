const mongoose = require('mongoose');

const paymentLogSchema = new mongoose.Schema(
  {
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    currency: {
      type: String,
      default: 'INR',
    },
    method: {
      type: String,
      enum: ['razorpay', 'upi', 'cod', 'wallet'],
      required: true,
    },
    provider: {
      type: String,
      enum: ['razorpay', 'cashfree', 'internal'],
      default: 'razorpay',
    },
    providerOrderId: {
      type: String, // Razorpay order_id
      default: '',
    },
    providerPaymentId: {
      type: String, // Razorpay payment_id
      default: '',
    },
    providerSignature: {
      type: String,
      default: '',
    },
    status: {
      type: String,
      enum: ['initiated', 'success', 'failed', 'refunded'],
      default: 'initiated',
    },
    webhookPayload: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    retryCount: {
      type: Number,
      default: 0,
    },
    failureReason: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

paymentLogSchema.index({ orderId: 1 });
paymentLogSchema.index({ providerOrderId: 1 });
paymentLogSchema.index({ userId: 1, createdAt: -1 });
paymentLogSchema.index({ status: 1 });

module.exports = mongoose.model('PaymentLog', paymentLogSchema);
