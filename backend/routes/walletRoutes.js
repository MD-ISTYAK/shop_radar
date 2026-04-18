const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  getWallet,
  getTransactions,
  addMoney,
  debitWallet,
  creditWallet,
} = require('../controllers/walletController');

router.get('/', protect, getWallet);
router.get('/transactions', protect, getTransactions);
router.post('/add-money', protect, addMoney);
router.post('/debit', protect, debitWallet);
router.post('/credit', protect, creditWallet);

module.exports = router;
