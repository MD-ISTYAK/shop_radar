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
    userLocation: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true },
    },
    shopLocation: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true },
    },
    pickupCode: {
      type: String,
      default: '',
    },
    deliveryPartnerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    note: {
      type: String,
      default: '',
      maxlength: 500,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'partner_assigned', 'picked_up', 'in_transit', 'delivered', 'rejected', 'cancelled'],
      default: 'pending',
    },
    deliveryFee: {
      type: Number,
      default: 0,
    },
    totalAmount: {
      type: Number,
      default: 0,
    },
    // Assignment tracking
    assignedAt: {
      type: Date,
      default: null,
    },
    pickedUpAt: {
      type: Date,
      default: null,
    },
    deliveredAt: {
      type: Date,
      default: null,
    },
    reassignmentCount: {
      type: Number,
      default: 0,
      max: 3,
    },
    previousPartners: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    }],
    cancellationReason: {
      type: String,
      default: '',
    },
    noPartnerAvailable: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

deliveryRequestSchema.index({ userId: 1, createdAt: -1 });
deliveryRequestSchema.index({ shopId: 1, status: 1 });
deliveryRequestSchema.index({ deliveryPartnerId: 1, status: 1 });
deliveryRequestSchema.index({ status: 1, deliveryPartnerId: 1 }); // For finding unassigned deliveries

module.exports = mongoose.model('DeliveryRequest', deliveryRequestSchema);
