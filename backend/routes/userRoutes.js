const express = require('express');
const { getUserProfile, searchUsers } = require('../controllers/socialController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(protect);

// Search must come before :userId param route
router.get('/search', searchUsers);
router.get('/:userId', getUserProfile);

module.exports = router;
