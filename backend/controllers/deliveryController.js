const DeliveryRequest = require('../models/DeliveryRequest');
const Shop = require('../models/Shop');

// @desc    Create delivery request
// @route   POST /api/delivery
const createDeliveryRequest = async (req, res, next) => {
  try {
    const { shopId, items, deliveryAddress, note } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Items are required' });
    }

    const totalAmount = items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);

    const request = await DeliveryRequest.create({
      userId: req.user._id,
      shopId,
      items,
      deliveryAddress,
      note: note || '',
      totalAmount,
    });

    res.status(201).json({ success: true, message: 'Delivery request sent', data: request });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's delivery requests
// @route   GET /api/delivery/my-requests
const getMyDeliveryRequests = async (req, res, next) => {
  try {
    const requests = await DeliveryRequest.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .populate('shopId', 'shopName logo');

    res.status(200).json({ success: true, count: requests.length, data: requests });
  } catch (error) {
    next(error);
  }
};

// @desc    Get delivery requests for owner's shop
// @route   GET /api/delivery/shop-requests
const getShopDeliveryRequests = async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user._id });
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });

    const requests = await DeliveryRequest.find({ shopId: shop._id })
      .sort({ createdAt: -1 })
      .populate('userId', 'name phone');

    res.status(200).json({ success: true, count: requests.length, data: requests });
  } catch (error) {
    next(error);
  }
};

// @desc    Update delivery request status (accept/reject)
// @route   PATCH /api/delivery/:id/status
const updateDeliveryStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const validStatuses = ['accepted', 'rejected', 'delivered'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: `Status must be one of: ${validStatuses.join(', ')}` });
    }

    const request = await DeliveryRequest.findById(req.params.id);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    // Verify ownership
    const shop = await Shop.findById(request.shopId);
    if (!shop || shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    request.status = status;
    await request.save();

    res.status(200).json({ success: true, message: `Request ${status}`, data: request });
  } catch (error) {
    next(error);
  }
};

module.exports = { createDeliveryRequest, getMyDeliveryRequests, getShopDeliveryRequests, updateDeliveryStatus };
