const Shop = require('../models/Shop');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Follow = require('../models/Follow');
const CheckIn = require('../models/CheckIn');
const DeliveryRequest = require('../models/DeliveryRequest');
const Business = require('../models/Business');
const User = require('../models/User');
const { calculateDistance, formatDistance } = require('../utils/geoDistance');
const logger = require('../config/logger');

// @desc    Create a new shop
// @route   POST /api/shops
const createShop = async (req, res, next) => {
  try {
    const {
      shopName,
      category,
      description,
      address,
      longitude,
      latitude,
      openingTime,
      closingTime,
      phone,
      businessType = 'shop',
      isMobile = false,
      serviceType = 'both',
      upiId = '',
      whatsappNumber = '',
      website = '',
      deliveryRadius = 5,
      hasHomeDelivery = true,
      hasSelfPickup = true,
    } = req.body;

    // --- Subscription Limit Check ---
    const user = await User.findById(req.user._id);
    const existingBusinessesCount = await Business.countDocuments({
      userId: req.user._id,
      businessType: { $ne: 'delivery_partner' }, // Delivery Partner doesn't count against limits
    });

    const plan = user.subscription?.plan || 'free';
    
    // Free: max 1
    if (plan === 'free' && existingBusinessesCount >= 1) {
      return res.status(403).json({
        success: false,
        message: 'You have reached the limit for the Free plan. Upgrade to Pro or Ultra Pro to create more.',
        requiresSubscription: true,
      });
    }

    // Pro: max 3
    if (plan === 'pro' && existingBusinessesCount >= 3) {
      return res.status(403).json({
        success: false,
        message: 'You have reached the limit for the Pro plan. Upgrade to Ultra Pro to create unlimited shops/services.',
        requiresSubscription: true,
      });
    }
    // --------------------------------

    const shopData = {
      shopName,
      ownerId: req.user._id,
      category,
      description: description || '',
      address,
      location: {
        type: 'Point',
        coordinates: [parseFloat(longitude || 0), parseFloat(latitude || 0)],
      },
      openingTime,
      closingTime,
      phone,
      businessType,
      isMobile: isMobile === true || isMobile === 'true',
      serviceType,
      upiId,
      whatsappNumber,
      website,
      deliveryRadius: parseFloat(deliveryRadius || 5),
      hasHomeDelivery: hasHomeDelivery === true || hasHomeDelivery === 'true',
      hasSelfPickup: hasSelfPickup === true || hasSelfPickup === 'true',
    };

    // Handle file uploads (Cloudinary gives full URL in path)
    if (req.files) {
      if (req.files.logo) shopData.logo = req.files.logo[0].path;
      if (req.files.banner) shopData.banner = req.files.banner[0].path;
    }

    const shop = await Shop.create(shopData);

    // Auto-create/update a Business record for this shop
    let business = await Business.findOne({
      userId: req.user._id,
      businessType: 'shop',
      shopRef: null, // Find an unlinked shop business
    });

    if (business) {
      // Link existing unlinked business record to this shop
      business.shopRef = shop._id;
      business.businessName = shopName;
      business.category = category;
      await business.save();
    } else {
      // Create new business record
      business = await Business.create({
        userId: req.user._id,
        businessType: 'shop',
        businessName: shopName,
        description: description || '',
        category: category,
        shopRef: shop._id,
        contactPhone: phone,
      });

      await User.findByIdAndUpdate(req.user._id, {
        $addToSet: { businesses: business._id },
      });
    }

    // Update user role if they're still 'user' (backward compat)
    if (req.user.role === 'user') {
      await User.findByIdAndUpdate(req.user._id, { role: 'owner' });
    }

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
          $maxDistance: parseFloat(radius) * 1000,
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
    logger.error('getNearbyShops error', { error: error.message, requestId: req.requestId });
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

    // Handle file uploads (Cloudinary gives full URL in path)
    if (req.files) {
      if (req.files.logo) updates.logo = req.files.logo[0].path;
      if (req.files.banner) updates.banner = req.files.banner[0].path;
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

    // Use aggregation for stats instead of loading all orders into memory
    const [totalProducts, orderStats, totalFollowers, totalCheckIns, deliveryStats] = await Promise.all([
      Product.countDocuments({ shopId: shop._id }),
      Order.aggregate([
        { $match: { shopId: shop._id } },
        {
          $group: {
            _id: null,
            totalOrders: { $sum: 1 },
            totalEarnings: { $sum: '$totalAmount' },
            successfulOrders: {
              $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] },
            },
          },
        },
      ]),
      Follow.countDocuments({ shopId: shop._id }),
      CheckIn.countDocuments({ shopId: shop._id }),
      DeliveryRequest.aggregate([
        { $match: { shopId: shop._id } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            delivered: {
              $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] },
            },
            pending: {
              $sum: {
                $cond: [
                  { $in: ['$status', ['pending', 'accepted', 'partner_assigned', 'picked_up']] },
                  1,
                  0,
                ],
              },
            },
          },
        },
      ]),
    ]);

    const stats = orderStats[0] || { totalOrders: 0, totalEarnings: 0, successfulOrders: 0 };
    const delStats = deliveryStats[0] || { total: 0, delivered: 0, pending: 0 };

    res.status(200).json({
      success: true,
      data: {
        shop,
        analytics: {
          totalProducts,
          totalOrders: stats.totalOrders,
          totalEarnings: stats.totalEarnings,
          successfulOrders: stats.successfulOrders,
          totalFollowers,
          totalCheckIns,
          deliveryStats: {
            pending: delStats.pending,
            delivered: delStats.delivered,
            total: delStats.total,
          },
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get business categories, modes, and filters
// @route   GET /api/shops/filters
const getShopFilters = async (req, res, next) => {
  try {
    const categories = [
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
      'AC & Appliance Repair',
      'Plumbing & Electrician',
      'Street Carts & Tea Stalls',
      'Gyms & Fitness',
      'Salons & Beauty',
      'Clinics & Medical',
      'Automobile & Mechanic',
      'Home Services',
      'Other',
    ];

    const businessModes = [
      { id: 'shops', label: 'Shops & Retail', icon: 'storefront' },
      { id: 'carts', label: 'Street Carts & Stalls', icon: 'emoji_food_beverage' },
      { id: 'services', label: 'Services & Repair', icon: 'home_repair_service' },
      { id: 'gyms', label: 'Gyms & Fitness', icon: 'fitness_center' },
      { id: 'food', label: 'Food & Dining', icon: 'restaurant' },
    ];

    const subCategoriesByBusinessType = {
      'Shops & Retail': [
        'All Shops',
        'Grocery & Kirana',
        'Electronics & Mobile',
        'Clothing & Fashion',
        'Pharmacy & Medical',
        'Hardware & Electrical',
        'Stationery & Books',
      ],
      'Street Carts & Stalls': [
        'All Carts & Stalls',
        'Tea & Coffee Stalls',
        'Fruit & Vegetable Carts',
        'Chaat & Street Food',
        'Juice & Shakes',
        'Flower & Puja Vendors',
      ],
      'Services & Repair': [
        'All Services',
        'AC & Appliance Repair',
        'Plumbing & Electrician',
        'Automobile & Bike Mechanic',
        'Salons & Home Beauty',
        'House Cleaning & Painting',
        'Doctor & Home Clinic Visit',
      ],
      'Gyms & Fitness': [
        'All Gyms',
        'Unisex Fitness Gym',
        'Crossfit & Cardio',
        'Yoga & Meditation Studio',
        'Zumba & Dance Club',
        'Personal Trainer & Rehab',
      ],
      'Food & Dining': [
        'All Food',
        'Restaurants & Dhabas',
        'Fast Food & Pizza',
        'Sweets & Bakery',
        'Cafes & Juice Bar',
      ],
    };

    res.status(200).json({
      success: true,
      categories,
      businessModes,
      subCategoriesByBusinessType,
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
  getShopFilters,
};
