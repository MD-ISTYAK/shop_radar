const express = require('express');
const multer = require('multer');
const path = require('path');
const { createShop, getNearbyShops, getShopById, updateShop, toggleStatus, updateShopStatus, updateCrowdLevel, getOwnerShop, getShopFilters } = require('../controllers/shopController');
const { protect, authorize } = require('../middlewares/authMiddleware');
const { shopValidation } = require('../middlewares/validationMiddleware');

const router = express.Router();

const { storage } = require('../config/cloudinary');

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

const shopUpload = upload.fields([
  { name: 'logo', maxCount: 1 },
  { name: 'banner', maxCount: 1 },
]);

// Public routes
router.get('/nearby', getNearbyShops);
router.get('/filters', getShopFilters);

// Protected routes (Any logged-in user can register a business; owner operations require auth)
router.get('/owner/my-shop', protect, getOwnerShop);
router.post('/', protect, shopUpload, shopValidation, createShop);
router.put('/:id', protect, authorize('owner'), shopUpload, updateShop);
router.patch('/:id/toggle-status', protect, authorize('owner'), toggleStatus);
router.patch('/:id/status', protect, authorize('owner'), updateShopStatus);
router.patch('/:id/crowd', protect, authorize('owner'), updateCrowdLevel);

// Public parameterized route - MUST be after specific paths
router.get('/:id', getShopById);

module.exports = router;
