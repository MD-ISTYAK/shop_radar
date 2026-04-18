const Badge = require('../models/Badge');
const User = require('../models/User');
const CheckIn = require('../models/CheckIn');
const Review = require('../models/Review');
const Order = require('../models/Order');
const Follow = require('../models/Follow');
const Deal = require('../models/Deal');
const Referral = require('../models/Referral');

const BADGE_CRITERIA = {
  explorer: { target: 10, description: 'Visit 10 different shops' },
  foodie: { target: 5, description: 'Check in at 5 food shops' },
  saver: { target: 5, description: 'Save 5 deals' },
  trendsetter: { target: 3, description: 'Get 3 reviews with 10+ upvotes' },
  super_shopper: { target: 50, description: 'Place 50 orders' },
  shopradar_hero: { target: 10, description: 'Refer 10 friends' },
  first_review: { target: 1, description: 'Write your first review' },
  social_butterfly: { target: 20, description: 'Follow 20 shops' },
  deal_hunter: { target: 10, description: 'Save 10 deals' },
  loyal_customer: { target: 30, description: '30 check-ins total' },
};

// Check and award badges for a user
exports.checkAndAwardBadges = async (userId) => {
  try {
    const results = [];

    // Explorer badge — unique shops visited
    const uniqueShops = await CheckIn.distinct('shopId', { userId });
    await upsertBadgeProgress(userId, 'explorer', uniqueShops.length, results);

    // First review badge
    const reviewCount = await Review.countDocuments({ userId });
    await upsertBadgeProgress(userId, 'first_review', reviewCount, results);

    // Super shopper badge
    const orderCount = await Order.countDocuments({ userId, status: 'delivered' });
    await upsertBadgeProgress(userId, 'super_shopper', orderCount, results);

    // Social butterfly badge
    const followCount = await Follow.countDocuments({ userId });
    await upsertBadgeProgress(userId, 'social_butterfly', followCount, results);

    // Loyal customer badge
    const totalCheckIns = await CheckIn.countDocuments({ userId });
    await upsertBadgeProgress(userId, 'loyal_customer', totalCheckIns, results);

    // Trendsetter badge — reviews with 10+ upvotes
    const viralReviews = await Review.countDocuments({
      userId,
      'upvotes.9': { $exists: true }, // at least 10 upvotes
    });
    await upsertBadgeProgress(userId, 'trendsetter', viralReviews, results);

    // ShopRadar Hero — referrals
    const referralCount = await Referral.countDocuments({
      referrerId: userId,
      status: { $in: ['completed', 'rewarded'] },
    });
    await upsertBadgeProgress(userId, 'shopradar_hero', referralCount, results);

    return results;
  } catch (error) {
    console.error('Badge check error:', error);
    return [];
  }
};

async function upsertBadgeProgress(userId, badgeName, progress, results) {
  const criteria = BADGE_CRITERIA[badgeName];
  const existing = await Badge.findOne({ userId, badgeName });

  if (existing) {
    existing.progress = progress;
    await existing.save();
  } else if (progress >= criteria.target) {
    await Badge.create({
      userId,
      badgeName,
      progress,
      target: criteria.target,
      criteria: criteria.description,
    });
    results.push({ badgeName, newlyEarned: true });
  }
}

// Get my badges
exports.getMyBadges = async (req, res, next) => {
  try {
    const userId = req.user._id;

    // Award any new badges
    const newBadges = await exports.checkAndAwardBadges(userId);

    const earnedBadges = await Badge.find({ userId }).sort({ earnedAt: -1 });

    // Build full badge list with lock/unlock status
    const allBadges = Object.entries(BADGE_CRITERIA).map(([name, criteria]) => {
      const earned = earnedBadges.find(b => b.badgeName === name);
      return {
        badgeName: name,
        description: criteria.description,
        target: criteria.target,
        progress: earned ? earned.progress : 0,
        earned: !!earned,
        earnedAt: earned ? earned.earnedAt : null,
      };
    });

    res.json({
      success: true,
      data: allBadges,
      newBadges,
      totalEarned: earnedBadges.length,
    });
  } catch (error) {
    next(error);
  }
};

// Get leaderboard
exports.getLeaderboard = async (req, res, next) => {
  try {
    // Top users by badge count
    const leaders = await Badge.aggregate([
      { $group: { _id: '$userId', badgeCount: { $sum: 1 } } },
      { $sort: { badgeCount: -1 } },
      { $limit: 20 },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'user',
        },
      },
      { $unwind: '$user' },
      {
        $project: {
          _id: 1,
          badgeCount: 1,
          'user.name': 1,
          'user.avatar': 1,
          'user.totalCheckIns': 1,
          'user.totalReviews': 1,
          'user.totalOrders': 1,
        },
      },
    ]);

    res.json({ success: true, data: leaders });
  } catch (error) {
    next(error);
  }
};
