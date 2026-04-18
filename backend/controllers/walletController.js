const Wallet = require('../models/Wallet');

// Get wallet balance
exports.getWallet = async (req, res, next) => {
  try {
    const userId = req.user._id;
    let wallet = await Wallet.findOne({ userId });

    if (!wallet) {
      wallet = await Wallet.create({ userId });
    }

    res.json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};

// Get transaction history
exports.getTransactions = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;

    const wallet = await Wallet.findOne({ userId });
    if (!wallet) return res.json({ success: true, data: [] });

    const transactions = wallet.transactions
      .sort((a, b) => b.createdAt - a.createdAt)
      .slice((page - 1) * limit, page * limit);

    res.json({
      success: true,
      data: transactions,
      balance: wallet.balance,
      pagination: {
        page,
        limit,
        total: wallet.transactions.length,
        pages: Math.ceil(wallet.transactions.length / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

// Add money to wallet (after Razorpay payment verification)
exports.addMoney = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { amount, paymentId } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid amount' });
    }

    let wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      wallet = await Wallet.create({ userId });
    }

    wallet.balance += amount;
    wallet.totalCredited += amount;
    wallet.transactions.push({
      type: 'credit',
      amount,
      description: 'Wallet top-up via Razorpay',
      referenceType: 'topup',
      referenceId: paymentId || '',
      balanceAfter: wallet.balance,
    });
    await wallet.save();

    res.json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};

// Debit from wallet (for orders)
exports.debitWallet = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { amount, description, referenceType, referenceId } = req.body;

    const wallet = await Wallet.findOne({ userId });
    if (!wallet) return res.status(404).json({ success: false, message: 'Wallet not found' });

    if (wallet.balance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient balance' });
    }

    wallet.balance -= amount;
    wallet.totalDebited += amount;
    wallet.transactions.push({
      type: 'debit',
      amount,
      description: description || 'Payment',
      referenceType: referenceType || 'order',
      referenceId: referenceId || '',
      balanceAfter: wallet.balance,
    });
    await wallet.save();

    res.json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};

// Credit wallet (for rewards, referrals, delivery earnings)
exports.creditWallet = async (req, res, next) => {
  try {
    const userId = req.body.userId || req.user._id;
    const { amount, description, referenceType, referenceId } = req.body;

    let wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      wallet = await Wallet.create({ userId });
    }

    wallet.balance += amount;
    wallet.totalCredited += amount;
    wallet.transactions.push({
      type: 'credit',
      amount,
      description: description || 'Credit',
      referenceType: referenceType || 'reward',
      referenceId: referenceId || '',
      balanceAfter: wallet.balance,
    });
    await wallet.save();

    res.json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};
