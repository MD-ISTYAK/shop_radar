const { body, validationResult } = require('express-validator');

// Handle validation results
const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map((err) => ({
        field: err.path,
        message: err.msg,
      })),
    });
  }
  next();
};

// Auth validation rules
const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name is required').isLength({ min: 2, max: 50 }).withMessage('Name must be 2-50 characters'),
  body('email').trim().isEmail().withMessage('Please enter a valid email').normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('phone').trim().notEmpty().withMessage('Phone number is required'),
  body('role').optional().isIn(['user', 'owner']).withMessage('Role must be user or owner'),
  handleValidation,
];

const loginValidation = [
  body('email').trim().isEmail().withMessage('Please enter a valid email').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
  handleValidation,
];

// Shop validation rules
const shopValidation = [
  body('shopName').trim().notEmpty().withMessage('Shop name is required'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('address').trim().notEmpty().withMessage('Address is required'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude is required'),
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude is required'),
  body('openingTime').trim().notEmpty().withMessage('Opening time is required'),
  body('closingTime').trim().notEmpty().withMessage('Closing time is required'),
  body('phone').trim().notEmpty().withMessage('Phone number is required'),
  handleValidation,
];

// Product validation rules
const productValidation = [
  body('name').trim().notEmpty().withMessage('Product name is required'),
  body('price').isFloat({ min: 0 }).withMessage('Price must be a positive number'),
  body('stock').isInt({ min: 0 }).withMessage('Stock must be a non-negative integer'),
  body('discount').optional().isFloat({ min: 0, max: 100 }).withMessage('Discount must be 0-100'),
  handleValidation,
];

// Cart validation rules
const cartValidation = [
  body('productId').notEmpty().withMessage('Product ID is required').isMongoId().withMessage('Invalid product ID'),
  body('quantity').optional().isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
  handleValidation,
];

module.exports = {
  registerValidation,
  loginValidation,
  shopValidation,
  productValidation,
  cartValidation,
};
