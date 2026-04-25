const User = require('../models/User');
const Business = require('../models/Business');
const { generateToken } = require('../config/jwt');

// @desc    Register a new user
// @route   POST /api/auth/register
const register = async (req, res, next) => {
  try {
    const { name, email, password, phone } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists',
      });
    }

    // Create user object — always register as 'user'
    const userData = { name, email, password, phone, role: 'user' };
    
    // Add location if provided
    if (req.body.lat && req.body.lng) {
      userData.location = {
        type: 'Point',
        coordinates: [parseFloat(req.body.lng), parseFloat(req.body.lat)],
      };
    }

    // Auto-generate username from name if not provided
    if (!userData.username) {
      userData.username = name.toLowerCase().replace(/\s+/g, '_') + '_' + Date.now().toString(36).slice(-4);
    }

    const user = await User.create(userData);

    // Generate token
    const token = generateToken({ id: user._id, role: user.role });

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        user: {
          id: user._id,
          name: user.name,
          username: user.username,
          email: user.email,
          phone: user.phone,
          role: user.role,
          accountType: user.accountType || 'user',
          profilePic: user.profilePic || user.avatar || '',
          avatar: user.avatar || '',
          bio: user.bio || '',
          followersCount: user.followersCount || 0,
          followingCount: user.followingCount || 0,
          businessCount: 0,
        },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Login user
// @route   POST /api/auth/login
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Find user and include password
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Compare passwords
    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Generate token
    const token = generateToken({ id: user._id, role: user.role });

    // Count user's businesses
    const businessCount = await Business.countDocuments({ userId: user._id, isActive: true });

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user._id,
          name: user.name,
          username: user.username,
          email: user.email,
          phone: user.phone,
          role: user.role,
          accountType: user.accountType || 'user',
          profilePic: user.profilePic || user.avatar || '',
          avatar: user.avatar || '',
          bio: user.bio || '',
          followersCount: user.followersCount || 0,
          followingCount: user.followingCount || 0,
          businessCount: businessCount,
        },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current user profile
// @route   GET /api/auth/profile
const getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update user profile
// @route   PUT /api/auth/profile
const updateProfile = async (req, res, next) => {
  try {
    const { name, username, bio } = req.body;
    const userId = req.user._id;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (name) user.name = name;
    if (bio !== undefined) user.bio = bio;
    
    // Check username uniqueness if changing
    if (username && username !== user.username) {
      const existing = await User.findOne({ username: username.toLowerCase() });
      if (existing) {
        return res.status(400).json({ success: false, message: 'Username is already taken' });
      }
      user.username = username.toLowerCase();
    }

    if (req.file) {
      user.profilePic = req.file.path;
      user.avatar = req.file.path; // Keep both in sync for now
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, login, getProfile, updateProfile };
