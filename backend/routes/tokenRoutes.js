const express = require('express');
const { takeToken, getQueueStatus, getMyToken, advanceQueue, cancelToken } = require('../controllers/tokenController');
const { protect, authorize } = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/take', takeToken);
router.get('/my-token', getMyToken);
router.get('/shop/:shopId', getQueueStatus);
router.post('/advance/:shopId', authorize('owner'), advanceQueue);
router.delete('/:id', cancelToken);

module.exports = router;
