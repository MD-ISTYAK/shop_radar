const DeliveryPartner = require('../models/DeliveryPartner');
const DeliveryRequest = require('../models/DeliveryRequest');
const User = require('../models/User');

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

    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner) return res.status(404).json({ success: false, message: 'Not a partner' });

    if (partner.activeDeliveryId) {
      return res.status(400).json({ success: false, message: 'Complete current delivery first' });
    }

    const delivery = await DeliveryRequest.findById(deliveryId);
    if (!delivery || delivery.deliveryPartnerId) {
      return res.status(400).json({ success: false, message: 'Delivery already taken or not found' });
    }

    delivery.deliveryPartnerId = userId;
    delivery.status = 'partner_assigned';
    await delivery.save();

    partner.activeDeliveryId = delivery._id;
    await partner.save();

    const populated = await DeliveryRequest.findById(deliveryId)
      .populate('shopId', 'shopName address location phone')
      .populate('userId', 'name phone address');

    res.json({ success: true, data: populated });
  } catch (error) {
    next(error);
  }
};

// Complete a delivery
exports.completeDelivery = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { deliveryId } = req.params;

    const partner = await DeliveryPartner.findOne({ userId });
    if (!partner) return res.status(404).json({ success: false, message: 'Not a partner' });

    const delivery = await DeliveryRequest.findById(deliveryId);
    if (!delivery || delivery.deliveryPartnerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not your delivery' });
    }

    delivery.status = 'delivered';
    await delivery.save();

    // Calculate and credit earnings
    const earnings = delivery.deliveryFee * 0.85; // 85% to partner, 15% platform
    partner.activeDeliveryId = null;
    partner.totalDeliveries += 1;
    partner.earningsBalance += earnings;
    partner.totalEarnings += earnings;
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
      .populate('activeDeliveryId');

    if (!partner) return res.status(404).json({ success: false, message: 'Not registered as partner' });

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
