const mongoose = require('mongoose');

const deliveryPartnerSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    vehicleType: {
      type: String,
      enum: ['bicycle', 'bike', 'scooter', 'car', 'auto'],
      required: [true, 'Vehicle type is required'],
    },
    vehicleNumber: {
      type: String,
      default: '',
      trim: true,
    },
    licenseNumber: {
      type: String,
      default: '',
      trim: true,
    },
    kycStatus: {
      type: String,
      enum: ['pending', 'submitted', 'verified', 'rejected'],
      default: 'pending',
    },
    kycDocuments: {
      aadhaar: { type: String, default: '' },
      pan: { type: String, default: '' },
      license: { type: String, default: '' },
      vehicleRC: { type: String, default: '' },
      selfie: { type: String, default: '' },
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    currentLocation: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number],
        default: [0, 0],
      },
    },
    activeDeliveryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'DeliveryRequest',
      default: null,
    },
    totalDeliveries: {
      type: Number,
      default: 0,
    },
    rating: {
      type: Number,
      default: 5.0,
      min: 0,
      max: 5,
    },
    totalRatings: {
      type: Number,
      default: 0,
    },
    earningsBalance: {
      type: Number,
      default: 0,
    },
    totalEarnings: {
      type: Number,
      default: 0,
    },
    bankDetails: {
      accountNumber: { type: String, default: '' },
      ifsc: { type: String, default: '' },
      upiId: { type: String, default: '' },
    },
    isBlocked: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

deliveryPartnerSchema.index({ currentLocation: '2dsphere' });
deliveryPartnerSchema.index({ isOnline: 1, kycStatus: 1 });
deliveryPartnerSchema.index({ userId: 1 });

module.exports = mongoose.model('DeliveryPartner', deliveryPartnerSchema);
