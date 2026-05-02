const fetch = require('node-fetch');
const crypto = require('crypto');
const Post = require('../models/Post');
const User = require('../models/User');
const BlockedHash = require('../models/BlockedHash');
const Report = require('../models/Report');
const logger = require('../config/logger');

// ── Constants ──
const REPORT_AUTO_HIDE_THRESHOLD = 3;
const DUPLICATE_SIMILARITY_THRESHOLD = 0.90;
const MAX_STRIKES_BEFORE_BAN = 5;
const HASH_FRAME_COUNT = 4; // Number of frames to sample from video

// ── Trust Score Adjustments ──
const TRUST_ADJUSTMENTS = {
  clean_upload: +2,
  report_received: -5,
  content_removed: -15,
  account_age_bonus: +1,
  clean_streak_bonus: +3,
  false_report_penalty: -3,
};

/**
 * Generate a perceptual hash for a video using Cloudinary frame extraction.
 * Extracts N frames at different timestamps, downloads them, and creates
 * a composite hash using pixel averaging.
 *
 * @param {string} cloudinaryUrl - The Cloudinary video URL
 * @returns {Promise<string>} - Composite hash string
 */
const generateVideoHash = async (cloudinaryUrl) => {
  try {
    if (!cloudinaryUrl || !cloudinaryUrl.includes('cloudinary')) {
      return '';
    }

    const uploadIndex = cloudinaryUrl.indexOf('/upload/');
    if (uploadIndex === -1) return '';

    const prefix = cloudinaryUrl.substring(0, uploadIndex + 8);
    let suffix = cloudinaryUrl.substring(uploadIndex + 8);

    // Remove any existing transformations from suffix
    // Cloudinary URLs may already have transformations like f_auto,q_auto
    const versionMatch = suffix.match(/^v\d+\//);
    if (!versionMatch) {
      // If there are transformations before the version, strip them
      const parts = suffix.split('/');
      // Find the part that starts with 'v' followed by digits (version)
      const versionIdx = parts.findIndex(p => /^v\d+$/.test(p));
      if (versionIdx > 0) {
        suffix = parts.slice(versionIdx).join('/');
      }
    }

    // Frame positions as percentages of video duration
    const framePositions = ['1', '25p', '50p', '75p'];
    const hashParts = [];

    for (const pos of framePositions) {
      // Generate thumbnail URL using Cloudinary transformation
      // so_<offset> sets the start offset, w_16,h_16 for a tiny image for hashing
      let thumbSuffix = suffix;
      const extIdx = thumbSuffix.lastIndexOf('.');
      if (extIdx !== -1) {
        thumbSuffix = thumbSuffix.substring(0, extIdx) + '.jpg';
      }

      const frameUrl = `${prefix}so_${pos},w_16,h_16,c_fill,f_jpg,q_low/${thumbSuffix}`;

      try {
        const response = await fetch(frameUrl, { timeout: 10000 });
        if (!response.ok) continue;

        const buffer = await response.buffer();
        // Create a simple hash from the raw pixel data
        const hash = crypto.createHash('md5').update(buffer).digest('hex');
        hashParts.push(hash);
      } catch (frameErr) {
        logger.warn(`Failed to fetch frame at ${pos}: ${frameErr.message}`);
        continue;
      }
    }

    if (hashParts.length === 0) return '';

    // Composite hash: concatenate frame hashes
    return hashParts.join(':');
  } catch (error) {
    logger.error(`generateVideoHash error: ${error.message}`);
    return '';
  }
};

/**
 * Generate a lightweight audio fingerprint from video.
 * Uses Cloudinary to extract audio, then hashes the waveform.
 *
 * @param {string} cloudinaryUrl - The Cloudinary video URL
 * @returns {Promise<string>} - Audio fingerprint string
 */
const generateAudioFingerprint = async (cloudinaryUrl) => {
  try {
    if (!cloudinaryUrl || !cloudinaryUrl.includes('cloudinary')) {
      return '';
    }

    const uploadIndex = cloudinaryUrl.indexOf('/upload/');
    if (uploadIndex === -1) return '';

    const prefix = cloudinaryUrl.substring(0, uploadIndex + 8);
    let suffix = cloudinaryUrl.substring(uploadIndex + 8);

    // Extract audio waveform image using Cloudinary
    // fl_waveform creates a visual representation of the audio
    let audioSuffix = suffix;
    const extIdx = audioSuffix.lastIndexOf('.');
    if (extIdx !== -1) {
      audioSuffix = audioSuffix.substring(0, extIdx) + '.png';
    }

    const waveformUrl = `${prefix}fl_waveform,co_black,b_white,w_200,h_50/${audioSuffix}`;

    try {
      const response = await fetch(waveformUrl, { timeout: 15000 });
      if (!response.ok) return '';

      const buffer = await response.buffer();
      return crypto.createHash('sha256').update(buffer).digest('hex');
    } catch (fetchErr) {
      logger.warn(`Audio fingerprint fetch error: ${fetchErr.message}`);
      return '';
    }
  } catch (error) {
    logger.error(`generateAudioFingerprint error: ${error.message}`);
    return '';
  }
};

/**
 * Calculate Hamming distance between two composite hashes.
 * Each hash is a colon-separated list of MD5 frame hashes.
 *
 * @param {string} hash1
 * @param {string} hash2
 * @returns {number} - Similarity score between 0 and 1
 */
const calculateHashSimilarity = (hash1, hash2) => {
  if (!hash1 || !hash2) return 0;

  const parts1 = hash1.split(':');
  const parts2 = hash2.split(':');

  if (parts1.length === 0 || parts2.length === 0) return 0;

  // Compare matching frame positions
  const minLen = Math.min(parts1.length, parts2.length);
  let matches = 0;

  for (let i = 0; i < minLen; i++) {
    if (parts1[i] === parts2[i]) {
      matches++;
    }
  }

  return matches / Math.max(parts1.length, parts2.length);
};

/**
 * Check if a video hash is a duplicate of any existing video.
 *
 * @param {string} hash - The video hash to check
 * @param {string} [excludePostId] - Post ID to exclude from comparison
 * @returns {Promise<{isDuplicate: boolean, matchedPostId: string|null, similarity: number}>}
 */
const checkDuplicate = async (hash, excludePostId = null) => {
  try {
    if (!hash) return { isDuplicate: false, matchedPostId: null, similarity: 0 };

    const query = { videoHash: { $ne: '' }, type: 'reel' };
    if (excludePostId) {
      query._id = { $ne: excludePostId };
    }

    // Fetch existing video hashes (limit to recent 500 for performance)
    const existingPosts = await Post.find(query)
      .select('videoHash')
      .sort({ createdAt: -1 })
      .limit(500)
      .lean();

    for (const post of existingPosts) {
      const similarity = calculateHashSimilarity(hash, post.videoHash);
      if (similarity >= DUPLICATE_SIMILARITY_THRESHOLD) {
        return {
          isDuplicate: true,
          matchedPostId: post._id.toString(),
          similarity,
        };
      }
    }

    return { isDuplicate: false, matchedPostId: null, similarity: 0 };
  } catch (error) {
    logger.error(`checkDuplicate error: ${error.message}`);
    return { isDuplicate: false, matchedPostId: null, similarity: 0 };
  }
};

/**
 * Check if a hash or audio fingerprint is in the blocked list.
 *
 * @param {string} videoHash
 * @param {string} audioFp
 * @returns {Promise<{isBlocked: boolean, reason: string, hashType: string}>}
 */
const checkBlockedHash = async (videoHash, audioFp) => {
  try {
    const conditions = [];
    if (videoHash) conditions.push({ hash: videoHash, hashType: 'video' });
    if (audioFp) conditions.push({ hash: audioFp, hashType: 'audio' });

    if (conditions.length === 0) return { isBlocked: false, reason: '', hashType: '' };

    // For video hashes (composite), check each frame hash individually
    if (videoHash) {
      const frameParts = videoHash.split(':');
      for (const part of frameParts) {
        conditions.push({ hash: { $regex: part }, hashType: 'video' });
      }
    }

    const blocked = await BlockedHash.findOne({ $or: conditions });
    if (blocked) {
      return {
        isBlocked: true,
        reason: blocked.reason || 'Content matches blocked hash',
        hashType: blocked.hashType,
      };
    }

    return { isBlocked: false, reason: '', hashType: '' };
  } catch (error) {
    logger.error(`checkBlockedHash error: ${error.message}`);
    return { isBlocked: false, reason: '', hashType: '' };
  }
};

/**
 * Calculate initial visibility score based on user trust score.
 *
 * @param {number} trustScore - User's trust score (0-100)
 * @returns {number} - Visibility percentage (5-50)
 */
const calculateInitialVisibility = (trustScore) => {
  if (trustScore <= 30) return 5;
  if (trustScore <= 60) return 10;
  if (trustScore <= 80) return 25;
  return 50;
};

/**
 * Auto-moderate a post based on report count.
 * If reports exceed threshold, auto-hide and reduce author's trust.
 *
 * @param {string} postId
 * @returns {Promise<{action: string, hidden: boolean}>}
 */
const autoModerate = async (postId) => {
  try {
    const post = await Post.findById(postId);
    if (!post) return { action: 'none', hidden: false };

    // Count total reports
    const reportCount = await Report.countDocuments({
      targetId: postId,
      targetType: { $in: ['post', 'reel'] },
    });

    post.reportCount = reportCount;

    if (reportCount >= REPORT_AUTO_HIDE_THRESHOLD) {
      post.isHidden = true;
      post.moderationStatus = 'auto_hidden';
      post.distributionLevel = 'hidden';
      await post.save();

      // Decrease author trust score
      if (post.userId) {
        await updateTrustScore(post.userId, 'report_received');
      }

      logger.info(`Auto-hidden post ${postId} with ${reportCount} reports`);
      return { action: 'auto_hidden', hidden: true };
    }

    await post.save();
    return { action: 'report_added', hidden: false };
  } catch (error) {
    logger.error(`autoModerate error: ${error.message}`);
    return { action: 'error', hidden: false };
  }
};

/**
 * Update a user's trust score based on an event.
 *
 * @param {string} userId
 * @param {string} event - One of: clean_upload, report_received, content_removed, account_age_bonus
 * @returns {Promise<number>} - New trust score
 */
const updateTrustScore = async (userId, event) => {
  try {
    const adjustment = TRUST_ADJUSTMENTS[event] || 0;
    if (adjustment === 0) return -1;

    const user = await User.findById(userId);
    if (!user) return -1;

    user.trustScore = Math.max(0, Math.min(100, (user.trustScore || 50) + adjustment));
    await user.save();

    logger.info(`Trust score updated for user ${userId}: ${event} (${adjustment > 0 ? '+' : ''}${adjustment}) → ${user.trustScore}`);
    return user.trustScore;
  } catch (error) {
    logger.error(`updateTrustScore error: ${error.message}`);
    return -1;
  }
};

/**
 * Check if a user is allowed to upload (not banned, not in cooldown).
 *
 * @param {string} userId
 * @returns {Promise<{allowed: boolean, reason: string}>}
 */
const checkUploadEligibility = async (userId) => {
  try {
    const user = await User.findById(userId);
    if (!user) return { allowed: false, reason: 'User not found' };

    if (user.isBanned) {
      return { allowed: false, reason: `Account banned: ${user.banReason || 'Policy violation'}` };
    }

    if (user.uploadCooldownUntil && new Date(user.uploadCooldownUntil) > new Date()) {
      const remaining = Math.ceil((new Date(user.uploadCooldownUntil) - new Date()) / 60000);
      return { allowed: false, reason: `Upload cooldown active. Try again in ${remaining} minutes.` };
    }

    return { allowed: true, reason: '' };
  } catch (error) {
    logger.error(`checkUploadEligibility error: ${error.message}`);
    return { allowed: true, reason: '' }; // Fail open to not block legitimate uploads
  }
};

/**
 * Apply a strike to a user. If strikes exceed threshold, ban the user.
 *
 * @param {string} userId
 * @param {string} reason
 * @returns {Promise<{strikeCount: number, banned: boolean}>}
 */
const applyStrike = async (userId, reason) => {
  try {
    const user = await User.findById(userId);
    if (!user) return { strikeCount: 0, banned: false };

    user.strikeCount = (user.strikeCount || 0) + 1;

    // Apply cooldown based on strike count
    const cooldownMinutes = user.strikeCount * 60; // 1h, 2h, 3h, etc.
    user.uploadCooldownUntil = new Date(Date.now() + cooldownMinutes * 60 * 1000);

    // Ban if exceeded max strikes
    if (user.strikeCount >= MAX_STRIKES_BEFORE_BAN) {
      user.isBanned = true;
      user.banReason = reason || 'Exceeded maximum content policy violations';
    }

    // Decrease trust score for content removal
    user.trustScore = Math.max(0, (user.trustScore || 50) + TRUST_ADJUSTMENTS.content_removed);

    await user.save();

    logger.warn(`Strike applied to user ${userId}: count=${user.strikeCount}, banned=${user.isBanned}`);
    return { strikeCount: user.strikeCount, banned: user.isBanned };
  } catch (error) {
    logger.error(`applyStrike error: ${error.message}`);
    return { strikeCount: 0, banned: false };
  }
};

/**
 * Add a hash to the blocked list.
 *
 * @param {string} hash
 * @param {string} hashType - 'video' or 'audio'
 * @param {string} reason
 * @param {string} adminId
 * @param {string} sourceVideoId
 */
const addToBlocklist = async (hash, hashType, reason, adminId, sourceVideoId) => {
  try {
    if (!hash) return;

    // For composite video hashes, also block individual frame hashes
    if (hashType === 'video' && hash.includes(':')) {
      const frameParts = hash.split(':');
      // Store the composite hash
      await BlockedHash.findOneAndUpdate(
        { hash, hashType },
        { hash, hashType, reason, addedBy: adminId, sourceVideoId },
        { upsert: true, new: true }
      );
      // Also store each frame hash for partial matching
      for (const part of frameParts) {
        await BlockedHash.findOneAndUpdate(
          { hash: part, hashType },
          { hash: part, hashType, reason: `Frame hash from: ${reason}`, addedBy: adminId, sourceVideoId },
          { upsert: true, new: true }
        );
      }
    } else {
      await BlockedHash.findOneAndUpdate(
        { hash, hashType },
        { hash, hashType, reason, addedBy: adminId, sourceVideoId },
        { upsert: true, new: true }
      );
    }

    logger.info(`Added ${hashType} hash to blocklist: ${hash.substring(0, 20)}...`);
  } catch (error) {
    logger.error(`addToBlocklist error: ${error.message}`);
  }
};

module.exports = {
  generateVideoHash,
  generateAudioFingerprint,
  calculateHashSimilarity,
  checkDuplicate,
  checkBlockedHash,
  calculateInitialVisibility,
  autoModerate,
  updateTrustScore,
  checkUploadEligibility,
  applyStrike,
  addToBlocklist,
  REPORT_AUTO_HIDE_THRESHOLD,
  DUPLICATE_SIMILARITY_THRESHOLD,
  MAX_STRIKES_BEFORE_BAN,
  TRUST_ADJUSTMENTS,
};
