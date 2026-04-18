const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  checkIn,
  getShopCheckIns,
  getMyCheckIns,
} = require('../controllers/checkInController');

router.post('/', protect, checkIn);
router.get('/shop/:shopId', getShopCheckIns);
router.get('/my-checkins', protect, getMyCheckIns);

module.exports = router;
