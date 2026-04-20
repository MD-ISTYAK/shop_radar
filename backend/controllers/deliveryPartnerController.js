const DeliveryPartner = require('../models/DeliveryPartner');
const DeliveryRequest = require('../models/DeliveryRequest');
const Order = require('../models/Order');
const User = require('../models/User');
const { calculateDistance } = require('../utils/geoDistance');

// Register as delivery partner
exports.registerAsPartner = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { vehicleType, vehicleNumber, licenseNumber } = req.body;

    const existing = await DeliveryPartner.findOne({ userId });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Already registered as delivery partner' });
    }

    const partner = await DeliveryPartner.create({
      userId,
      vehicleType,
      vehicleNumber: vehicleNumber || '',
      licenseNumber: licenseNumber || '',
    });

    // Update user role
    await User.findByIdAndUpdate(userId, { role: 'delivery_partner' });

    res.status(201).json({ success: true, data: partner });
  } catch (error) {
    next(error);
  }
};

// Update KYC documents
exports.updateKYC = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { aadhaar, pan, license, vehicleRC, selfie } = req.body;

    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner) return res.status(404).json({ success: false, message: 'Not registered as partner' });

    partner.kycDocuments = {
      aadhaar: aadhaar || partner.kycDocuments.aadhaar,
      pan: pan || partner.kycDocuments.pan,
      license: license || partner.kycDocuments.license,
      vehicleRC: vehicleRC || partner.kycDocuments.vehicleRC,
      selfie: selfie || partner.kycDocuments.selfie,
    };
    partner.kycStatus = 'submitted';
    await partner.save();

    res.json({ success: true, data: partner });
  } catch (error) {
    next(error);
  }
};

// Toggle online/offline
exports.toggleOnline = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { lat, lng } = req.body;

    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner) return res.status(404).json({ success: false, message: 'Not registered as partner' });

    if (partner.kycStatus !== 'verified') {
      return res.status(403).json({ success: false, message: 'KYC not verified yet' });
    }

    partner.isOnline = !partner.isOnline;
    if (lat && lng) {
      partner.currentLocation = { type: 'Point', coordinates: [lng, lat] };
    }
    await partner.save();

    res.json({ success: true, data: partner, isOnline: partner.isOnline });
  } catch (error) {
    next(error);
  }
};

// Update live location
exports.updateLocation = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { lat, lng } = req.body;

    await DeliveryPartner.findOneAndUpdate(
      { userId },
      { currentLocation: { type: 'Point', coordinates: [lng, lat] } }
    );

    res.json({ success: true, message: 'Location updated' });
  } catch (error) {
    next(error);
  }
};

// Get available deliveries nearby
exports.getAvailableDeliveries = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner || !partner.isOnline) {
      return res.status(400).json({ success: false, message: 'Go online to see deliveries' });
    }

    const deliveries = await DeliveryRequest.find({
      status: 'accepted', // Shop accepted, waiting for partner
      deliveryPartnerId: null,
    })
      .populate('shopId', 'shopName address location phone')
      .populate('userId', 'name phone')
      .sort({ createdAt: -1 })
      .limit(20);

    res.json({ success: true, data: deliveries });
  } catch (error) {
    next(error);
  }
};

// Accept a delivery
exports.acceptDelivery = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { deliveryId } = req.params;

    // 1. Atomically assign partner if it is still null
    // We only allow accepting if status is 'accepted' (meaning shop accepted it)
    const delivery = await DeliveryRequest.findOneAndUpdate(
      { _id: deliveryId, deliveryPartnerId: null, status: 'accepted' },
      { deliveryPartnerId: userId, status: 'partner_assigned' },
      { new: true }
    ).populate('shopId', 'shopName address location phone').populate('userId', 'name phone address');

    if (!delivery) {
      // Logic for "Missed Request" tracking
      await DeliveryPartner.findOneAndUpdate({ userId }, { $inc: { missedRequests: 1 } });
      return res.status(400).json({ 
        success: false, 
        message: 'Too late! This request was already accepted by another partner.' 
      });
    }

    // 2. Update Partner stats and active deliveries
    const partner = await DeliveryPartner.findOneAndUpdate(
      { userId },
      { 
        $addToSet: { activeDeliveries: deliveryId },
        $inc: { totalAcceptedRequests: 1 }
      },
      { new: true }
    );

    // 3. Update Order
    const order = await Order.findById(delivery.orderId);
    if(order) {
      order.deliveryPartnerId = userId;
      order.status = 'delivery_assigned';
      order.timeline.push({ status: 'delivery_assigned', note: 'Delivery partner assigned' });
      await order.save();
    }

    // 4. Notify all online partners that it's claimed
    const { getIO } = require('../config/socketManager');
    try {
      const io = getIO();
      io.emit('delivery:claimed', { deliveryId, claimerId: userId });
    } catch (e) {}

    res.json({ success: true, data: delivery });
  } catch (error) {
    next(error);
  }
};

