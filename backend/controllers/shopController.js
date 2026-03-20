const Shop = require('../models/Shop');
const Product = require('../models/Product');
const Order = require('../models/Order');
const { calculateDistance, formatDistance } = require('../utils/geoDistance');

// @desc    Create a new shop
// @route   POST /api/shops
const createShop = async (req, res, next) => {
  try {
    const { shopName, category, description, address, longitude, latitude, openingTime, closingTime, phone } = req.body;

    // Check if owner already has a shop
    const existingShop = await Shop.findOne({ ownerId: req.user._id });
    if (existingShop) {
      return res.status(400).json({
        success: false,
        message: 'You already have a registered shop',
      });
    }

    const shopData = {
      shopName,
      ownerId: req.user._id,
      category,
      description: description || '',
      address,
      location: {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      },
      openingTime,
      closingTime,
      phone,
    };

    // Handle file uploads
    if (req.files) {
      if (req.files.logo) shopData.logo = `/uploads/${req.files.logo[0].filename}`;
      if (req.files.banner) shopData.banner = `/uploads/${req.files.banner[0].filename}`;
    }

    const shop = await Shop.create(shopData);

    res.status(201).json({
      success: true,
      message: 'Shop created successfully',
      data: shop,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get nearby shops
// @route   GET /api/shops/nearby?lat=&lng=&radius=&category=&search=
const getNearbyShops = async (req, res, next) => {
  try {
    const { lat, lng, radius = 10, category, search } = req.query;

    let query = {};

    // Geospatial query if coordinates provided
    if (lat && lng && lat !== 'null' && lng !== 'null') {
      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)],
          },
          $maxDistance: parseFloat(radius) * 1000, // Convert km to meters
        },
      };
    }

    // Category filter
    if (category && category !== 'All') {
      query.category = category;
    }

    // Search filter
    if (search) {
      query.shopName = { $regex: search, $options: 'i' };
    }

    const shops = await Shop.find(query).populate('ownerId', 'name email');

    // Calculate distance for each shop
    const shopsWithDistance = shops.map((shop) => {
      const shopObj = shop.toObject();
      if (lat && lng && lat !== 'null' && lng !== 'null') {
        const distance = calculateDistance(
          parseFloat(lat),
          parseFloat(lng),
          shop.location.coordinates[1],
          shop.location.coordinates[0]
        );
        shopObj.distance = distance;
        shopObj.distanceFormatted = formatDistance(distance);
      }
      return shopObj;
    });

    res.status(200).json({
      success: true,
      count: shopsWithDistance.length,
      data: shopsWithDistance,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get shop by ID
// @route   GET /api/shops/:id
const getShopById = async (req, res, next) => {
  try {
    const shop = await Shop.findById(req.params.id).populate('ownerId', 'name email phone');

    if (!shop) {
      return res.status(404).json({
        success: false,
        message: 'Shop not found',
      });
    }

    res.status(200).json({
      success: true,
      data: shop,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update shop
// @route   PUT /api/shops/:id
const updateShop = async (req, res, next) => {
  try {
    let shop = await Shop.findById(req.params.id);

    if (!shop) {
      return res.status(404).json({ success: false, message: 'Shop not found' });
    }

    if (shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized to update this shop' });
    }

    const updates = { ...req.body };

    // Handle location update
    if (updates.longitude && updates.latitude) {
      updates.location = {
        type: 'Point',
        coordinates: [parseFloat(updates.longitude), parseFloat(updates.latitude)],
      };
      delete updates.longitude;
      delete updates.latitude;
    }

    // Handle file uploads
    if (req.files) {
      if (req.files.logo) updates.logo = `/uploads/${req.files.logo[0].filename}`;
      if (req.files.banner) updates.banner = `/uploads/${req.files.banner[0].filename}`;
    }

    shop = await Shop.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true });

    res.status(200).json({
      success: true,
      message: 'Shop updated successfully',
      data: shop,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle shop status
// @route   PATCH /api/shops/:id/toggle-status
const toggleStatus = async (req, res, next) => {
  try {
    const shop = await Shop.findById(req.params.id);

    if (!shop) {
      return res.status(404).json({ success: false, message: 'Shop not found' });
    }

    if (shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    shop.status = shop.status === 'open' ? 'closed' : 'open';
    await shop.save();

    res.status(200).json({
      success: true,
      message: `Shop is now ${shop.status}`,
      data: shop,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update shop status
// @route   PATCH /api/shops/:id/status
const updateShopStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const validStatuses = ['open', 'closed', 'busy', 'temporarily_closed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: `Status must be one of: ${validStatuses.join(', ')}` });
    }

    const shop = await Shop.findById(req.params.id);
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });
    if (shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    shop.status = status;
    await shop.save();

    res.status(200).json({ success: true, message: `Shop status updated to ${status}`, data: shop });
  } catch (error) {
    next(error);
  }
};

// @desc    Update crowd level
// @route   PATCH /api/shops/:id/crowd
const updateCrowdLevel = async (req, res, next) => {
  try {
    const { crowdLevel } = req.body;
    const validLevels = ['low', 'medium', 'high'];
    if (!validLevels.includes(crowdLevel)) {
      return res.status(400).json({ success: false, message: `Crowd level must be one of: ${validLevels.join(', ')}` });
    }

    const shop = await Shop.findById(req.params.id);
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });
    if (shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    shop.crowdLevel = crowdLevel;
    await shop.save();

    res.status(200).json({ success: true, message: `Crowd level updated to ${crowdLevel}`, data: shop });
  } catch (error) {
    next(error);
  }
};

// @desc    Get owner's own shop
// @route   GET /api/shops/my-shop
const getOwnerShop = async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user._id });

    if (!shop) {
      return res.status(404).json({
        success: false,
        message: 'You have not registered a shop yet',
      });
    }

    // Get analytics
    const totalProducts = await Product.countDocuments({ shopId: shop._id });
    const orders = await Order.find({ shopId: shop._id });
    const totalOrders = orders.length;
    const totalEarnings = orders.reduce((sum, order) => sum + order.totalAmount, 0);

    res.status(200).json({
      success: true,
      data: {
        shop,
        analytics: {
          totalProducts,
          totalOrders,
          totalEarnings,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createShop,
  getNearbyShops,
  getShopById,
  updateShop,
  toggleStatus,
  updateShopStatus,
  updateCrowdLevel,
  getOwnerShop,
};
