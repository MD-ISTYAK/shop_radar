const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      minlength: 2,
      maxlength: 50,
    },
    // Social: unique username for @mentions
    username: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
      minlength: 3,
      maxlength: 30,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: 6,
      select: false,
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
    },
    role: {
      type: String,
      enum: ['user', 'owner', 'delivery_partner'],
      default: 'user',
    },
    // Social: account type for dual-type UI (user vs shop profile)
    accountType: {
      type: String,
      enum: ['user', 'shop'],
      default: 'user',
    },
    avatar: {
      type: String,
      default: '',
    },
    // Social: dedicated profilePic (falls back to avatar)
    profilePic: {
      type: String,
      default: '',
    },
    // Social: user bio
    bio: {
      type: String,
      default: '',
      maxlength: 150,
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },
    interests: {
      type: [String],
      default: [],
      enum: ['Food', 'Grocery', 'Electronics', 'Clothing', 'Pharmacy', 'Beauty', 'Sports', 'Books', 'Hardware', 'Home', 'Medical', 'Repair'],
    },
    language: {
      type: String,
      default: 'en',
      enum: ['en', 'hi', 'ta', 'te', 'bn', 'mr', 'gu', 'kn', 'ml', 'pa'],
    },
    referralCode: {
      type: String,
      unique: true,
      sparse: true,
    },
    referredBy: {
      type: String,
      default: '',
    },
    deviceTokenFCM: {
      type: String,
      default: '',
    },
    // Social: atomic follow counters (maintained via $inc, never derived)
    followersCount: {
      type: Number,
      default: 0,
    },
    followingCount: {
      type: Number,
      default: 0,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    profileComplete: {
      type: Boolean,
      default: false,
    },
    totalCheckIns: {
      type: Number,
      default: 0,
    },
    totalReviews: {
      type: Number,
      default: 0,
    },
    totalOrders: {
      type: Number,
      default: 0,
    },
    // Reference to shop document if accountType is 'shop'
    shopRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
    },
  },
  { timestamps: true }
);

// Indexes for social features
userSchema.index({ username: 1 }, { unique: true, sparse: true });
userSchema.index({ email: 1 }, { unique: true });

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Remove password from JSON output
userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  return user;
};

module.exports = mongoose.model('User', userSchema);
