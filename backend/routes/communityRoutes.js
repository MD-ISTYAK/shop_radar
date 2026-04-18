const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  postQuestion,
  answerQuestion,
  upvoteAnswer,
  getNearbyQuestions,
  getQuestion,
  deleteQuestion,
} = require('../controllers/communityController');

router.post('/', protect, postQuestion);
router.get('/', getNearbyQuestions);
router.get('/:id', getQuestion);
router.post('/:id/answer', protect, answerQuestion);
router.post('/:id/answers/:answerId/upvote', protect, upvoteAnswer);
router.delete('/:id', protect, deleteQuestion);

module.exports = router;
