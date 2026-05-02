const express = require('express');
const { getPlans, createOrder, verifyPayment } = require('../controllers/subscriptionController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.get('/plans', getPlans);
router.post('/order', protect, createOrder);
router.post('/verify', protect, verifyPayment);

module.exports = router;
