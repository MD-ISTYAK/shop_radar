const express = require('express');
const router = express.Router();
const multer = require('multer');
const { storage } = require('../config/cloudinary');

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
});

const { protect } = require('../middlewares/authMiddleware');
const {
  getMyOrders,
  getOrderById,
  getShopOrders,
  updateOrderStatus,
  acceptOrder,
  packOrder,
  verifyPickupCode,
  completeShopPickup,
  cancelOrder,
  getShopOrderStats,
  createFlexibleOrder,
  confirmPrice,
  acceptPrice,
} = require('../controllers/orderController');

router.get('/my-orders', protect, getMyOrders);
router.get('/shop-orders', protect, getShopOrders);
router.get('/shop-stats', protect, getShopOrderStats);
router.get('/:id', protect, getOrderById);
router.patch('/:id/status', protect, updateOrderStatus);
router.patch('/:id/accept', protect, acceptOrder);
router.patch('/:id/pack', protect, upload.array('images', 5), packOrder);
router.post('/:id/verify-pickup', protect, verifyPickupCode);
router.post('/:id/complete-pickup', protect, completeShopPickup);
router.patch('/:id/cancel', protect, cancelOrder);

// Flexible order endpoints
router.post('/flexible', protect, createFlexibleOrder);
router.patch('/:id/confirm-price', protect, confirmPrice);
router.patch('/:id/accept-price', protect, acceptPrice);

module.exports = router;
