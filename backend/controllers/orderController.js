const Order = require('../models/Order');
const Shop = require('../models/Shop');
const User = require('../models/User');

// Get user's orders
exports.getMyOrders = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const { status } = req.query;

    const filter = { userId };
    if (status) filter.status = status;

    const orders = await Order.find(filter)
      .populate('shopId', 'shopName logo address phone')
      .populate('deliveryPartnerId', 'name phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Order.countDocuments(filter);

    res.json({
      success: true,
      data: orders,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// Get single order
exports.getOrderById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const order = await Order.findById(id)
      .populate('shopId', 'shopName logo address phone location')
      .populate('deliveryPartnerId', 'name phone avatar');

    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Get shop's orders (for owner)
exports.getShopOrders = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { status } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const shop = await Shop.findOne({ ownerId: userId });
    if (!shop) return res.status(404).json({ success: false, message: 'No shop found' });

    const filter = { shopId: shop._id };
    if (status) filter.status = status;

    const orders = await Order.find(filter)
      .populate('userId', 'name phone avatar')
      .populate('deliveryPartnerId', 'name phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Order.countDocuments(filter);

    res.json({
      success: true,
      data: orders,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// Update order status (by shop owner)
exports.updateOrderStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const userId = req.user._id;

    const order = await Order.findById(id).populate('shopId');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    if (order.shopId.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    order.status = status;
    if (status === 'delivered') {
      order.actualDeliveryTime = new Date();
      await User.findByIdAndUpdate(order.userId, { $inc: { totalOrders: 1 } });
      await Shop.findByIdAndUpdate(order.shopId._id, { $inc: { totalOrders: 1 } });
    }
    await order.save();

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Cancel order
exports.cancelOrder = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const userId = req.user._id;

    const order = await Order.findById(id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    if (order.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (['delivered', 'cancelled'].includes(order.status)) {
      return res.status(400).json({ success: false, message: 'Cannot cancel this order' });
    }

    order.status = 'cancelled';
    order.cancelReason = reason || '';
    await order.save();

    // TODO: Refund to wallet if pre-paid

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Get order stats for shop owner dashboard
exports.getShopOrderStats = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const shop = await Shop.findOne({ ownerId: userId });
    if (!shop) return res.status(404).json({ success: false, message: 'No shop found' });

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [todayOrders, totalOrders, todayRevenue, pendingOrders] = await Promise.all([
      Order.countDocuments({ shopId: shop._id, createdAt: { $gte: today } }),
      Order.countDocuments({ shopId: shop._id }),
      Order.aggregate([
        { $match: { shopId: shop._id, createdAt: { $gte: today }, status: 'delivered' } },
        { $group: { _id: null, total: { $sum: '$totalAmount' } } },
      ]),
      Order.countDocuments({ shopId: shop._id, status: { $in: ['pending', 'confirmed', 'preparing'] } }),
    ]);

    res.json({
      success: true,
      data: {
        todayOrders,
        totalOrders,
        todayRevenue: todayRevenue.length > 0 ? todayRevenue[0].total : 0,
        pendingOrders,
      },
    });
  } catch (error) {
    next(error);
  }
};
