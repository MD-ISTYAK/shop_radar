const mongoose = require('mongoose');

const deliveryItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
  },
  name: String,
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  price: Number,
});

const deliveryRequestSchema = new mongoose.Schema(
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
    items: [deliveryItemSchema],
    deliveryAddress: {
      type: String,
      required: true,
    },
    note: {
      type: String,
      default: '',
      maxlength: 500,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'delivered'],
      default: 'pending',
    },
    totalAmount: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

deliveryRequestSchema.index({ userId: 1, createdAt: -1 });
deliveryRequestSchema.index({ shopId: 1, status: 1 });

module.exports = mongoose.model('DeliveryRequest', deliveryRequestSchema);
