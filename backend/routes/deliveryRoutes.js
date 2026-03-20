const express = require('express');
const { createDeliveryRequest, getMyDeliveryRequests, getShopDeliveryRequests, updateDeliveryStatus } = require('../controllers/deliveryController');
const { protect, authorize } = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/', createDeliveryRequest);
router.get('/my-requests', getMyDeliveryRequests);
router.get('/shop-requests', authorize('owner'), getShopDeliveryRequests);
router.patch('/:id/status', authorize('owner'), updateDeliveryStatus);

module.exports = router;
