const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const { getDashboardStats } = require('../controllers/financialController');

router.get('/dashboard', protect, getDashboardStats);

module.exports = router;
