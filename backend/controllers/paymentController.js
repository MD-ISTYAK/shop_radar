const crypto = require('crypto');
const Razorpay = require('razorpay');
const Order = require('../models/Order');
const PaymentLog = require('../models/PaymentLog');
const logger = require('../config/logger');

// Lazy Razorpay initialization — avoids crash when keys aren't configured
let _razorpay = null;
const getRazorpay = () => {
  if (!_razorpay) {
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      throw new Error('Razorpay credentials not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in .env');
    }
    _razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
  }
  return _razorpay;
};

// @desc    Create Razorpay order for payment
// @route   POST /api/payments/create-order
exports.createPaymentOrder = async (req, res, next) => {
  try {
    const { orderId } = req.body;
    const userId = req.user._id;

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (order.paymentStatus === 'paid') {
      return res.status(400).json({ success: false, message: 'Order already paid' });
    }

    const totalAmount = order.totalAmount + (order.deliveryFee || 0);

    // Check for existing initiated payment to prevent duplicates
    const existingLog = await PaymentLog.findOne({
      orderId: order._id,
      status: 'initiated',
    });

    let razorpayOrder;
    if (existingLog && existingLog.providerOrderId) {
      // Return existing order if still valid
      try {
        razorpayOrder = await getRazorpay().orders.fetch(existingLog.providerOrderId);
        if (razorpayOrder.status === 'created') {
          return res.status(200).json({
            success: true,
            data: {
              razorpayOrderId: razorpayOrder.id,
              amount: razorpayOrder.amount,
              currency: razorpayOrder.currency,
              orderId: order._id,
            },
          });
        }
      } catch (e) {
        // Existing order expired or invalid, create new one
        logger.warn('Existing Razorpay order invalid, creating new', { requestId: req.requestId });
      }
    }

    // Create new Razorpay order
    razorpayOrder = await getRazorpay().orders.create({
      amount: Math.round(totalAmount * 100), // Razorpay expects paise
      currency: 'INR',
      receipt: order.orderId,
      notes: {
        shopRadarOrderId: order._id.toString(),
        userId: userId.toString(),
      },
    });

    // Log payment initiation
    await PaymentLog.create({
      orderId: order._id,
      userId,
      amount: totalAmount,
      method: 'razorpay',
      provider: 'razorpay',
      providerOrderId: razorpayOrder.id,
      status: 'initiated',
    });

    logger.info('Razorpay order created', {
      requestId: req.requestId,
      userId: userId.toString(),
      orderId: order._id.toString(),
      razorpayOrderId: razorpayOrder.id,
      amount: totalAmount,
    });

    res.status(200).json({
      success: true,
      data: {
        razorpayOrderId: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency,
        orderId: order._id,
        keyId: process.env.RAZORPAY_KEY_ID,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Verify payment after frontend checkout
// @route   POST /api/payments/verify
exports.verifyPayment = async (req, res, next) => {
  try {
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature, orderId } = req.body;
    const userId = req.user._id;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({ success: false, message: 'Missing payment details' });
    }

    // Verify signature
    const generatedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    if (generatedSignature !== razorpaySignature) {
      // Log failed verification
      await PaymentLog.findOneAndUpdate(
        { providerOrderId: razorpayOrderId },
        {
          status: 'failed',
          failureReason: 'Signature verification failed',
          providerPaymentId: razorpayPaymentId,
          providerSignature: razorpaySignature,
        }
      );

      logger.warn('Payment signature verification failed', {
        requestId: req.requestId,
        razorpayOrderId,
        userId: userId.toString(),
      });

      return res.status(400).json({ success: false, message: 'Payment verification failed' });
    }

    // Idempotency check: skip if already processed
    const existingSuccess = await PaymentLog.findOne({
      providerOrderId: razorpayOrderId,
      status: 'success',
    });
    if (existingSuccess) {
      return res.status(200).json({ success: true, message: 'Payment already verified' });
    }

    // Update PaymentLog
    await PaymentLog.findOneAndUpdate(
      { providerOrderId: razorpayOrderId },
      {
        status: 'success',
        providerPaymentId: razorpayPaymentId,
        providerSignature: razorpaySignature,
      }
    );

    // Update Order
    const order = await Order.findById(orderId);
    if (order) {
      order.paymentStatus = 'paid';
      order.paymentId = razorpayPaymentId;
      order.paymentDetails = {
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
      };
      order.timeline.push({ status: 'payment_confirmed', note: 'Payment verified successfully' });
      await order.save();
    }

    logger.info('Payment verified successfully', {
      requestId: req.requestId,
      userId: userId.toString(),
      orderId: orderId,
      razorpayPaymentId,
    });

    res.status(200).json({
      success: true,
      message: 'Payment verified successfully',
      data: { orderId, paymentStatus: 'paid' },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Razorpay webhook handler (NO auth middleware)
// @route   POST /api/payments/webhook
exports.handleWebhook = async (req, res) => {
  try {
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    const signature = req.headers['x-razorpay-signature'];

    if (!signature || !webhookSecret) {
      logger.warn('Webhook received without signature or secret');
      return res.status(400).json({ success: false });
    }

    // Verify webhook signature
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(req.body) // raw body
      .digest('hex');

    if (expectedSignature !== signature) {
      logger.warn('Webhook signature mismatch');
      return res.status(400).json({ success: false });
    }

    const event = JSON.parse(req.body);
    const eventType = event.event;

    logger.info(`Webhook received: ${eventType}`, {
      eventType,
      paymentId: event.payload?.payment?.entity?.id,
    });

    if (eventType === 'payment.captured' || eventType === 'payment.authorized') {
      const payment = event.payload.payment.entity;
      const razorpayOrderId = payment.order_id;

      // Idempotency: skip if already processed
      const existing = await PaymentLog.findOne({
        providerOrderId: razorpayOrderId,
        status: 'success',
      });
      if (existing) {
        return res.status(200).json({ success: true, message: 'Already processed' });
      }

      // Update PaymentLog
      const paymentLog = await PaymentLog.findOneAndUpdate(
        { providerOrderId: razorpayOrderId },
        {
          status: 'success',
          providerPaymentId: payment.id,
          webhookPayload: event,
        },
        { new: true }
      );

      // Update Order
      if (paymentLog) {
        await Order.findByIdAndUpdate(paymentLog.orderId, {
          paymentStatus: 'paid',
          paymentId: payment.id,
        });
      }
    }

    if (eventType === 'payment.failed') {
      const payment = event.payload.payment.entity;
      const razorpayOrderId = payment.order_id;

      await PaymentLog.findOneAndUpdate(
        { providerOrderId: razorpayOrderId },
        {
          status: 'failed',
          failureReason: payment.error_description || 'Payment failed',
          webhookPayload: event,
          $inc: { retryCount: 1 },
        }
      );
    }

    // Always respond 200 to Razorpay
    res.status(200).json({ success: true });
  } catch (error) {
    logger.error('Webhook processing error', { error: error.message });
    // Still respond 200 to prevent Razorpay retries on our errors
    res.status(200).json({ success: true });
  }
};

// @desc    Get payment status for an order
// @route   GET /api/payments/:orderId/status
exports.getPaymentStatus = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const userId = req.user._id;

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const latestPayment = await PaymentLog.findOne({ orderId })
      .sort({ createdAt: -1 })
      .select('status amount method providerPaymentId failureReason createdAt');

    res.status(200).json({
      success: true,
      data: {
        orderPaymentStatus: order.paymentStatus,
        paymentMethod: order.paymentMethod,
        latestPayment: latestPayment || null,
      },
    });
  } catch (error) {
    next(error);
  }
};
