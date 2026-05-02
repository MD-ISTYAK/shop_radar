const mongoose = require('mongoose');
const Post = require('../models/Post');
const User = require('../models/User');
const Report = require('../models/Report');
const ModerationLog = require('../models/ModerationLog');
const BlockedHash = require('../models/BlockedHash');
const Comment = require('../models/Comment');
const Like = require('../models/Like');
const Feed = require('../models/Feed');
const Notification = require('../models/Notification');
const { cloudinary } = require('../config/cloudinary');
const moderationService = require('../services/moderationService');
const logger = require('../config/logger');

// ===================== DASHBOARD =====================

// @desc    Get moderation dashboard stats
// @route   GET /api/moderation/dashboard
const getModerationDashboard = async (req, res, next) => {
  try {
    const [
      pendingReports,
      autoHiddenCount,
      totalStrikesToday,
      totalBannedUsers,
      recentLogs,
    ] = await Promise.all([
      Report.countDocuments({ status: 'pending' }),
      Post.countDocuments({ moderationStatus: 'auto_hidden' }),
      ModerationLog.countDocuments({
        action: 'strike_added',
        createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      }),
      User.countDocuments({ isBanned: true }),
      ModerationLog.find()
        .sort({ createdAt: -1 })
        .limit(10)
        .populate('adminId', 'name username')
        .lean(),
    ]);

    res.status(200).json({
      success: true,
      data: {
        pendingReports,
        autoHiddenCount,
        totalStrikesToday,
        totalBannedUsers,
        recentLogs,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ===================== REPORTED CONTENT =====================

// @desc    Get reported videos/posts (paginated, aggregated)
// @route   GET /api/moderation/reports?page=&limit=&status=
const getReportedVideos = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status = 'pending' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Aggregate reports by target, counting reports per target
    const pipeline = [
      { $match: { status } },
      {
        $group: {
          _id: { targetId: '$targetId', targetType: '$targetType' },
          reportCount: { $sum: 1 },
          reasons: { $push: '$reason' },
          latestReport: { $max: '$createdAt' },
          reports: {
            $push: {
              _id: '$_id',
              reporterId: '$reporterId',
              reason: '$reason',
              description: '$description',
              createdAt: '$createdAt',
            },
          },
        },
      },
      { $sort: { reportCount: -1, latestReport: -1 } },
      { $skip: skip },
      { $limit: parseInt(limit) },
    ];

    const aggregated = await Report.aggregate(pipeline);

    // Enrich with post/user data
    const enriched = await Promise.all(
      aggregated.map(async (item) => {
        const targetId = item._id.targetId;
        const targetType = item._id.targetType;

        let target = null;
        if (['post', 'reel'].includes(targetType)) {
          target = await Post.findById(targetId)
            .select('caption videoUrl thumbnailUrl media type moderationStatus visibilityScore distributionLevel reportCount userId')
            .populate('userId', 'name username avatar trustScore strikeCount')
            .lean();
        } else if (targetType === 'user') {
          target = await User.findById(targetId)
            .select('name username avatar trustScore strikeCount isBanned')
            .lean();
        }

        // Reason breakdown
        const reasonBreakdown = {};
        item.reasons.forEach((r) => {
          reasonBreakdown[r] = (reasonBreakdown[r] || 0) + 1;
        });

        return {
          targetId,
          targetType,
          reportCount: item.reportCount,
          reasonBreakdown,
          latestReport: item.latestReport,
          target,
          reports: item.reports.slice(0, 5), // Limit to 5 individual reports
        };
      })
    );

    const totalGroups = await Report.aggregate([
      { $match: { status } },
      { $group: { _id: { targetId: '$targetId', targetType: '$targetType' } } },
      { $count: 'total' },
    ]);

    res.status(200).json({
      success: true,
      count: enriched.length,
      total: totalGroups[0]?.total || 0,
      data: enriched,
    });
  } catch (error) {
    next(error);
  }
};

// ===================== VIDEO MODERATION =====================

// @desc    Get detailed moderation info for a specific video
// @route   GET /api/moderation/videos/:id
const getVideoModerationDetails = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('userId', 'name username avatar trustScore strikeCount isBanned createdAt')
      .lean();

    if (!post) {
      return res.status(404).json({ success: false, message: 'Video not found' });
    }

    const reports = await Report.find({
      targetId: req.params.id,
      targetType: { $in: ['post', 'reel'] },
    })
      .populate('reporterId', 'name username')
      .sort({ createdAt: -1 })
      .lean();

    const moderationLogs = await ModerationLog.find({ videoId: req.params.id })
      .populate('adminId', 'name username')
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      success: true,
      data: {
        video: post,
        reports,
        moderationLogs,
        hashInfo: {
          videoHash: post.videoHash || '',
          audioFingerprint: post.audioFingerprint || '',
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Approve a video — restore visibility
// @route   POST /api/moderation/videos/:id/approve
const approveVideo = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Video not found' });
    }

    const previousStatus = post.moderationStatus;

    post.moderationStatus = 'approved';
    post.distributionLevel = 'standard';
    post.visibilityScore = Math.max(50, post.visibilityScore || 10);
    post.isHidden = false;
    await post.save();

    // Dismiss all pending reports for this video
    await Report.updateMany(
      { targetId: post._id, status: 'pending' },
      { status: 'dismissed', adminNote: 'Content approved by admin', actionTaken: 'none' }
    );

    // Log the action
    await ModerationLog.create({
      adminId: req.user._id,
      videoId: post._id,
      targetUserId: post.userId,
      action: 'approved',
      reason: req.body.reason || 'Content reviewed and approved',
      previousStatus,
      newStatus: 'approved',
    });

    logger.info(`Video ${post._id} approved by admin ${req.user._id}`);

    res.status(200).json({
      success: true,
      message: 'Video approved and visibility restored',
      data: post,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a video — remove from storage, strike user
// @route   POST /api/moderation/videos/:id/delete
const deleteVideo = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Video not found' });
    }

    const { reason } = req.body;
    const previousStatus = post.moderationStatus;

    // 1. Add hashes to blocklist before deletion
    if (post.videoHash) {
      await moderationService.addToBlocklist(
        post.videoHash, 'video', reason || 'Admin deleted', req.user._id, post._id
      );
    }
    if (post.audioFingerprint) {
      await moderationService.addToBlocklist(
        post.audioFingerprint, 'audio', reason || 'Admin deleted', req.user._id, post._id
      );
    }

    // 2. Try to delete from Cloudinary
    try {
      if (post.videoUrl && post.videoUrl.includes('cloudinary')) {
        // Extract public ID from Cloudinary URL
        const urlParts = post.videoUrl.split('/upload/');
        if (urlParts[1]) {
          let publicId = urlParts[1];
          // Remove transformation parameters
          const versionMatch = publicId.match(/(v\d+\/.*)/);
          if (versionMatch) publicId = versionMatch[1];
          // Remove extension
          const extIdx = publicId.lastIndexOf('.');
          if (extIdx !== -1) publicId = publicId.substring(0, extIdx);
          
          await cloudinary.uploader.destroy(publicId, { resource_type: 'video' });
        }
      }
    } catch (cloudErr) {
      logger.warn(`Failed to delete from Cloudinary: ${cloudErr.message}`);
    }

    // 3. Apply strike to user
    const strikeResult = await moderationService.applyStrike(
      post.userId, reason || 'Content policy violation'
    );

    // 4. Mark reports as actioned
    await Report.updateMany(
      { targetId: post._id, status: { $in: ['pending', 'reviewed'] } },
      { status: 'actioned', actionTaken: 'content_deleted', adminNote: reason || 'Deleted by admin' }
    );

    // 5. Clean up associated data
    await Comment.deleteMany({ postId: post._id });
    await Like.deleteMany({ postId: post._id });
    await Feed.deleteMany({ postId: post._id });
    await Notification.deleteMany({ postId: post._id });

    // 6. Log the action
    await ModerationLog.create({
      adminId: req.user._id,
      videoId: post._id,
      targetUserId: post.userId,
      action: 'deleted',
      reason: reason || 'Content policy violation',
      previousStatus,
      newStatus: 'deleted',
      metadata: { strikeCount: strikeResult.strikeCount, userBanned: strikeResult.banned },
    });

    // 7. If user is now banned, log that too
    if (strikeResult.banned) {
      await ModerationLog.create({
        adminId: req.user._id,
        targetUserId: post.userId,
        action: 'user_banned',
        reason: `Auto-banned after ${strikeResult.strikeCount} strikes`,
      });

      // Hide all content from banned user
      await Post.updateMany(
        { userId: post.userId },
        { isHidden: true, moderationStatus: 'rejected', distributionLevel: 'hidden' }
      );
    }

    // 8. Delete the post
    await Post.findByIdAndDelete(post._id);

    logger.warn(`Video ${post._id} deleted by admin ${req.user._id}. User strike: ${strikeResult.strikeCount}`);

    res.status(200).json({
      success: true,
      message: 'Video permanently deleted',
      data: {
        strikeCount: strikeResult.strikeCount,
        userBanned: strikeResult.banned,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ===================== USER MODERATION =====================

// @desc    Get user moderation profile
// @route   GET /api/moderation/users/:id
const getUserModerationProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id)
      .select('name username email avatar trustScore strikeCount isBanned banReason uploadCooldownUntil createdAt')
      .lean();

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Get report stats
    const [reportsAgainst, reportsBy, postCount, hiddenPosts] = await Promise.all([
      Report.countDocuments({ targetType: { $in: ['post', 'reel'] }, targetId: { $in: await Post.find({ userId: req.params.id }).distinct('_id') } }),
      Report.countDocuments({ reporterId: req.params.id }),
      Post.countDocuments({ userId: req.params.id }),
      Post.countDocuments({ userId: req.params.id, isHidden: true }),
    ]);

    // Recent moderation actions on this user
    const recentActions = await ModerationLog.find({ targetUserId: req.params.id })
      .populate('adminId', 'name username')
      .sort({ createdAt: -1 })
      .limit(20)
      .lean();

    res.status(200).json({
      success: true,
      data: {
        user,
        stats: {
          reportsAgainst,
          reportsBy,
          totalPosts: postCount,
          hiddenPosts,
        },
        recentActions,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Ban or unban a user
// @route   POST /api/moderation/users/:id/ban
const toggleBanUser = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (user.role === 'admin') {
      return res.status(403).json({ success: false, message: 'Cannot ban admin users' });
    }

    const wasBanned = user.isBanned;
    user.isBanned = !wasBanned;
    user.banReason = wasBanned ? '' : (req.body.reason || 'Banned by admin');

    if (!wasBanned) {
      // Banning — hide all their content
      await Post.updateMany(
        { userId: user._id },
        { isHidden: true, moderationStatus: 'rejected', distributionLevel: 'hidden' }
      );
      user.trustScore = 0;
    }

    await user.save();

    await ModerationLog.create({
      adminId: req.user._id,
      targetUserId: user._id,
      action: wasBanned ? 'user_unbanned' : 'user_banned',
      reason: req.body.reason || (wasBanned ? 'Unbanned by admin' : 'Banned by admin'),
    });

    res.status(200).json({
      success: true,
      message: wasBanned ? 'User unbanned' : 'User banned',
      data: { isBanned: user.isBanned },
    });
  } catch (error) {
    next(error);
  }
};

// ===================== MODERATION LOGS =====================

// @desc    Get moderation logs (paginated audit trail)
// @route   GET /api/moderation/logs?page=&limit=&action=
const getModerationLogs = async (req, res, next) => {
  try {
    const { page = 1, limit = 30, action } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const query = {};
    if (action) query.action = action;

    const [logs, total] = await Promise.all([
      ModerationLog.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .populate('adminId', 'name username')
        .populate('targetUserId', 'name username')
        .lean(),
      ModerationLog.countDocuments(query),
    ]);

    res.status(200).json({
      success: true,
      count: logs.length,
      total,
      data: logs,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getModerationDashboard,
  getReportedVideos,
  getVideoModerationDetails,
  approveVideo,
  deleteVideo,
  getUserModerationProfile,
  toggleBanUser,
  getModerationLogs,
};
