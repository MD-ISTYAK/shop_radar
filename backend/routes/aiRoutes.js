const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  getShoppingAssistant,
  getCrowdPrediction,
  getBestTimeToVisit,
  getAlternativeShop,
  getBargainRange,
} = require('../controllers/aiController');

router.post('/shopping-assistant', protect, getShoppingAssistant);
router.get('/crowd-prediction/:shopId', getCrowdPrediction);
router.get('/best-time/:shopId', getBestTimeToVisit);
router.get('/alternative/:shopId', getAlternativeShop);
router.get('/bargain', getBargainRange);

module.exports = router;
