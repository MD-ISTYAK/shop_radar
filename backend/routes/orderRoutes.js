const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  getMyOrders,
  getOrderById,
  getShopOrders,
  updateOrderStatus,
  cancelOrder,
  getShopOrderStats,
} = require('../controllers/orderController');

router.get('/my-orders', protect, getMyOrders);
router.get('/shop-orders', protect, getShopOrders);
router.get('/shop-stats', protect, getShopOrderStats);
router.get('/:id', protect, getOrderById);
router.patch('/:id/status', protect, updateOrderStatus);
router.patch('/:id/cancel', protect, cancelOrder);

module.exports = router;
