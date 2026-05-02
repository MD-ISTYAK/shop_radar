const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  createPaymentOrder,
  verifyPayment,
  handleWebhook,
  getPaymentStatus,
} = require('../controllers/paymentController');

// Protected routes
router.post('/create-order', protect, createPaymentOrder);
router.post('/verify', protect, verifyPayment);
router.get('/:orderId/status', protect, getPaymentStatus);

// Webhook — NO auth middleware, raw body parsed in server.js
router.post('/webhook', handleWebhook);

module.exports = router;
