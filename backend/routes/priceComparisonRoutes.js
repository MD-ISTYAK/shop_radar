const express = require('express');
const router = express.Router();
const {
  compareProductPrice,
  getPriceHistory,
} = require('../controllers/priceComparisonController');

router.get('/compare', compareProductPrice);
router.get('/history/:productId', getPriceHistory);

module.exports = router;
