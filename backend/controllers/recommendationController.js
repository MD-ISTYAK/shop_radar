const Shop = require('../models/Shop');
const Order = require('../models/Order');
const Follow = require('../models/Follow');
const { calculateDistance, formatDistance } = require('../utils/geoDistance');

// @desc    Get recommendations (nearby, trending, personalized)
// @route   GET /api/recommendations?lat=&lng=&type=
const getRecommendations = async (req, res, next) => {
  try {
    const { lat, lng, type = 'all' } = req.query;
    const result = {};

    // 1. Nearby shops (sorted by distance)
    if (type === 'all' || type === 'nearby') {
      let nearbyQuery = { status: { $in: ['open', 'busy'] } };
      if (lat && lng) {
        nearbyQuery.location = {
          $near: {
            $geometry: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
            $maxDistance: 5000, // 5km
          },
        };
      }
      const nearby = await Shop.find(nearbyQuery).limit(10);
      result.nearby = nearby.map((shop) => {
        const s = shop.toObject();
        if (lat && lng) {
          const dist = calculateDistance(parseFloat(lat), parseFloat(lng), shop.location.coordinates[1], shop.location.coordinates[0]);
          s.distance = dist;
          s.distanceFormatted = formatDistance(dist);
        }
        return s;
      });
    }

    // 2. Trending shops (most orders in last 7 days)
    if (type === 'all' || type === 'trending') {
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const trendingData = await Order.aggregate([
        { $match: { createdAt: { $gte: sevenDaysAgo } } },
        { $group: { _id: '$shopId', orderCount: { $sum: 1 } } },
        { $sort: { orderCount: -1 } },
        { $limit: 10 },
      ]);

      const trendingShopIds = trendingData.map((t) => t._id);
      const trendingShops = await Shop.find({ _id: { $in: trendingShopIds } });
      result.trending = trendingShops;
    }

    // 3. Personalized (based on user's followed shop categories)
    if (type === 'all' || type === 'personalized') {
      if (req.user) {
        const follows = await Follow.find({ userId: req.user._id });
        const followedShopIds = follows.map((f) => f.shopId);
        const followedShops = await Shop.find({ _id: { $in: followedShopIds } });
        const preferredCategories = [...new Set(followedShops.map((s) => s.category))];

        if (preferredCategories.length > 0) {
          const personalized = await Shop.find({
            category: { $in: preferredCategories },
            _id: { $nin: followedShopIds },
          }).limit(10);
          result.personalized = personalized;
        } else {
          result.personalized = [];
        }
      } else {
        result.personalized = [];
      }
    }

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = { getRecommendations };
