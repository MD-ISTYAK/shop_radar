const Business = require('../models/Business');
const Shop = require('../models/Shop');
const DeliveryPartner = require('../models/DeliveryPartner');
const User = require('../models/User');

// @desc    Register a new business
// @route   POST /api/business/register
const registerBusiness = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { businessType, businessName, description, category, serviceArea, contactPhone } = req.body;

    if (!businessType || !businessName) {
      return res.status(400).json({
        success: false,
        message: 'Business type and name are required',
      });
    }

    // For delivery_partner type, check if already registered
    if (businessType === 'delivery_partner') {
      const existingDP = await DeliveryPartner.findOne({ userId });
      if (existingDP) {
        // Check if business record already exists
        const existingBiz = await Business.findOne({ userId, businessType: 'delivery_partner' });
        if (existingBiz) {
          return res.status(400).json({
            success: false,
            message: 'You are already registered as a delivery partner',
          });
        }
        // Create business record for existing delivery partner
        const business = await Business.create({
          userId,
          businessType: 'delivery_partner',
          businessName,
          description: description || 'Delivery Partner',
          deliveryPartnerRef: existingDP._id,
          contactPhone: contactPhone || req.user.phone,
        });
        return res.status(201).json({ success: true, data: business });
      }
    }

    // For shop type, we just create the business record
    // The actual shop will be created via the add-shop screen
    const businessData = {
      userId,
      businessType,
      businessName,
      description: description || '',
      category: category || '',
      serviceArea: serviceArea || '',
      contactPhone: contactPhone || req.user.phone || '',
    };

    const business = await Business.create(businessData);

    // Update user to indicate they have a business account
    await User.findByIdAndUpdate(userId, {
      $addToSet: { businesses: business._id },
    });

    res.status(201).json({
      success: true,
      message: 'Business registered successfully',
      data: business,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all user's businesses
// @route   GET /api/business/my-businesses
const getMyBusinesses = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const businesses = await Business.find({ userId, isActive: true })
      .populate('shopRef', 'shopName status logo category rating')
      .populate('deliveryPartnerRef', 'isOnline kycStatus totalDeliveries rating')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: businesses });
  } catch (error) {
    next(error);
  }
};

// @desc    Get business by ID
// @route   GET /api/business/:id
const getBusinessById = async (req, res, next) => {
  try {
    const business = await Business.findById(req.params.id)
      .populate('shopRef')
      .populate('deliveryPartnerRef');

    if (!business) {
      return res.status(404).json({ success: false, message: 'Business not found' });
    }

    // Ensure the requester owns this business
    if (business.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    res.json({ success: true, data: business });
  } catch (error) {
    next(error);
  }
};

// @desc    Update business
// @route   PUT /api/business/:id
const updateBusiness = async (req, res, next) => {
  try {
    const business = await Business.findById(req.params.id);

    if (!business) {
      return res.status(404).json({ success: false, message: 'Business not found' });
    }

    if (business.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const { businessName, description, category, serviceArea, contactPhone } = req.body;

    if (businessName) business.businessName = businessName;
    if (description !== undefined) business.description = description;
    if (category) business.category = category;
    if (serviceArea !== undefined) business.serviceArea = serviceArea;
    if (contactPhone) business.contactPhone = contactPhone;

    await business.save();

    res.json({ success: true, message: 'Business updated', data: business });
  } catch (error) {
    next(error);
  }
};

// @desc    Deactivate/delete business
// @route   DELETE /api/business/:id
const deleteBusiness = async (req, res, next) => {
  try {
    const business = await Business.findById(req.params.id);

    if (!business) {
      return res.status(404).json({ success: false, message: 'Business not found' });
    }

    if (business.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    // Soft delete — just mark as inactive
    business.isActive = false;
    business.status = 'suspended';
    await business.save();

    // Remove from user's businesses array
    await User.findByIdAndUpdate(req.user._id, {
      $pull: { businesses: business._id },
    });

    res.json({ success: true, message: 'Business deactivated' });
  } catch (error) {
    next(error);
  }
};

// @desc    Link a shop to a business record
// @route   POST /api/business/:id/link-shop
const linkShop = async (req, res, next) => {
  try {
    const { shopId } = req.body;
    const business = await Business.findById(req.params.id);

    if (!business) {
      return res.status(404).json({ success: false, message: 'Business not found' });
    }

    if (business.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (business.businessType !== 'shop') {
      return res.status(400).json({ success: false, message: 'Business is not a shop type' });
    }

    business.shopRef = shopId;
    await business.save();

    res.json({ success: true, data: business });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registerBusiness,
  getMyBusinesses,
  getBusinessById,
  updateBusiness,
  deleteBusiness,
  linkShop,
};
