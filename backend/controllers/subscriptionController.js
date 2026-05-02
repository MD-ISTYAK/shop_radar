const User = require('../models/User');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const logger = require('../config/logger');

// Initialize Razorpay (use env vars in production, fallback for dev)
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_YourKeyIdHere',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'YourKeySecretHere',
});

const PLANS = {
  free: {
    id: 'free',
    name: 'Free',
    price: 0,
    features: ['1 Shop or Service Listing', 'Delivery Partner Access', 'Standard Support'],
  },
  pro: {
    id: 'pro',
    name: 'Pro',
    price: 299,
    features: ['Up to 3 Shops/Services', 'Priority Support', 'Advanced Analytics'],
  },
  ultra_pro: {
    id: 'ultra_pro',
    name: 'Ultra Pro',
    price: 499,
    features: ['Unlimited Shops/Services', '0% Platform Fee on Deliveries', 'Premium Placement'],
  },
};

// @desc    Get subscription plans
// @route   GET /api/subscription/plans
exports.getPlans = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      data: Object.values(PLANS),
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create Razorpay Order for Subscription
// @route   POST /api/subscription/order
exports.createOrder = async (req, res, next) => {
  try {
    const { planId } = req.body;
    
    if (!PLANS[planId] || planId === 'free') {
      return res.status(400).json({ success: false, message: 'Invalid plan selected' });
    }

    const amount = PLANS[planId].price * 100; // Razorpay expects amount in paise (INR)

    const options = {
      amount,
      currency: 'INR',
      receipt: `receipt_sub_${req.user._id}_${Date.now()}`,
    };

    const order = await razorpay.orders.create(options);

    res.status(200).json({
      success: true,
      data: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        planId,
      },
    });
  } catch (error) {
    logger.error('Razorpay create order failed', error);
    next(error);
  }
};

// @desc    Verify Payment and Upgrade User
// @route   POST /api/subscription/verify
exports.verifyPayment = async (req, res, next) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, planId } = req.body;

    // Verify signature
    const secret = process.env.RAZORPAY_KEY_SECRET || 'YourKeySecretHere';
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto.createHmac('sha256', secret).update(body.toString()).digest('hex');

    if (expectedSignature !== razorpay_signature) {
      return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }

    // Set expiration to 30 days from now
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        subscription: {
          plan: planId,
          expiresAt,
          razorpaySubscriptionId: razorpay_payment_id, // storing payment ID as ref for now
        },
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: 'Subscription upgraded successfully',
      data: user,
    });
  } catch (error) {
    logger.error('Razorpay verify failed', error);
    next(error);
  }
};
