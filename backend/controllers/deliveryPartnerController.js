const DeliveryPartner = require('../models/DeliveryPartner');
const DeliveryRequest = require('../models/DeliveryRequest');
const Order = require('../models/Order');
const User = require('../models/User');
const Business = require('../models/Business');
const { calculateDistance } = require('../utils/geoDistance');
const logger = require('../config/logger');

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

    // Create a Business record instead of changing user role
    const existingBiz = await Business.findOne({ userId, businessType: 'delivery_partner' });
    if (!existingBiz) {
      const business = await Business.create({
        userId,
        businessType: 'delivery_partner',
        businessName: `${req.user.name}'s Delivery`,
        description: 'Delivery Partner',
        deliveryPartnerRef: partner._id,
        contactPhone: req.user.phone || '',
      });

      await User.findByIdAndUpdate(userId, {
        $addToSet: { businesses: business._id },
      });
    }

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

    // 1. Atomically assign partner if it is still null (prevents double-assignment)
    const delivery = await DeliveryRequest.findOneAndUpdate(
      { _id: deliveryId, deliveryPartnerId: null, status: 'accepted' },
      {
        deliveryPartnerId: userId,
        status: 'partner_assigned',
        assignedAt: new Date(),
      },
      { new: true }
    ).populate('shopId', 'shopName address location phone').populate('userId', 'name phone address');

    if (!delivery) {
      await DeliveryPartner.findOneAndUpdate({ userId }, { $inc: { missedRequests: 1 } });
      return res.status(400).json({ 
        success: false, 
        message: 'Too late! This request was already accepted by another partner.' 
      });
    }

    // 2. Update Partner stats and active deliveries
    await DeliveryPartner.findOneAndUpdate(
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
    try {
      const { getIO } = require('../config/socketManager');
      const io = getIO();
      io.emit('delivery:claimed', { deliveryId, claimerId: userId });
    } catch (e) {}

    logger.info('Delivery accepted', {
      requestId: req.requestId,
      deliveryId,
      partnerId: userId.toString(),
    });

    res.json({ success: true, data: delivery });
  } catch (error) {
    next(error);
  }
};

// Reject a delivery explicitly
exports.rejectDelivery = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { deliveryId } = req.params;

    const delivery = await DeliveryRequest.findById(deliveryId);
    if (!delivery) return res.status(404).json({ success: false, message: 'Delivery not found' });

    // Only reject if it's assigned to this partner
    if (delivery.deliveryPartnerId && delivery.deliveryPartnerId.toString() === userId.toString()) {
      // Reassign
      delivery.previousPartners.push(userId);
      delivery.deliveryPartnerId = null;
      delivery.status = 'accepted'; // Back to pool
      delivery.reassignmentCount += 1;
      delivery.assignedAt = null;
      await delivery.save();

      // Update partner stats
      await DeliveryPartner.findOneAndUpdate(
        { userId },
        {
          $pull: { activeDeliveries: deliveryId },
          $inc: { rejectedDeliveries: 1 },
        }
      );

      // Update order
      const order = await Order.findById(delivery.orderId);
      if (order) {
        order.deliveryPartnerId = null;
        order.status = 'ready'; // Back to ready for assignment
        order.timeline.push({ status: 'partner_rejected', note: 'Delivery partner rejected, looking for another' });
        await order.save();
      }

      // Re-notify nearby partners
      exports.notifyNearbyPartners(delivery);
    } else {
      await DeliveryPartner.findOneAndUpdate({ userId }, { $inc: { rejectedDeliveries: 1 } });
    }

    res.json({ success: true, message: 'Delivery rejected' });
  } catch (error) {
    next(error);
  }
};

