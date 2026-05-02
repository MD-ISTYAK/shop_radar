const Order = require('../models/Order');
const Shop = require('../models/Shop');
const User = require('../models/User');
const logger = require('../config/logger');

// ── Order Status Transition Machine ──
const ORDER_TRANSITIONS = {
  pending:            ['accepted', 'cancelled'],
  accepted:           ['preparing', 'cancelled'],
  preparing:          ['packed', 'cancelled'],
  packed:             ['ready', 'cancelled'],
  ready:              ['delivery_assigned', 'out_for_delivery', 'delivered'],
  delivery_assigned:  ['picked_up', 'cancelled'],
  picked_up:          ['out_for_delivery'],
  out_for_delivery:   ['delivered'],
  delivered:          [],
  cancelled:          [],
};

const isValidTransition = (from, to) => {
  return ORDER_TRANSITIONS[from]?.includes(to) || false;
};

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
    const { status, search } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const shop = await Shop.findOne({ ownerId: userId });
    if (!shop) return res.status(404).json({ success: false, message: 'No shop found' });

    const filter = { shopId: shop._id };
    if (status) filter.status = status;
    if (search) {
      filter.orderId = { $regex: search, $options: 'i' };
    }

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

// Update order status (with transition validation)
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

    // Validate status transition
    if (!isValidTransition(order.status, status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status transition: ${order.status} → ${status}. Allowed: ${ORDER_TRANSITIONS[order.status]?.join(', ') || 'none'}`,
      });
    }

    order.status = status;
    order.timeline.push({ status, note: `Status updated to ${status}` });
    
    if (status === 'delivered') {
      order.actualDeliveryTime = new Date();
      await User.findByIdAndUpdate(order.userId, { $inc: { totalOrders: 1 } });
      await Shop.findByIdAndUpdate(order.shopId._id, { $inc: { totalOrders: 1 } });
    }
    await order.save();

    logger.info('Order status updated', {
      requestId: req.requestId,
      orderId: order._id.toString(),
      from: order.status,
      to: status,
    });

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Accept order (Shop Owner)
exports.acceptOrder = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const order = await Order.findById(id).populate('shopId');
    if (!order || order.shopId.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized or not found' });
    }

    if (!isValidTransition(order.status, 'accepted')) {
      return res.status(400).json({ success: false, message: `Cannot accept order in status: ${order.status}` });
    }

    order.status = 'accepted';
    order.timeline.push({ status: 'accepted', note: 'Shop accepted the order' });
    await order.save();

    // Trigger delivery partner notification if home delivery
    if (order.deliveryType === 'home_delivery') {
      const DeliveryRequest = require('../models/DeliveryRequest');
      const deliveryRequest = await DeliveryRequest.findOneAndUpdate(
        { orderId: order._id },
        { status: 'accepted' },
        { new: true }
      );
      
      if (deliveryRequest) {
        const { notifyNearbyPartners } = require('./deliveryPartnerController');
        notifyNearbyPartners(deliveryRequest);
      }
    }

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Pack order (Shop Owner) - uploads images
exports.packOrder = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const order = await Order.findById(id).populate('shopId');
    if (!order || order.shopId.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized or not found' });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ success: false, message: 'Minimum 1 image is required to mark as packed' });
    }

    const images = req.files.map((file) => file.path);
    order.packedImages = images;
    order.status = 'packed';
    order.timeline.push({ status: 'packed', note: 'Order packed and ready for handover' });
    await order.save();

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Verify pickup code (Shop Owner verifying Delivery Partner)
exports.verifyPickupCode = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { code } = req.body;
    const userId = req.user._id;

    const order = await Order.findById(id).populate('shopId');
    if (!order || order.shopId.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized or not found' });
    }

    if (order.pickupCode !== code) {
      return res.status(400).json({ success: false, message: 'Invalid verification code' });
    }

    order.status = 'out_for_delivery';
    order.timeline.push({ status: 'out_for_delivery', note: 'Order dispatched with delivery partner' });
    await order.save();

    const request = await require('../models/DeliveryRequest').findOne({ orderId: order._id });
    if(request) {
       request.status = 'picked_up';
       await request.save();
    }

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Complete shop pickup (Shop Owner verifying User OTP for shop pickup)
exports.completeShopPickup = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { otp } = req.body;
    const userId = req.user._id;

    const order = await Order.findById(id).populate('shopId');
    if (!order || order.shopId.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized or order not found' });
    }

    // Allow handover even if originally set to home_delivery (customer might be at the shop)
    if (!['accepted', 'preparing', 'packed', 'ready', 'delivery_assigned'].includes(order.status)) {
      return res.status(400).json({ success: false, message: `Order must be prepared before handover. Current status: ${order.status}` });
    }

    if (order.userOtp !== otp) {
      return res.status(400).json({ success: false, message: 'Invalid verification code' });
    }

    order.status = 'delivered';
    order.actualDeliveryTime = new Date();
    order.timeline.push({ status: 'delivered', note: 'Order picked up by customer' });
    
    await User.findByIdAndUpdate(order.userId, { $inc: { totalOrders: 1 } });
    await Shop.findByIdAndUpdate(order.shopId._id, { $inc: { totalOrders: 1 } });
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
    order.timeline.push({ status: 'cancelled', note: reason || 'Order cancelled by user' });
    await order.save();

    // Cancel associated delivery request
    const DeliveryRequest = require('../models/DeliveryRequest');
    await DeliveryRequest.findOneAndUpdate(
      { orderId: order._id, status: { $nin: ['delivered'] } },
      { status: 'cancelled', cancellationReason: reason || 'Order cancelled' }
    );

    // Notify delivery partner if assigned
    if (order.deliveryPartnerId) {
      const { sendToUser } = require('../config/socketManager');
      sendToUser(order.deliveryPartnerId.toString(), 'order:cancelled', {
        orderId: order._id,
        message: 'Order has been cancelled',
      });
    }

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Create flexible (text-based) order
exports.createFlexibleOrder = async (req, res, next) => {
  try {
    const { shopId, description, deliveryType = 'home_delivery', deliveryAddress, lat, lng } = req.body;
    const userId = req.user._id;

    if (!description || !description.trim()) {
      return res.status(400).json({ success: false, message: 'Order description is required' });
    }

    const shop = await Shop.findById(shopId);
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });

    const orderId = `ORD-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const userOtp = Math.floor(100000 + Math.random() * 900000).toString();
    const pickupCode = Math.floor(100000 + Math.random() * 900000).toString();

    let userLoc = [0, 0];
    if (lat && lng) userLoc = [Number(lng), Number(lat)];

    const order = await Order.create({
      orderId,
      userId,
      shopId,
      orderType: 'flexible',
      flexibleDescription: description.trim(),
      items: [],
      totalAmount: 0, // Will be set when shop confirms price
      deliveryType,
      deliveryAddress: deliveryAddress || '',
      deliveryLocation: { type: 'Point', coordinates: userLoc },
      userOtp,
      pickupCode,
      status: 'pending',
      timeline: [{ status: 'pending', note: 'Flexible order placed — awaiting price confirmation' }],
    });

    // Notify shop owner
    const { sendToUser } = require('../config/socketManager');
    sendToUser(shop.ownerId.toString(), 'notification:new', {
      type: 'order_request',
      title: 'New Text Order!',
      body: `New flexible order: "${description.substring(0, 80)}"`,
      useCustomSound: true,
      data: { orderId: order._id, status: 'pending' },
    });

    res.status(201).json({ success: true, message: 'Flexible order placed', data: order });
  } catch (error) {
    next(error);
  }
};

