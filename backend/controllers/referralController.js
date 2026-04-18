const Referral = require('../models/Referral');
const User = require('../models/User');
const Wallet = require('../models/Wallet');
const crypto = require('crypto');

// Generate referral code (auto-called on registration)
exports.generateReferralCode = async (userId) => {
  const code = 'SR' + crypto.randomBytes(3).toString('hex').toUpperCase();
  await User.findByIdAndUpdate(userId, { referralCode: code });
  return code;
};

// Get my referral info
exports.getMyReferrals = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const user = await User.findById(userId).select('referralCode');

    const referrals = await Referral.find({ referrerId: userId })
      .populate('refereeId', 'name avatar createdAt')
      .sort({ createdAt: -1 });

    const totalRewards = referrals
      .filter(r => r.status === 'rewarded')
      .reduce((sum, r) => sum + r.rewardAmount, 0);

    res.json({
      success: true,
      data: {
        referralCode: user.referralCode,
        referrals,
        totalReferrals: referrals.length,
        completedReferrals: referrals.filter(r => r.status === 'completed' || r.status === 'rewarded').length,
        totalRewards,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Apply referral code (called during registration)
exports.applyReferralCode = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { referralCode } = req.body;

    if (!referralCode) {
      return res.status(400).json({ success: false, message: 'Referral code is required' });
    }

    // Find referrer
    const referrer = await User.findOne({ referralCode });
    if (!referrer) {
      return res.status(404).json({ success: false, message: 'Invalid referral code' });
    }

    if (referrer._id.toString() === userId.toString()) {
      return res.status(400).json({ success: false, message: 'Cannot use your own referral code' });
    }

    // Check if already referred
    const existing = await Referral.findOne({ refereeId: userId });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Already used a referral code' });
    }

    const referral = await Referral.create({
      referrerId: referrer._id,
      refereeId: userId,
      referralCode,
      status: 'completed',
      completedAt: new Date(),
    });

    // Credit both wallets
    const rewardAmount = 50;
    for (const uid of [referrer._id, userId]) {
      let wallet = await Wallet.findOne({ userId: uid });
      if (!wallet) wallet = await Wallet.create({ userId: uid });

      wallet.balance += rewardAmount;
      wallet.totalCredited += rewardAmount;
      wallet.transactions.push({
        type: 'credit',
        amount: rewardAmount,
        description: uid.toString() === referrer._id.toString()
          ? 'Referral reward - friend joined!'
          : 'Welcome bonus - joined via referral!',
        referenceType: 'referral',
        referenceId: referral._id.toString(),
        balanceAfter: wallet.balance,
      });
      await wallet.save();
    }

    referral.status = 'rewarded';
    referral.rewardedAt = new Date();
    await referral.save();

    await User.findByIdAndUpdate(userId, { referredBy: referralCode });

    res.json({ success: true, data: referral, message: '₹50 added to both wallets!' });
  } catch (error) {
    next(error);
  }
};
