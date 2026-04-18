const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  getMyBadges,
  getLeaderboard,
} = require('../controllers/gamificationController');

router.get('/badges', protect, getMyBadges);
router.get('/leaderboard', getLeaderboard);

module.exports = router;
