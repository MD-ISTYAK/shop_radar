const CheckIn = require('../models/CheckIn');
const Shop = require('../models/Shop');
const User = require('../models/User');

// Check in at a shop
exports.checkIn = async (req, res, next) => {
  try {
    const { shopId, microRating } = req.body;
    const userId = req.user._id;
    const { lat, lng } = req.body;

    // Prevent duplicate check-ins within 30 minutes
    const recentCheckIn = await CheckIn.findOne({
      userId,
      shopId,
      createdAt: { $gte: new Date(Date.now() - 30 * 60 * 1000) },
    });

    if (recentCheckIn) {
      return res.status(400).json({ success: false, message: 'You checked in here recently. Try again in 30 minutes.' });
    }

    const checkIn = await CheckIn.create({
      userId,
      shopId,
      location: {
        type: 'Point',
        coordinates: [lng || 0, lat || 0],
      },
      microRating: microRating || null,
    });

    // Update shop check-in count
    await Shop.findByIdAndUpdate(shopId, { $inc: { totalCheckIns: 1 } });
    await User.findByIdAndUpdate(userId, { $inc: { totalCheckIns: 1 } });

    const populated = await CheckIn.findById(checkIn._id)
      .populate('userId', 'name avatar')
      .populate('shopId', 'shopName logo');

    res.status(201).json({ success: true, data: populated, pointsEarned: 5 });
  } catch (error) {
    next(error);
  }
};

// Get check-ins for a shop
exports.getShopCheckIns = async (req, res, next) => {
  try {
    const { shopId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const checkIns = await CheckIn.find({ shopId })
      .populate('userId', 'name avatar')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await CheckIn.countDocuments({ shopId });
    const recentCount = await CheckIn.countDocuments({
      shopId,
      createdAt: { $gte: new Date(Date.now() - 30 * 60 * 1000) },
    });

    res.json({
      success: true,
      data: checkIns,
      recentCheckIns: recentCount,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// Get my check-ins
exports.getMyCheckIns = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const checkIns = await CheckIn.find({ userId })
      .populate('shopId', 'shopName logo category address')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await CheckIn.countDocuments({ userId });

    res.json({
      success: true,
      data: checkIns,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};
