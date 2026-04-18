const Shop = require('../models/Shop');
const Product = require('../models/Product');
const CheckIn = require('../models/CheckIn');
const Review = require('../models/Review');

// AI Shopping Assistant — cheapest plan + route
exports.getShoppingAssistant = async (req, res, next) => {
  try {
    const { items, lat, lng, radius } = req.body;
    // items = [{ name: "milk 1L" }, { name: "bread" }]

    if (!items || !items.length) {
      return res.status(400).json({ success: false, message: 'Provide a shopping list' });
    }

    const maxDistance = (radius || 3) * 1000;
    const results = [];

    for (const item of items) {
      const products = await Product.find({
        name: { $regex: item.name, $options: 'i' },
        isActive: true,
        stock: { $gt: 0 },
      })
        .populate({
          path: 'shopId',
          match: {
            status: { $in: ['open', 'busy'] },
            ...(lat && lng ? {
              location: {
                $near: {
                  $geometry: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
                  $maxDistance: maxDistance,
                },
              },
            } : {}),
          },
          select: 'shopName address location status phone',
        })
        .sort({ price: 1 })
        .limit(5);

      const validProducts = products.filter(p => p.shopId !== null);
      results.push({
        item: item.name,
        options: validProducts.map(p => ({
          productId: p._id,
          name: p.name,
          price: p.price,
          discount: p.discount,
          finalPrice: p.discountedPrice,
          shop: p.shopId,
          stock: p.stock,
        })),
        cheapest: validProducts.length > 0 ? {
          price: validProducts[0].discountedPrice,
          shop: validProducts[0].shopId?.shopName,
        } : null,
      });
    }

    const totalCheapest = results.reduce((sum, r) => sum + (r.cheapest?.price || 0), 0);

    res.json({
      success: true,
      data: {
        plan: results,
        totalEstimate: totalCheapest,
        message: `Best estimate: ₹${totalCheapest} across nearby shops`,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Crowd Prediction
exports.getCrowdPrediction = async (req, res, next) => {
  try {
    const { shopId } = req.params;

    const now = new Date();
    const hourOfDay = now.getHours();
    const dayOfWeek = now.getDay();

    // Heuristic: count check-ins in similar time slots from past 7 days
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const recentCheckIns = await CheckIn.countDocuments({
      shopId,
      createdAt: { $gte: oneWeekAgo },
    });

    const last30Min = await CheckIn.countDocuments({
      shopId,
      createdAt: { $gte: new Date(now.getTime() - 30 * 60 * 1000) },
    });

    let prediction = 'low';
    let message = 'Expected to be quiet';

    if (last30Min > 10 || recentCheckIns > 50) {
      prediction = 'high';
      message = 'Expected to be busy. Consider visiting later.';
    } else if (last30Min > 5 || recentCheckIns > 25) {
      prediction = 'medium';
      message = 'Moderate crowd expected.';
    }

    // Peak hours heuristic
    const isPeakHour = (hourOfDay >= 10 && hourOfDay <= 13) || (hourOfDay >= 17 && hourOfDay <= 20);
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;

    if (isPeakHour && prediction === 'low') {
      prediction = 'medium';
      message = 'Peak hours - may be busier than usual.';
    }
    if (isWeekend && prediction !== 'high') {
      prediction = prediction === 'low' ? 'medium' : 'high';
      message += ' Weekend traffic expected.';
    }

    res.json({
      success: true,
      data: {
        currentCrowd: prediction,
        message,
        recentCheckIns: last30Min,
        bestTimeToVisit: isPeakHour ? 'Try visiting between 2-5 PM' : 'Good time to visit now!',
      },
    });
  } catch (error) {
    next(error);
  }
};

// Best Time to Visit
exports.getBestTimeToVisit = async (req, res, next) => {
  try {
    const { shopId } = req.params;

    // Analyze check-in patterns
    const checkIns = await CheckIn.aggregate([
      { $match: { shopId: require('mongoose').Types.ObjectId.createFromHexString(shopId) } },
      {
        $group: {
          _id: { $hour: '$createdAt' },
          count: { $sum: 1 },
        },
      },
      { $sort: { count: 1 } },
    ]);

    const bestHours = checkIns.slice(0, 3).map(c => ({
      hour: c._id,
      timeSlot: `${c._id}:00 - ${c._id + 1}:00`,
      expectedCrowd: 'low',
    }));

    res.json({
      success: true,
      data: {
        bestTimes: bestHours.length > 0 ? bestHours : [
          { hour: 14, timeSlot: '2:00 PM - 3:00 PM', expectedCrowd: 'low' },
          { hour: 15, timeSlot: '3:00 PM - 4:00 PM', expectedCrowd: 'low' },
        ],
        message: 'Based on recent visitor patterns',
      },
    });
  } catch (error) {
    next(error);
  }
};

// Alternative Shop Suggestion
exports.getAlternativeShop = async (req, res, next) => {
  try {
    const { shopId } = req.params;
    const shop = await Shop.findById(shopId);
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });

    const alternatives = await Shop.find({
      _id: { $ne: shopId },
      category: shop.category,
      status: { $in: ['open', 'busy'] },
      location: {
        $near: {
          $geometry: shop.location,
          $maxDistance: 5000,
        },
      },
    })
      .sort({ rating: -1 })
      .limit(5);

    res.json({ success: true, data: alternatives });
  } catch (error) {
    next(error);
  }
};

// Bargain Assistant
exports.getBargainRange = async (req, res, next) => {
  try {
    const { productName, lat, lng } = req.query;

    const products = await Product.find({
      name: { $regex: productName, $options: 'i' },
      isActive: true,
    }).populate('shopId', 'shopName address');

    if (products.length === 0) {
      return res.json({
        success: true,
        data: { message: 'No price data found for this product' },
      });
    }

    const prices = products.map(p => p.discountedPrice || p.price);
    const minPrice = Math.min(...prices);
    const maxPrice = Math.max(...prices);
    const avgPrice = Math.round(prices.reduce((s, p) => s + p, 0) / prices.length);

    res.json({
      success: true,
      data: {
        productName,
        priceRange: { min: minPrice, max: maxPrice, average: avgPrice },
        fairPrice: avgPrice,
        bargainTip: minPrice < avgPrice
          ? `Try bargaining to ₹${minPrice} - ₹${Math.round(avgPrice * 0.9)}. Best price found at ${products.find(p => (p.discountedPrice || p.price) === minPrice)?.shopId?.shopName || 'nearby shop'}.`
          : 'Prices are consistent across shops. Not much room for bargaining.',
        shops: products.slice(0, 5).map(p => ({
          shop: p.shopId?.shopName,
          price: p.price,
          finalPrice: p.discountedPrice || p.price,
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};
