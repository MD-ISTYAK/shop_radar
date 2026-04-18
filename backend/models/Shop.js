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
        'Salon',
        'Clinic',
        'Repair',
        'Petrol Pump',
        'Mechanic',
        'Doctor',
        'Government Office',
        'Coaching Centre',
        'Bakery',
        'Jewellery',
        'Pet Store',
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
    images: {
      type: [String],
      default: [],
    },
    openingTime: {
      type: String,
      required: [true, 'Opening time is required'],
    },
    closingTime: {
      type: String,
      required: [true, 'Closing time is required'],
    },
    operatingDays: {
      type: [String],
      default: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      enum: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
    },
    whatsappNumber: {
      type: String,
      default: '',
    },
    website: {
      type: String,
      default: '',
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
    is24x7: {
      type: Boolean,
      default: false,
    },
    isEmergency: {
      type: Boolean,
      default: false,
    },
    emergencyType: {
      type: String,
      enum: ['hospital', 'medical_store', 'petrol_pump', 'mechanic', 'ambulance', ''],
      default: '',
    },
    isEmergencyVerified: {
      type: Boolean,
      default: false,
    },
    features: {
      type: [String],
      default: [],
      enum: ['wifi', 'parking', 'ac', 'card_payment', 'upi', 'home_delivery', 'dine_in', 'takeaway', 'wheelchair_access'],
    },
    autoStatusByGPS: {
      type: Boolean,
      default: false,
    },
    queueEnabled: {
      type: Boolean,
      default: false,
    },
    busyThreshold: {
      type: Number,
      default: 10,
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
    followers: {
      type: Number,
      default: 0,
    },
    totalCheckIns: {
      type: Number,
      default: 0,
    },
    trendingScore: {
      type: Number,
      default: 0,
    },
    isTrending: {
      type: Boolean,
      default: false,
    },
    totalOrders: {
      type: Number,
      default: 0,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

// Create 2dsphere index for geospatial queries
shopSchema.index({ location: '2dsphere' });
shopSchema.index({ category: 1, status: 1 });
shopSchema.index({ trendingScore: -1 });
shopSchema.index({ ownerId: 1 });

module.exports = mongoose.model('Shop', shopSchema);
