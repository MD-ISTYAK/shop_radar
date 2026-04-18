const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  createReview,
  getShopReviews,
  upvoteReview,
  addOwnerReply,
  deleteReview,
} = require('../controllers/reviewController');

router.post('/', protect, createReview);
router.get('/shop/:shopId', getShopReviews);
router.post('/:id/upvote', protect, upvoteReview);
router.post('/:id/reply', protect, addOwnerReply);
router.delete('/:id', protect, deleteReview);

module.exports = router;