// Shop confirms price for flexible order
exports.confirmPrice = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { price } = req.body;
    const userId = req.user._id;

    if (!price || price <= 0) {
      return res.status(400).json({ success: false, message: 'Valid price is required' });
    }

    const order = await Order.findById(id).populate('shopId');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (order.shopId.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    if (order.orderType !== 'flexible') {
      return res.status(400).json({ success: false, message: 'Only flexible orders need price confirmation' });
    }

    order.confirmedPrice = price;
    order.priceConfirmedAt = new Date();
    order.timeline.push({ status: 'price_quoted', note: `Shop quoted ₹${price}` });
    await order.save();

    // Notify user
    const { sendToUser } = require('../config/socketManager');
    sendToUser(order.userId.toString(), 'order:priceConfirmed', {
      orderId: order._id,
      price,
      message: `Shop has quoted ₹${price} for your order`,
    });

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// User accepts quoted price
exports.acceptPrice = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const order = await Order.findById(id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (order.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    if (!order.confirmedPrice) {
      return res.status(400).json({ success: false, message: 'No price has been quoted yet' });
    }

    order.totalAmount = order.confirmedPrice;
    order.timeline.push({ status: 'price_accepted', note: `User accepted ₹${order.confirmedPrice}` });
    await order.save();

    res.json({ success: true, message: 'Price accepted', data: order });
  } catch (error) {
    next(error);
  }
};

// Get order stats for shop owner dashboard (using aggregation, not memory load)
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
      Order.countDocuments({ shopId: shop._id, status: { $in: ['pending', 'accepted', 'preparing'] } }),
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
