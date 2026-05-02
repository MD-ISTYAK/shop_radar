const Post = require('../models/Post');
const User = require('../models/User');
const Report = require('../models/Report');
const logger = require('../config/logger');
const moderationService = require('./moderationService');

// ── Trust Score Background Jobs ──
// Run periodically to maintain trust scores and promote clean content

/**
 * Daily trust score maintenance job.
 * - Account age bonus for users with no recent reports
 * - Clean upload streak bonus
 * - Promote clean pending content to standard visibility
 * - Auto-escalate high-engagement content
 */
const runTrustScoreJobs = async () => {
  logger.info('🔄 Running trust score maintenance jobs...');

  try {
    // 1. Account age bonus — users with account > 30 days and no reports in last 30 days
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const matureUsers = await User.find({
      createdAt: { $lt: thirtyDaysAgo },
      isBanned: false,
      trustScore: { $lt: 100 },
    }).select('_id').lean();

    for (const user of matureUsers) {
      // Check if user has reports in last 30 days
      const recentReports = await Report.countDocuments({
        targetType: { $in: ['post', 'reel'] },
        targetId: {
          $in: await Post.find({ userId: user._id }).distinct('_id'),
        },
        createdAt: { $gte: thirtyDaysAgo },
      });

      if (recentReports === 0) {
        await moderationService.updateTrustScore(user._id, 'account_age_bonus');
      }
    }

    logger.info(`  ✅ Account age bonus processed for ${matureUsers.length} users`);

    // 2. Clean upload streak — users with 5+ uploads and 0 reports in last 30 days
    const activeUploaders = await Post.aggregate([
      {
        $match: {
          type: 'reel',
          createdAt: { $gte: thirtyDaysAgo },
          reportCount: 0,
        },
      },
      {
        $group: {
          _id: '$userId',
          uploadCount: { $sum: 1 },
        },
      },
      { $match: { uploadCount: { $gte: 5 } } },
    ]);

    for (const uploader of activeUploaders) {
      await moderationService.updateTrustScore(uploader._id, 'clean_streak_bonus');
    }

    logger.info(`  ✅ Clean streak bonus processed for ${activeUploaders.length} users`);

    // 3. Promote clean pending content to standard
    //    Posts that are 24+ hours old, pending, 0 reports → upgrade to standard
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const promotionResult = await Post.updateMany(
      {
        moderationStatus: 'pending',
        reportCount: 0,
        createdAt: { $lt: oneDayAgo },
        distributionLevel: 'limited',
        isHidden: false,
      },
      {
        $set: {
          distributionLevel: 'standard',
          visibilityScore: 50,
        },
      }
    );

    logger.info(`  ✅ Promoted ${promotionResult.modifiedCount} clean posts to standard visibility`);

    // 4. Auto-escalate high-engagement content
    //    Posts with high engagement rate AND 0 reports → boost visibility
    const highEngagement = await Post.find({
      type: 'reel',
      moderationStatus: { $in: ['pending', 'approved'] },
      reportCount: 0,
      distributionLevel: { $in: ['limited', 'standard'] },
      isHidden: false,
      likesCount: { $gte: 10 },
    }).select('_id likesCount viewCount commentsCount').lean();

    for (const post of highEngagement) {
      const engagementRate = ((post.likesCount || 0) + (post.commentsCount || 0)) /
        Math.max(1, post.viewCount || 1);

      if (engagementRate > 0.1) { // >10% engagement rate
        await Post.findByIdAndUpdate(post._id, {
          distributionLevel: 'boosted',
          visibilityScore: 80,
          moderationStatus: 'approved',
        });
      }
    }

    logger.info(`  ✅ Checked ${highEngagement.length} posts for engagement escalation`);

    logger.info('✅ Trust score maintenance jobs completed');
  } catch (error) {
    logger.error(`Trust score job error: ${error.message}`);
  }
};

/**
 * Start the periodic trust score job.
 * Runs every 6 hours.
 */
const startTrustScoreScheduler = () => {
  const SIX_HOURS = 6 * 60 * 60 * 1000;

  // Run once on startup after a delay (30 seconds)
  setTimeout(() => {
    runTrustScoreJobs().catch((err) => logger.error(`Initial trust job failed: ${err.message}`));
  }, 30000);

  // Then run every 6 hours
  setInterval(() => {
    runTrustScoreJobs().catch((err) => logger.error(`Scheduled trust job failed: ${err.message}`));
  }, SIX_HOURS);

  logger.info('📅 Trust score scheduler started (runs every 6 hours)');
};

module.exports = {
  runTrustScoreJobs,
  startTrustScoreScheduler,
};
