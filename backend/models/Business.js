const mongoose = require('mongoose');

const businessSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    businessType: {
      type: String,
      enum: ['shop', 'cart_service', 'delivery_partner', 'freelancer', 'other'],
      required: [true, 'Business type is required'],
    },
    businessName: {
      type: String,
      required: [true, 'Business name is required'],
      trim: true,
      maxlength: 100,
    },
    description: {
      type: String,
      default: '',
      maxlength: 500,
    },
    category: {
      type: String,
      default: '',
      trim: true,
    },
    status: {
      type: String,
      enum: ['pending', 'active', 'suspended'],
      default: 'active',
    },
    // Reference to Shop document (if businessType === 'shop')
    shopRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      default: null,
    },
    // Reference to DeliveryPartner document (if businessType === 'delivery_partner')
    deliveryPartnerRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'DeliveryPartner',
      default: null,
    },
    // For non-shop business types
    serviceArea: {
      type: String,
      default: '',
    },
    contactPhone: {
      type: String,
      default: '',
    },
    logo: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

// Indexes
businessSchema.index({ userId: 1 });
businessSchema.index({ businessType: 1 });
businessSchema.index({ userId: 1, businessType: 1 });

module.exports = mongoose.model('Business', businessSchema);
