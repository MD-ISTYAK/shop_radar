const mongoose = require('mongoose');
const Post = require('../models/Post');
const Story = require('../models/Story');
const Follow = require('../models/Follow');
const User = require('../models/User');
const Shop = require('../models/Shop');
const Notification = require('../models/Notification');

const Feed = require('../models/Feed');
const Like = require('../models/Like');
const Comment = require('../models/Comment');
const { optimizeMediaUrl, getVideoThumbnail } = require('../config/cloudinary');

// ===================== POSTS =====================

// @desc    Create a post (any user or shop owner)
// @route   POST /api/social/posts
const createPost = async (req, res, next) => {
  try {
    const { content, type, caption } = req.body;
    const userId = req.user._id;

    const user = await User.findById(userId);

    const postData = {
      userId,
      ownerId: userId,
      caption: caption || content || '',
      type: type || 'post',
      userSnapshot: {
        username: user.username || user.name,
        avatarUrl: user.profile?.avatarUrl || user.avatar || '',
      },
      media: [],
    };

    // If user is a shop owner, also link the shop
    const shop = await Shop.findOne({ ownerId: userId });
    if (shop) {
      postData.shopId = shop._id;
    }

    // Handle image uploads
    if (req.files && req.files.images) {
      req.files.images.forEach((f) => {
        postData.media.push({
          type: 'image',
          url: optimizeMediaUrl(f.path, 'image'),
        });
      });
    }
    // Handle video upload for reels
    if (req.files && req.files.video && req.files.video[0]) {
      const vUrl = optimizeMediaUrl(req.files.video[0].path, 'video');
      const tUrl = getVideoThumbnail(req.files.video[0].path);
      postData.media.push({
        type: 'video',
        url: vUrl,
        thumbnailUrl: tUrl,
      });
      postData.videoUrl = vUrl;
      postData.thumbnailUrl = tUrl;
      postData.type = 'reel';
    }

    const post = await Post.create(postData);
    
    // Increment User postsCount
    await User.findByIdAndUpdate(userId, { $inc: { 'stats.postsCount': 1 } });

    // Notify followers and Fan-out to Feed
    const followers = await Follow.find({ followingId: userId });
    
    // Add to my own feed
    const feedEntries = [{ userId, postId: post._id }];

    if (followers.length > 0) {
      const displayName = user.username || user.name;
      
      const notifications = [];
      followers.forEach((f) => {
        // Feed Fan-out
        feedEntries.push({ userId: f.followerId, postId: post._id });
        
        // Notifications
        notifications.push({
          userId: f.followerId,
          type: 'new_post',
          title: `${displayName} shared a new ${postData.type}`,
          body: postData.caption ? postData.caption.substring(0, 100) : '',
          actorId: userId,
          postId: post._id,
          data: { postId: post._id, userId },
        });
      });
      
      await Notification.insertMany(notifications);
    }
    
    // Bulk insert into Feed
    await Feed.insertMany(feedEntries);

    // Populate and return
    const populated = await Post.findById(post._id)
      .populate('userId', 'name username profilePic avatar accountType')
      .populate('shopId', 'shopName logo');

    res.status(201).json({ success: true, message: 'Post created', data: populated });
  } catch (error) {
    next(error);
  }
};

