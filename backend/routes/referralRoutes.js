const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  getMyReferrals,
  applyReferralCode,
} = require('../controllers/referralController');

router.get('/my-referrals', protect, getMyReferrals);
router.post('/apply', protect, applyReferralCode);

module.exports = router;
