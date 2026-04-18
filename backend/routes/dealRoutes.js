const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  createDeal,
  getNearbyDeals,
  getTrendingDeals,
  toggleSaveDeal,
  getMySavedDeals,
  getShopDeals,
  deleteDeal,
} = require('../controllers/dealController');

router.post('/', protect, createDeal);
router.get('/nearby', getNearbyDeals);
router.get('/trending', getTrendingDeals);
router.get('/saved', protect, getMySavedDeals);
router.get('/shop/:shopId', getShopDeals);
router.post('/:id/save', protect, toggleSaveDeal);
router.delete('/:id', protect, deleteDeal);

module.exports = router;
