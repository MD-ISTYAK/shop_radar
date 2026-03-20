const mongoose = require('mongoose');

const shopSchema = new mongoose.Schema(
  {
    shopName: {
      type: String,
      required: [true, 'Shop name is required'],
      trim: true,
      maxlength: 100,
    },
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      trim: true,
      enum: [
        'Grocery',
        'Electronics',
        'Clothing',
        'Food & Restaurant',
        'Pharmacy',
        'Books & Stationery',
        'Hardware',
        'Beauty & Personal Care',
        'Sports',
        'Home & Furniture',
        'Other',
      ],
    },
    description: {
      type: String,
      default: '',
      maxlength: 500,
    },
    address: {
      type: String,
      required: [true, 'Address is required'],
      trim: true,
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    logo: {
      type: String,
      default: '',
    },
    banner: {
      type: String,
      default: '',
    },
    openingTime: {
      type: String,
      required: [true, 'Opening time is required'],
    },
    closingTime: {
      type: String,
      required: [true, 'Closing time is required'],
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
    },
    status: {
      type: String,
      enum: ['open', 'closed', 'busy', 'temporarily_closed'],
      default: 'open',
    },
    crowdLevel: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'low',
    },
    isEmergency: {
      type: Boolean,
      default: false,
    },
    emergencyType: {
      type: String,
      enum: ['hospital', 'medical_store', 'petrol_pump', 'mechanic', ''],
      default: '',
    },
    rating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },
    totalRatings: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

// Create 2dsphere index for geospatial queries
shopSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Shop', shopSchema);