// Notify nearby delivery partners helper
exports.notifyNearbyPartners = async (deliveryRequest) => {
  try {
    const { getIO } = require('../config/socketManager');
    const io = getIO();
    const shopLoc = deliveryRequest.shopLocation.coordinates; // [lng, lat]

    // Find verified online partners within 500m
    const partners = await DeliveryPartner.find({
      isOnline: true,
      kycStatus: 'verified',
      currentLocation: {
        $near: {
          $geometry: { type: 'Point', coordinates: shopLoc },
          $maxDistance: 500
        }
      }
    });

    partners.forEach(partner => {
      io.to(`user:${partner.userId}`).emit('delivery:newRequest', deliveryRequest);
    });
  } catch (error) {
    console.error('Notification Error:', error);
  }
};

// Complete a delivery (with OTP and Images)
exports.completeDelivery = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { deliveryId } = req.params;
    const { otp } = req.body;

    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner) return res.status(404).json({ success: false, message: 'Not a partner' });

    const delivery = await DeliveryRequest.findById(deliveryId);
    if (!delivery || delivery.deliveryPartnerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not your delivery' });
    }

    const order = await Order.findById(delivery.orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    if (order.userOtp !== otp) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ success: false, message: 'Minimum 1 image required to mark as delivered' });
    }

    const images = req.files.map((file) => file.path);
    order.deliveredImages = images;
    order.status = 'delivered';
    order.actualDeliveryTime = new Date();
    order.timeline.push({ status: 'delivered', note: 'Order delivered to customer' });
    
    await User.findByIdAndUpdate(order.userId, { $inc: { totalOrders: 1 } });
    await require('../models/Shop').findByIdAndUpdate(order.shopId, { $inc: { totalOrders: 1 } });
    await order.save();

    delivery.status = 'delivered';
    await delivery.save();

    // Calculate delivery time
    const assignedEvent = order.timeline.find(t => t.status === 'delivery_assigned');
    const deliveryTimeMins = assignedEvent ? (order.actualDeliveryTime - assignedEvent.timestamp) / 60000 : 0;

    // Calculate and credit earnings
    const earnings = delivery.deliveryFee * 0.85; // 85% to partner, 15% platform
    partner.activeDeliveries = partner.activeDeliveries.filter(id => id.toString() !== delivery._id.toString());
    
    partner.completedDeliveries += 1;
    partner.totalDeliveries += 1;
    partner.earningsBalance += earnings;
    partner.totalEarnings += earnings;
    partner.todayEarnings += earnings;

    // Update moving average for delivery time
    if(deliveryTimeMins > 0) {
      const prevTotal = (partner.averageDeliveryTime || 0) * (partner.completedDeliveries - 1);
      partner.averageDeliveryTime = (prevTotal + deliveryTimeMins) / partner.completedDeliveries;
    }

    await partner.save();

    res.json({ success: true, data: delivery, earnings });
  } catch (error) {
    next(error);
  }
};

// Get my partner profile
exports.getMyPartnerProfile = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const partner = await DeliveryPartner.findOne({ userId })
      .populate({
        path: 'activeDeliveries',
        populate: [
          { path: 'shopId', select: 'shopName address location phone' },
          { path: 'userId', select: 'name phone address' }
        ]
      });

    if (!partner) return res.status(404).json({ success: false, message: 'Not registered as partner' });

    // Reset today's earnings if a new day has started
    const lastUpdate = new Date(partner.updatedAt);
    const now = new Date();
    if (lastUpdate.toDateString() !== now.toDateString()) {
      partner.todayEarnings = 0;
      await partner.save();
    }

    res.json({ success: true, data: partner });
  } catch (error) {
    next(error);
  }
};

// Self verify for testing
exports.verifySelf = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const partner = await DeliveryPartner.findOneAndUpdate(
      { userId },
      { kycStatus: 'verified' },
      { new: true }
    );

    if (!partner) return res.status(404).json({ success: false, message: 'Partner not found' });

    res.json({ success: true, data: partner });
  } catch (error) {
    next(error);
  }
};

// Get earnings summary
exports.getEarnings = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner) return res.status(404).json({ success: false, message: 'Not a partner' });

    res.json({
      success: true,
      data: {
        balance: partner.earningsBalance,
        totalEarnings: partner.totalEarnings,
        totalDeliveries: partner.totalDeliveries,
        rating: partner.rating,
      },
    });
  } catch (error) {
    next(error);
  }
};
