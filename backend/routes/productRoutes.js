const express = require('express');
const multer = require('multer');
const path = require('path');
const {
  addProduct,
  getProductsByShop,
  getProductById,
  updateProduct,
  deleteProduct,
  getOwnerProducts,
} = require('../controllers/productController');
const { protect, authorize } = require('../middlewares/authMiddleware');
const { productValidation } = require('../middlewares/validationMiddleware');

const router = express.Router();

const { storage } = require('../config/cloudinary');

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
});

// Public routes
router.get('/shop/:shopId', getProductsByShop);

// Protected routes (owner only) - must be BEFORE /:id to avoid catching 'owner' as id
router.get('/owner/my-products', protect, authorize('owner'), getOwnerProducts);
router.post('/', protect, authorize('owner'), upload.array('images', 5), productValidation, addProduct);
router.put('/:id', protect, authorize('owner'), upload.array('images', 5), updateProduct);
router.delete('/:id', protect, authorize('owner'), deleteProduct);

// Public parameterized route - MUST be after specific paths
router.get('/:id', getProductById);

module.exports = router;
