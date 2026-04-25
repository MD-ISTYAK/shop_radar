const { verifyToken } = require('../config/jwt');
const User = require('../models/User');
const Business = require('../models/Business');

// Protect routes - verify JWT token
const protect = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized. No token provided.',
      });
    }

    const decoded = verifyToken(token);
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User not found.',
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized. Invalid token.',
    });
  }
};

// Restrict to specific roles
// Now also checks if the user has a Business of the matching type
// e.g., authorize('owner') passes if user.role === 'owner' OR user has a shop-type business
const authorize = (...roles) => {
  return async (req, res, next) => {
    // Direct role match
    if (roles.includes(req.user.role)) {
      return next();
    }

    // Check if user has a business that grants the required role
    try {
      // Map roles to business types
      const roleToBusinessType = {
        'owner': 'shop',
        'delivery_partner': 'delivery_partner',
        'business_owner': null, // any business type
      };

      for (const role of roles) {
        const businessType = roleToBusinessType[role];
        
        if (businessType === undefined) continue; // Unknown role mapping
        
        const query = { userId: req.user._id, isActive: true };
        if (businessType !== null) {
          query.businessType = businessType;
        }
        
        const hasBusiness = await Business.findOne(query);
        if (hasBusiness) {
          // Store the business reference for downstream use
          req.activeBusiness = hasBusiness;
          return next();
        }
      }
    } catch (err) {
      // If business check fails, fall through to denial
      console.error('Business auth check error:', err.message);
    }

    return res.status(403).json({
      success: false,
      message: `Role '${req.user.role}' is not authorized to access this route.`,
    });
  };
};

module.exports = { protect, authorize };
