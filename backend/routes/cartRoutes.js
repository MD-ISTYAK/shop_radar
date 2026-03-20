const express = require('express');
const { addToCart, getCart, updateCartItem, removeFromCart, checkout } = require('../controllers/cartController');
const { protect } = require('../middlewares/authMiddleware');
const { cartValidation } = require('../middlewares/validationMiddleware');

const router = express.Router();

router.use(protect); // All cart routes require authentication

router.post('/add', cartValidation, addToCart);
router.get('/', getCart);
router.put('/update', updateCartItem);
router.delete('/remove/:productId', removeFromCart);
router.post('/checkout', checkout);

module.exports = router;
