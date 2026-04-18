const Product = require('../models/Product');
const PriceHistory = require('../models/PriceHistory');

// Compare prices for a product across nearby shops
exports.compareProductPrice = async (req, res, next) => {
  try {
    const { productName, lat, lng, radius } = req.query;
    const maxDistance = (parseFloat(radius) || 5) * 1000;

    const matchCondition = {
      name: { $regex: productName, $options: 'i' },
      isActive: true,
    };

    let products = await Product.find(matchCondition)
      .populate({
        path: 'shopId',
        match: {
          status: { $in: ['open', 'busy', 'closed'] },
          ...(lat && lng ? {
            location: {
              $near: {
                $geometry: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
                $maxDistance: maxDistance,
              },
            },
          } : {}),
        },
        select: 'shopName address location status phone rating',
      })
      .sort({ price: 1 });

    products = products.filter(p => p.shopId !== null);

    const comparison = products.map(p => ({
      productId: p._id,
      name: p.name,
      price: p.price,
      discount: p.discount,
      finalPrice: p.discountedPrice || p.price,
      stock: p.stock,
      inStock: p.stock > 0,
      shop: {
        id: p.shopId._id,
        name: p.shopId.shopName,
        address: p.shopId.address,
        status: p.shopId.status,
        rating: p.shopId.rating,
        phone: p.shopId.phone,
      },
    }));

    const bestDeal = comparison.length > 0 ? comparison[0] : null;

    res.json({
      success: true,
      data: {
        query: productName,
        totalResults: comparison.length,
        comparison,
        bestDeal,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get price history for a product
exports.getPriceHistory = async (req, res, next) => {
  try {
    const { productId } = req.params;
    const days = parseInt(req.query.days) || 30;

    const sinceDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const history = await PriceHistory.find({
      productId,
      recordedAt: { $gte: sinceDate },
    })
      .sort({ recordedAt: 1 })
      .select('price recordedAt');

    res.json({ success: true, data: history });
  } catch (error) {
    next(error);
  }
};

// Record price snapshot (called when product price is updated)
exports.recordPriceSnapshot = async (productId, shopId, productName, price) => {
  try {
    await PriceHistory.create({ productId, shopId, productName, price });
  } catch (error) {
    console.error('Price history record error:', error);
  }
};
