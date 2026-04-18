const Deal = require('../models/Deal');
const Shop = require('../models/Shop');

// Create a deal
exports.createDeal = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { shopId, title, description, originalPrice, dealPrice, expiresAt, category } = req.body;

    const shop = await Shop.findById(shopId);
    if (!shop || shop.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const discountPercent = originalPrice > 0
      ? Math.round(((originalPrice - dealPrice) / originalPrice) * 100)
      : 0;

    const deal = await Deal.create({
      shopId,
      ownerId: userId,
      title,
      description,
      image: req.body.image || '',
      originalPrice,
      dealPrice,
      discountPercent,
      expiresAt: new Date(expiresAt),
      category: category || 'general',
    });

    const populated = await Deal.findById(deal._id)
      .populate('shopId', 'shopName logo address');

    res.status(201).json({ success: true, data: populated });
  } catch (error) {
    next(error);
  }
};

// Get nearby deals
exports.getNearbyDeals = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const deals = await Deal.find({
      isActive: true,
      expiresAt: { $gt: new Date() },
    })
      .populate('shopId', 'shopName logo address location category')
      .sort({ engagementCount: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Deal.countDocuments({
      isActive: true,
      expiresAt: { $gt: new Date() },
    });

    res.json({
      success: true,
      data: deals,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// Get trending deals
exports.getTrendingDeals = async (req, res, next) => {
  try {
    const deals = await Deal.find({
      isActive: true,
      expiresAt: { $gt: new Date() },
    })
      .populate('shopId', 'shopName logo address location')
      .sort({ engagementCount: -1 })
      .limit(10);

    res.json({ success: true, data: deals });
  } catch (error) {
    next(error);
  }
};

// Save / unsave a deal
exports.toggleSaveDeal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const deal = await Deal.findById(id);
    if (!deal) return res.status(404).json({ success: false, message: 'Deal not found' });

    const index = deal.savedBy.indexOf(userId);
    if (index > -1) {
      deal.savedBy.splice(index, 1);
    } else {
      deal.savedBy.push(userId);
      deal.engagementCount += 1;
    }
    await deal.save();

    res.json({ success: true, data: deal, saved: index === -1 });
  } catch (error) {
    next(error);
  }
};

// Get my saved deals
exports.getMySavedDeals = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const deals = await Deal.find({
      savedBy: userId,
      isActive: true,
      expiresAt: { $gt: new Date() },
    })
      .populate('shopId', 'shopName logo address')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: deals });
  } catch (error) {
    next(error);
  }
};

// Get deals by shop
exports.getShopDeals = async (req, res, next) => {
  try {
    const { shopId } = req.params;
    const deals = await Deal.find({
      shopId,
      isActive: true,
      expiresAt: { $gt: new Date() },
    })
      .sort({ createdAt: -1 });

    res.json({ success: true, data: deals });
  } catch (error) {
    next(error);
  }
};

// Delete a deal
exports.deleteDeal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const deal = await Deal.findById(id);
    if (!deal) return res.status(404).json({ success: false, message: 'Deal not found' });
    if (deal.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await Deal.findByIdAndDelete(id);
    res.json({ success: true, message: 'Deal deleted' });
  } catch (error) {
    next(error);
  }
};