// Reassign delivery (admin or automatic)
exports.reassignDelivery = async (req, res, next) => {
  try {
    const { deliveryId } = req.params;
    const { newPartnerId } = req.body;

    const delivery = await DeliveryRequest.findById(deliveryId);
    if (!delivery) return res.status(404).json({ success: false, message: 'Delivery not found' });

    if (delivery.reassignmentCount >= 3) {
      return res.status(400).json({ success: false, message: 'Maximum reassignment limit reached (3)' });
    }

    // Release current partner
    if (delivery.deliveryPartnerId) {
      delivery.previousPartners.push(delivery.deliveryPartnerId);
      await DeliveryPartner.findOneAndUpdate(
        { userId: delivery.deliveryPartnerId },
        { $pull: { activeDeliveries: deliveryId } }
      );
    }

    if (newPartnerId) {
      // Manual reassignment to specific partner
      delivery.deliveryPartnerId = newPartnerId;
      delivery.status = 'partner_assigned';
      delivery.assignedAt = new Date();

      await DeliveryPartner.findOneAndUpdate(
        { userId: newPartnerId },
        { $addToSet: { activeDeliveries: deliveryId } }
      );
    } else {
      // Put back in pool
      delivery.deliveryPartnerId = null;
      delivery.status = 'accepted';
      delivery.assignedAt = null;
      exports.notifyNearbyPartners(delivery);
    }

    delivery.reassignmentCount += 1;
    await delivery.save();

    // Update order
    const order = await Order.findById(delivery.orderId);
    if (order) {
      order.deliveryPartnerId = newPartnerId || null;
      order.timeline.push({ status: 'reassigned', note: `Delivery reassigned (attempt ${delivery.reassignmentCount})` });
      await order.save();
    }

    res.json({ success: true, data: delivery });
  } catch (error) {
    next(error);
  }
};

// Notify nearby delivery partners helper (with radius fallback)
exports.notifyNearbyPartners = async (deliveryRequest) => {
  try {
    const { getIO } = require('../config/socketManager');
    const io = getIO();
    const shopLoc = deliveryRequest.shopLocation.coordinates; // [lng, lat]

    // Try 5km first, then 10km fallback
    let partners = await DeliveryPartner.find({
      isOnline: true,
      kycStatus: 'verified',
      userId: { $nin: deliveryRequest.previousPartners || [] }, // Exclude previously rejected partners
      currentLocation: {
        $near: {
          $geometry: { type: 'Point', coordinates: shopLoc },
          $maxDistance: 5000, // 5km
        }
      }
    });

    if (partners.length === 0) {
      // Fallback to 10km radius
      partners = await DeliveryPartner.find({
        isOnline: true,
        kycStatus: 'verified',
        userId: { $nin: deliveryRequest.previousPartners || [] },
        currentLocation: {
          $near: {
            $geometry: { type: 'Point', coordinates: shopLoc },
            $maxDistance: 10000, // 10km
          }
        }
      });
    }

    if (partners.length === 0) {
      // Mark as no partner available
      await DeliveryRequest.findByIdAndUpdate(deliveryRequest._id, { noPartnerAvailable: true });
      logger.warn('No delivery partners available', { deliveryId: deliveryRequest._id.toString() });
      return;
    }

    partners.forEach(partner => {
      io.to(`user:${partner.userId}`).emit('delivery:newRequest', deliveryRequest);
    });

    logger.info(`Notified ${partners.length} nearby partners`, {
      deliveryId: deliveryRequest._id.toString(),
    });
  } catch (error) {
    logger.error('Notification Error:', { error: error.message });
  }
};

// Complete a delivery (with OTP and Images)
exports.completeDelivery = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { deliveryId } = req.params;
    const { otp } = req.body;
    console.log(`[completeDelivery] userId: ${userId}, deliveryId: ${deliveryId}, otp: ${otp}`);

    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner) {
      console.log(`[completeDelivery] Partner not found for userId: ${userId}`);
      return res.status(404).json({ success: false, message: 'Not a partner' });
    }

    const delivery = await DeliveryRequest.findById(deliveryId);
    if (!delivery || delivery.deliveryPartnerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not your delivery' });
    }

    const order = await Order.findById(delivery.orderId);
    if (!order) {
      console.log(`[completeDelivery] Order not found for deliveryId: ${deliveryId}, orderId: ${delivery.orderId}`);
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

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
    delivery.deliveredAt = new Date();
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