// @desc    Cursor-based feed from followed users
// @route   GET /api/social/feed?limit=&cursor=
const getFeed = async (req, res, next) => {
  try {
    const { limit = 10, cursor } = req.query;
    const limitNum = parseInt(limit);
    const userId = req.user._id;

    // Build Feed query
    const feedQuery = { userId };
    
    if (cursor) {
      feedQuery.createdAt = { $lt: new Date(cursor) };
    }

    // Fetch Feed entries (already sorted by latest)
    const feedEntries = await Feed.find(feedQuery)
      .sort({ createdAt: -1 })
      .limit(limitNum)
      .lean();

    if (feedEntries.length === 0) {
      return res.status(200).json({ success: true, count: 0, nextCursor: null, data: [] });
    }

    const postIds = feedEntries.map(f => f.postId);

    // Optimized field selection for minimal payload
    const selectFields = 'caption media userSnapshot likesCount commentsCount createdAt type';

    // Fetch posts associated with those feed entries
    const posts = await Post.find({
      _id: { $in: postIds },
      isHidden: { $ne: true },
    })
      .select(selectFields)
      .lean();

    // Reorder posts to match feedEntries order
    const orderedPosts = feedEntries.map(f => {
      const post = posts.find(p => p._id.toString() === f.postId.toString());
      if (post) {
        post.feedId = f._id; // Add feed ID just in case
      }
      return post;
    }).filter(Boolean);

    // Add isLiked status for current user (Query Like collection)
    const likes = await Like.find({ userId, postId: { $in: postIds } }).lean();
    const likedPostIds = new Set(likes.map(l => l.postId.toString()));
    
    orderedPosts.forEach(post => {
      post.isLiked = likedPostIds.has(post._id.toString());
    });

    const nextCursor = feedEntries.length > 0 ? feedEntries[feedEntries.length - 1].createdAt : null;

    res.status(200).json({
      success: true,
      count: orderedPosts.length,
      nextCursor,
      data: orderedPosts,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Explore / discovery feed (public posts sorted by popularity)
// @route   GET /api/social/explore?page=&limit=
const explorePosts = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const userId = req.user._id;

    // Optimized field selection
    const selectFields = 'userId shopId ownerId content images videoUrl media mediaUrl mediaType type likesCount commentsCount createdAt isHidden';

    const posts = await Post.find({ type: 'post', isHidden: { $ne: true } })
      .sort({ likesCount: -1, createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select(selectFields)
      .populate('userId', 'name username profilePic avatar accountType')
      .populate('shopId', 'shopName logo')
      .populate('ownerId', 'name avatar')
      .lean();

    _addLikeStatus(posts, userId);

    res.status(200).json({ success: true, count: posts.length, data: posts });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle like on a post
// @route   POST /api/social/posts/:id/like
const toggleLike = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    const userId = req.user._id;
    
    // Check Like collection instead of post.likes array
    const existingLike = await Like.findOne({ userId, postId: post._id });

    if (existingLike) {
      await Like.findByIdAndDelete(existingLike._id);
      post.likesCount = Math.max(0, (post.likesCount || 0) - 1);
    } else {
      await Like.create({ userId, postId: post._id });
      post.likesCount = (post.likesCount || 0) + 1;

      // Notify post author (if not self)
      if (post.userId && post.userId.toString() !== userId.toString()) {
        const liker = await User.findById(userId);
        await Notification.create({
          userId: post.userId,
          type: 'like',
          title: 'New Like',
          body: `@${liker.username || liker.name} liked your post`,
          actorId: userId,
          postId: post._id,
          data: { postId: post._id, senderId: userId },
        });
      }
    }
    await post.save();

    res.status(200).json({
      success: true,
      message: existingLike ? 'Unliked' : 'Liked',
      data: { likesCount: post.likesCount, isLiked: !existingLike },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get comments for a post
// @route   GET /api/social/posts/:id/comments
const getPostComments = async (req, res, next) => {
  try {
    const comments = await Comment.find({ postId: req.params.id, isHidden: { $ne: true } })
      .sort({ createdAt: -1 }) // or 1 for chronological
      .lean();

    res.status(200).json({
      success: true,
      count: comments.length,
      data: comments,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add comment to post
// @route   POST /api/social/posts/:id/comment
const addComment = async (req, res, next) => {
  try {
    const { text, parentCommentId } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Comment text is required' });
    }

    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    const user = await User.findById(req.user._id);

    // Create comment in Comment collection
    const comment = await Comment.create({
      postId: post._id,
      userId: req.user._id,
      text: text.trim(),
      parentCommentId: parentCommentId || null,
      userSnapshot: {
        username: user.username || user.name,
        avatarUrl: user.profile?.avatarUrl || user.avatar || '',
      },
    });

    post.commentsCount = (post.commentsCount || 0) + 1;
    await post.save();

    // Notify post author
    if (post.userId && post.userId.toString() !== req.user._id.toString()) {
      await Notification.create({
        userId: post.userId,
        type: 'comment',
        title: 'New Comment',
        body: `@${user.username || user.name} commented: ${text.substring(0, 60)}`,
        actorId: req.user._id,
        postId: post._id,
        data: { postId: post._id, senderId: req.user._id },
      });
    }

    res.status(201).json({
      success: true,
      message: 'Comment added',
      data: comment,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Save / unsave a post
// @route   POST /api/social/posts/:id/save
const savePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    const userId = req.user._id;
    const idx = post.savedBy.findIndex((id) => id.toString() === userId.toString());

    if (idx > -1) {
      post.savedBy.splice(idx, 1);
    } else {
      post.savedBy.push(userId);
    }
    await post.save();

    res.status(200).json({
      success: true,
      message: idx > -1 ? 'Unsaved' : 'Saved',
      data: { isSaved: idx === -1 },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Unsave a post
// @route   DELETE /api/social/posts/:id/save
const unsavePost = async (req, res, next) => {
  try {
    await Post.findByIdAndUpdate(req.params.id, {
      $pull: { savedBy: req.user._id },
    });
    res.status(200).json({ success: true, message: 'Unsaved' });
  } catch (error) {
    next(error);
  }
};

// @desc    Get a user's posts (profile grid)
// @route   GET /api/social/users/:userId/posts?cursor=&limit=
const getUserPosts = async (req, res, next) => {
  try {
    const { cursor, limit = 12 } = req.query;
    const query = {
      $or: [
        { userId: req.params.userId },
        { ownerId: req.params.userId },
      ],
      isHidden: { $ne: true },
    };
    if (cursor) {
      query._id = { $lt: new mongoose.Types.ObjectId(cursor) };
    }

    const posts = await Post.find(query)
      .sort({ _id: -1 })
      .limit(parseInt(limit))
      .populate('userId', 'name username profilePic avatar accountType')
      .lean();

    _addLikeStatus(posts, req.user._id);

    const nextCursor = posts.length > 0 ? posts[posts.length - 1]._id : null;

    res.status(200).json({
      success: true,
      count: posts.length,
      nextCursor,
      data: posts,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update a post
// @route   PUT /api/social/posts/:id
const updatePost = async (req, res, next) => {
  try {
    const { content } = req.body;
    let post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    if (post.ownerId.toString() !== req.user._id.toString() &&
        post.userId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    post = await Post.findByIdAndUpdate(req.params.id, { content }, { new: true, runValidators: true });
    res.status(200).json({ success: true, data: post });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a post
// @route   DELETE /api/social/posts/:id
const deletePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    if (post.ownerId.toString() !== req.user._id.toString() &&
        post.userId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await Post.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: 'Post deleted' });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle hide post
// @route   PATCH /api/social/posts/:id/hide
const toggleHidePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    if (post.ownerId.toString() !== req.user._id.toString() &&
        post.userId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    post.isHidden = !post.isHidden;
    await post.save();
    res.status(200).json({ success: true, message: post.isHidden ? 'Post hidden' : 'Post unhidden', data: post });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a comment
// @route   DELETE /api/social/posts/:postId/comments/:commentId
const deleteComment = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.postId);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    const comment = post.comments.id(req.params.commentId);
    if (!comment) return res.status(404).json({ success: false, message: 'Comment not found' });

    if (post.ownerId.toString() !== req.user._id.toString() && comment.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    comment.deleteOne();
    post.commentsCount = Math.max(0, (post.commentsCount || 1) - 1);
    await post.save();
    res.status(200).json({ success: true, message: 'Comment deleted' });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle hide comment
// @route   PATCH /api/social/posts/:postId/comments/:commentId/hide
const toggleHideComment = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.postId);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    if (post.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Only post owner can hide comments' });
    }

    const comment = post.comments.id(req.params.commentId);
    if (!comment) return res.status(404).json({ success: false, message: 'Comment not found' });

    comment.isHidden = !comment.isHidden;
    await post.save();
    res.status(200).json({ success: true, data: comment });
  } catch (error) {
    next(error);
  }
};

// @desc    Get post likers
// @route   GET /api/social/posts/:id/likes
const getPostLikes = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id).populate('likes', 'name username profilePic avatar');
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });
    res.status(200).json({ success: true, count: post.likes.length, data: post.likes });
  } catch (error) {
    next(error);
  }
};

// @desc    Get my posts
// @route   GET /api/social/my-posts
const getMyPosts = async (req, res, next) => {
  try {
    const posts = await Post.find({
      $or: [{ userId: req.user._id }, { ownerId: req.user._id }],
    })
      .sort({ createdAt: -1 })
      .populate('comments.userId', 'name username profilePic avatar')
      .lean();

    _addLikeStatus(posts, req.user._id);
    res.status(200).json({ success: true, count: posts.length, data: posts });
  } catch (error) {
    next(error);
  }
};

// ===================== STORIES =====================

// @desc    Create a story
// @route   POST /api/social/stories
const createStory = async (req, res, next) => {
  try {
    const userId = req.user._id;

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Media is required for stories' });
    }

    const storyData = {
      userId,
      ownerId: userId,
      mediaUrl: req.file.path,
      imageUrl: req.file.path, // backward compat
      mediaType: req.file.mimetype?.startsWith('video') ? 'video' : 'image',
      caption: req.body.caption || '',
    };

    // If shop owner, also link the shop
    const shop = await Shop.findOne({ ownerId: userId });
    if (shop) {
      storyData.shopId = shop._id;
    }

    const story = await Story.create(storyData);
    res.status(201).json({ success: true, message: 'Story created', data: story });
  } catch (error) {
    next(error);
  }
};

// @desc    Get stories feed (grouped by user)
// @route   GET /api/social/stories
const getStories = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const follows = await Follow.find({ followerId: userId }).lean();
    const followingIds = follows.map((f) => f.followingId);
    const shopIds = follows.filter((f) => f.shopId).map((f) => f.shopId);

    const stories = await Story.find({
      $or: [
        { userId: userId },      // include my own stories
        { ownerId: userId },     // include my own stories (backward compat)
        { userId: { $in: followingIds } },
        { ownerId: { $in: followingIds } },
        { shopId: { $in: shopIds } },
      ],
      expiresAt: { $gt: new Date() },
      isHidden: { $ne: true },
    })
      .sort({ createdAt: 1 })
      .populate('userId', 'name username profilePic avatar accountType')
      .populate('shopId', 'shopName logo')
      .lean();

    // Group by user
    const grouped = {};
    stories.forEach((story) => {
      const key = story.userId?._id?.toString() || story.ownerId?.toString() || story.shopId?._id?.toString();
      if (!key) return;
      if (!grouped[key]) {
        const user = story.userId || {};
        const shop = story.shopId || {};
        grouped[key] = {
          user: {
            _id: key,
            username: user.username || user.name || shop.shopName || '',
            profilePic: user.profilePic || user.avatar || shop.logo || '',
            accountType: user.accountType || 'user',
          },
          // Backward compat
          shop: story.shopId || { _id: key, shopName: user.name || '', logo: user.avatar || '' },
          stories: [],
          hasUnseen: false,
        };
      }
      // Check if current user has viewed this story
      const viewed = (story.viewers || []).some((v) => v.toString() === userId.toString());
      if (!viewed) grouped[key].hasUnseen = true;
      grouped[key].stories.push(story);
    });

    // Sort: unseen groups first
    const result = Object.values(grouped).sort((a, b) => (b.hasUnseen ? 1 : 0) - (a.hasUnseen ? 1 : 0));

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark story as viewed
// @route   POST /api/social/stories/:id/view
const markStoryViewed = async (req, res, next) => {
  try {
    await Story.findByIdAndUpdate(req.params.id, {
      $addToSet: { viewers: req.user._id },
    });
    res.status(200).json({ success: true, message: 'Story viewed' });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a story
const deleteStory = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id);
    if (!story) return res.status(404).json({ success: false, message: 'Story not found' });

    if (story.ownerId?.toString() !== req.user._id.toString() &&
        story.userId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await Story.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: 'Story deleted' });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle hide story
const toggleHideStory = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id);
    if (!story) return res.status(404).json({ success: false, message: 'Story not found' });

    if (story.ownerId?.toString() !== req.user._id.toString() &&
        story.userId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    story.isHidden = !story.isHidden;
    await story.save();
    res.status(200).json({ success: true, data: story });
  } catch (error) {
    next(error);
  }
};

// @desc    Get my active stories
const getMyStories = async (req, res, next) => {
  try {
    const stories = await Story.find({
      $or: [{ userId: req.user._id }, { ownerId: req.user._id }],
    }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: stories.length, data: stories });
  } catch (error) {
    next(error);
  }
};

// ===================== REELS =====================

// @desc    Get reels feed (followed users first, then trending)
// @route   GET /api/social/reels?page=&limit=
const getReels = async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const userId = req.user._id;

    // Optimized field selection
    const selectFields = 'userId shopId ownerId content caption videoUrl media mediaUrl thumbnailUrl mediaType type likesCount commentsCount createdAt duration isHidden';

    const reels = await Post.find({
      type: 'reel',
      $or: [
        { videoUrl: { $ne: '' } },
        { 'media.type': 'video' }
      ],
      isHidden: { $ne: true },
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select(selectFields)
      .populate('userId', 'name username profilePic avatar accountType')
      .populate('shopId', 'shopName logo')
      .lean();

    _addLikeStatus(reels, userId);

    res.status(200).json({ success: true, count: reels.length, data: reels });
  } catch (error) {
    next(error);
  }
};

// @desc    Like a reel
// @route   POST /api/social/reels/:id/like
const likeReel = async (req, res, next) => {
  // Reels are stored as Posts with type='reel', so reuse toggleLike
  req.params.id = req.params.id;
  return toggleLike(req, res, next);
};

// ===================== FOLLOW SYSTEM =====================

// @desc    Follow / unfollow a user (toggle)
// @route   POST /api/social/follow/:userId
const toggleFollow = async (req, res, next) => {
  try {
    const followerId = req.user._id;
    let followingId = req.params.userId;

    if (!followingId) {
      return res.status(400).json({ success: false, message: 'Target ID is required' });
    }

    // Check if followingId is actually a shopId
    const shopByShopId = await Shop.findById(followingId);
    if (shopByShopId) {
      followingId = shopByShopId.ownerId;
    }

    if (followerId.toString() === followingId.toString()) {
      return res.status(400).json({ success: false, message: 'Cannot follow yourself' });
    }

    const existing = await Follow.findOne({ followerId, followingId });

    if (existing) {
      // Unfollow
      await Follow.findByIdAndDelete(existing._id);
      // Atomic decrement
      await User.findByIdAndUpdate(followingId, { $inc: { 'stats.followersCount': -1, followersCount: -1 } });
      await User.findByIdAndUpdate(followerId, { $inc: { 'stats.followingCount': -1, followingCount: -1 } });
      
      // Optional: Clean up Feed entries (remove unfollowed user's posts from feed)
      // This might be heavy, so we can do it asynchronously or limit it.
      // But for strict clean feed, we should remove them.
      const userPosts = await Post.find({ userId: followingId }).select('_id').lean();
      const postIds = userPosts.map(p => p._id);
      if (postIds.length > 0) {
        await Feed.deleteMany({ userId: followerId, postId: { $in: postIds } });
      }

      return res.status(200).json({ success: true, message: 'Unfollowed', data: { isFollowing: false } });
    }

    // Follow
    const followData = { followerId, followingId };

    // Backward compat: Store shopId if the target is a shop owner
    const targetShop = await Shop.findOne({ ownerId: followingId });
    if (targetShop) {
      followData.shopId = targetShop._id;
    }

    await Follow.create(followData);
    // Atomic increment
    await User.findByIdAndUpdate(followingId, { $inc: { 'stats.followersCount': 1, followersCount: 1 } });
    await User.findByIdAndUpdate(followerId, { $inc: { 'stats.followingCount': 1, followingCount: 1 } });

    // Fan-out recent posts into the new follower's Feed
    const recentPosts = await Post.find({ userId: followingId, isHidden: { $ne: true } })
      .sort({ createdAt: -1 })
      .limit(20)
      .select('_id')
      .lean();
      
    if (recentPosts.length > 0) {
      const feedEntries = recentPosts.map(p => ({
        userId: followerId,
        postId: p._id,
      }));
      await Feed.insertMany(feedEntries);
    }

    // Notify
    const follower = await User.findById(followerId);
    await Notification.create({
      userId: followingId,
      type: 'follow',
      title: 'New Follower',
      body: `@${follower.username || follower.name} started following you`,
      actorId: followerId,
      data: { senderId: followerId },
    });

    res.status(201).json({ success: true, message: 'Followed', data: { isFollowing: true } });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: 'Already following' });
    }
    next(error);
  }
};

// @desc    Unfollow a user explicitly
// @route   DELETE /api/social/unfollow/:userId
const unfollowUser = async (req, res, next) => {
  try {
    const followerId = req.user._id;
    const followingId = req.params.userId;

    const existing = await Follow.findOneAndDelete({ followerId, followingId });
    if (existing) {
      await User.updateOne({ _id: followingId }, { $inc: { 'stats.followersCount': -1, followersCount: -1 } });
      await User.updateOne({ _id: followerId }, { $inc: { 'stats.followingCount': -1, followingCount: -1 } });
      
      const userPosts = await Post.find({ userId: followingId }).select('_id').lean();
      const postIds = userPosts.map(p => p._id);
      if (postIds.length > 0) {
        await Feed.deleteMany({ userId: followerId, postId: { $in: postIds } });
      }
    }

    res.status(200).json({ success: true, message: 'Unfollowed', data: { isFollowing: false } });
  } catch (error) {
    next(error);
  }
};

// @desc    Check follow status
// @route   GET /api/social/follow/:userId/check
const checkFollow = async (req, res, next) => {
  try {
    const existing = await Follow.findOne({
      followerId: req.user._id,
      $or: [
        { followingId: req.params.userId },
        { shopId: req.params.userId },
      ],
    });
    res.status(200).json({ success: true, data: { isFollowing: !!existing } });
  } catch (error) {
    next(error);
  }
};

// @desc    Get followers count
// @route   GET /api/social/follow/:userId/count
const getFollowersCount = async (req, res, next) => {
  try {
    const count = await Follow.countDocuments({
      $or: [
        { followingId: req.params.userId },
        { shopId: req.params.userId },
      ],
    });
    res.status(200).json({ success: true, data: { count } });
  } catch (error) {
    next(error);
  }
};

// @desc    Get followers list (paginated)
// @route   GET /api/social/followers/:userId?page=
const getFollowers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const follows = await Follow.find({ followingId: req.params.userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('followerId', 'name username profilePic avatar accountType');

    const users = follows.filter((f) => f.followerId).map((f) => f.followerId);
    res.status(200).json({ success: true, count: users.length, data: users });
  } catch (error) {
    next(error);
  }
};

// @desc    Get following list (paginated)
// @route   GET /api/social/following/:userId?page=
const getFollowing = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const follows = await Follow.find({ followerId: req.params.userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('followingId', 'name username profilePic avatar accountType');

    const users = follows.filter((f) => f.followingId).map((f) => f.followingId);
    res.status(200).json({ success: true, count: users.length, data: users });
  } catch (error) {
    next(error);
  }
};

// @desc    Get shops the current user follows (backward compat)
// @route   GET /api/social/follow/my-follows
const getMyFollowedShops = async (req, res, next) => {
  try {
    const follows = await Follow.find({
      followerId: req.user._id,
      shopId: { $ne: null },
    }).populate('shopId', 'shopName logo category address status rating openingTime closingTime phone');

    const shops = follows.filter((f) => f.shopId != null).map((f) => f.shopId);
    res.status(200).json({ success: true, count: shops.length, data: shops });
  } catch (error) {
    next(error);
  }
};

// ===================== USER PROFILE =====================

// @desc    Get user profile
// @route   GET /api/users/:userId
const getUserProfile = async (req, res, next) => {
  try {
    const { userId } = req.params;
    console.log(`[SOCIAL] Fetching profile for userId: ${userId}`);

    // Validate ObjectID to prevent crash
    if (!userId.match(/^[0-9a-fA-F]{24}$/)) {
      console.log(`[SOCIAL] Invalid User ID format: ${userId}`);
      return res.status(400).json({ success: false, message: 'Invalid User ID format' });
    }

    const user = await User.findById(userId).select('-password');
    if (!user) {
      console.log(`[SOCIAL] User not found: ${userId}`);
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    console.log(`[SOCIAL] Profile found for: ${user.name} (@${user.username})`);

    // Count posts
    const postsCount = await Post.countDocuments({
      $or: [{ userId: user._id }, { ownerId: user._id }],
      isHidden: { $ne: true },
    });

    // Check if current user follows this user
    let isFollowing = false;
    if (req.user && req.user._id.toString() !== user._id.toString()) {
      const follow = await Follow.findOne({ followerId: req.user._id, followingId: user._id });
      isFollowing = !!follow;
    }

    const profileData = {
      _id: user._id,
      name: user.name,
      username: user.username || (user.name ? user.name.toLowerCase().replace(/\s+/g, '') : 'user'),
      email: user.email,
      profilePic: user.profilePic || user.avatar || '',
      avatar: user.avatar || '',
      bio: user.bio || '',
      accountType: user.accountType || 'user',
      followersCount: user.followersCount || 0,
      followingCount: user.followingCount || 0,
      postsCount,
      isFollowing,
      isVerified: user.isVerified || false,
      createdAt: user.createdAt,
    };

    res.status(200).json({ success: true, data: profileData });
  } catch (error) {
    next(error);
  }
};

// @desc    Search users
// @route   GET /api/users/search?q=
const searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q || q.length < 2) {
      return res.status(200).json({ success: true, data: [] });
    }

    const users = await User.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { username: { $regex: q, $options: 'i' } },
      ],
    })
      .select('name username profilePic avatar accountType bio followersCount')
      .limit(20)
      .lean();

    res.status(200).json({ success: true, count: users.length, data: users });
  } catch (error) {
    next(error);
  }
};

// @desc    Get suggested users to follow
// @route   GET /api/social/users/suggested
const getSuggestedUsers = async (req, res, next) => {
  try {
    const userId = req.user._id;

    // Discover who user already follows
    const follows = await Follow.find({ followerId: userId }).lean();
    let excludeIds = follows.map((f) => f.followingId);
    excludeIds.push(userId); // Also exclude oneself

    // Find users
    const suggested = await User.find({ _id: { $nin: excludeIds } })
      .select('name username profilePic avatar accountType bio')
      // simple random sampling approach (limit and sort)
      .sort({ followersCount: -1, _id: -1 })
      .limit(10)
      .lean();

    res.status(200).json({ success: true, count: suggested.length, data: suggested });
  } catch (error) {
    next(error);
  }
};

// ===================== HELPERS =====================

function _addLikeStatus(posts, userId) {
  const userIdStr = userId.toString();
  posts.forEach((post) => {
    post.isLiked = (post.likes || []).some((id) => id.toString() === userIdStr);
    post.likesCount = post.likesCount || (post.likes || []).length;
    post.commentsCount = post.commentsCount || (post.comments || []).length;
  });
}

// ===================== EXPORTS =====================

module.exports = {
  createPost,
  getFeed,
  explorePosts,
  toggleLike,
  getPostComments,
  addComment,
  savePost,
  unsavePost,
  getUserPosts,
  updatePost,
  deletePost,
  toggleHidePost,
  deleteComment,
  toggleHideComment,
  getPostLikes,
  getMyPosts,
  createStory,
  getStories,
  markStoryViewed,
  deleteStory,
  toggleHideStory,
  getMyStories,
  getReels,
  likeReel,
  toggleFollow,
  unfollowUser,
  checkFollow,
  getFollowersCount,
  getFollowers,
  getFollowing,
  getMyFollowedShops,
  getUserProfile,
  searchUsers,
  getSuggestedUsers,
};
