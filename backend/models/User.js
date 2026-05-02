const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    // New Social Media Schema
    profile: {
      name: {
        type: String,
        required: [true, 'Name is required'],
        trim: true,
        minlength: 2,
        maxlength: 50,
      },
      bio: {
        type: String,
        default: '',
        maxlength: 150,
      },
      avatarUrl: {
        type: String,
        default: '',
      },
    },
    stats: {
      followersCount: {
        type: Number,
        default: 0,
      },
      followingCount: {
        type: Number,
        default: 0,
      },
      postsCount: {
        type: Number,
        default: 0,
      },
    },

    // Backward compatibility aliases (Virtuals will be added for easier access)
    // To not break existing code, we keep these flat fields for now and sync them or we just use them directly if the migration is too complex.
    // Wait, since we must use `profile.name`, we should define them directly.
    name: {
      type: String,
      trim: true,
      minlength: 2,
      maxlength: 50,
    },
    bio: {
      type: String,
      default: '',
      maxlength: 150,
    },
    avatar: {
      type: String,
      default: '',
    },
    profilePic: {
      type: String,
      default: '',
    },
    followersCount: {
      type: Number,
      default: 0,
    },
    followingCount: {
      type: Number,
      default: 0,
    },

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
      enum: ['user', 'owner', 'delivery_partner', 'business_owner', 'admin'],
      default: 'user',
    },
    accountType: {
      type: String,
      enum: ['user', 'shop'],
      default: 'user',
    },
    location: {
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
    isOnline: {
      type: Boolean,
      default: false,
    },
    lastSeen: {
      type: Date,
      default: Date.now,
    },
    shopRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
    },
    businesses: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Business',
    }],

    // ── Subscription System ──
    subscription: {
      plan: {
        type: String,
        enum: ['free', 'pro', 'ultra_pro'],
        default: 'free',
      },
      expiresAt: {
        type: Date,
        default: null,
      },
      razorpaySubscriptionId: {
        type: String,
      },
    },

    // ── Moderation & Trust System ──
    trustScore: {
      type: Number,
      default: 50,
      min: 0,
      max: 100,
    },
    strikeCount: {
      type: Number,
      default: 0,
    },
    isBanned: {
      type: Boolean,
      default: false,
    },
    banReason: {
      type: String,
      default: '',
    },
    uploadCooldownUntil: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

// Pre-validate hook to keep backward compatibility fields synced before validation
userSchema.pre('validate', function (next) {
  if (!this.profile) this.profile = {};
  if (!this.stats) this.stats = {};

  if (this.isModified('name') && !this.isModified('profile.name')) {
    this.profile.name = this.name;
  }
  if (this.isModified('profile.name') && !this.isModified('name')) {
    this.name = this.profile.name;
  }
  
  if (this.isModified('bio') && !this.isModified('profile.bio')) {
    this.profile.bio = this.bio;
  }
  if (this.isModified('profile.bio') && !this.isModified('bio')) {
    this.bio = this.profile.bio;
  }
  
  if (this.isModified('avatar') && !this.isModified('profile.avatarUrl')) {
    this.profile.avatarUrl = this.avatar;
  }
  if (this.isModified('profile.avatarUrl') && !this.isModified('avatar')) {
    this.avatar = this.profile.avatarUrl;
    this.profilePic = this.profile.avatarUrl;
  }

  if (this.isModified('followersCount') && !this.isModified('stats.followersCount')) {
    this.stats.followersCount = this.followersCount;
  }
  if (this.isModified('stats.followersCount') && !this.isModified('followersCount')) {
    this.followersCount = this.stats.followersCount;
  }

  if (this.isModified('followingCount') && !this.isModified('stats.followingCount')) {
    this.stats.followingCount = this.followingCount;
  }
  if (this.isModified('stats.followingCount') && !this.isModified('followingCount')) {
    this.followingCount = this.stats.followingCount;
  }

  next();
});

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
