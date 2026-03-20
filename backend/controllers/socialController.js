const Post = require('../models/Post');
const Story = require('../models/Story');
const Follow = require('../models/Follow');
const Shop = require('../models/Shop');
const Notification = require('../models/Notification');

// ===================== POSTS =====================

// @desc    Create a post
// @route   POST /api/social/posts
const createPost = async (req, res, next) => {
  try {
    const { content, type } = req.body;
    const shop = await Shop.findOne({ ownerId: req.user._id });
    if (!shop) {
      return res.status(404).json({ success: false, message: 'You must register a shop first' });
    }

    const postData = {
      shopId: shop._id,
      ownerId: req.user._id,
      content: content || '',
      type: type || 'post',
    };

    // Handle image uploads
    if (req.files && req.files.images) {
      postData.images = req.files.images.map((f) => `/uploads/${f.filename}`);
    }
    // Handle video upload for reels
    if (req.files && req.files.video && req.files.video[0]) {
      postData.videoUrl = `/uploads/${req.files.video[0].filename}`;
      postData.type = 'reel';
    }

    const post = await Post.create(postData);

    // Notify followers
    const followers = await Follow.find({ shopId: shop._id });
    const notifications = followers.map((f) => ({
      userId: f.userId,
      type: 'new_post',
      title: `${shop.shopName} shared a new ${postData.type}`,
      body: content ? content.substring(0, 100) : '',
      data: { postId: post._id, shopId: shop._id },
    }));
    if (notifications.length > 0) {
      await Notification.insertMany(notifications);
    }

    res.status(201).json({ success: true, message: 'Post created', data: post });
  } catch (error) {
    next(error);
  }
};

// @desc    Get personalized feed (posts from followed shops)
// @route   GET /api/social/feed?page=&limit=
const getFeed = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get followed shop IDs
    const follows = await Follow.find({ userId: req.user._id });
    const shopIds = follows.map((f) => f.shopId);

    const posts = await Post.find({
      shopId: { $in: shopIds },
      isHidden: { $ne: true },
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('shopId', 'shopName logo')
      .populate('ownerId', 'name avatar')
      .populate({
        path: 'comments.userId',
        select: 'name avatar',
      });

    // Filter hidden comments
    posts.forEach((post) => {
      post.comments = post.comments.filter((c) => !c.isHidden);
    });

    const total = await Post.countDocuments({
      shopId: { $in: shopIds },
      isHidden: { $ne: true },
    });

    res.status(200).json({
      success: true,
      count: posts.length,
      total,
      page: parseInt(page),
      data: posts,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all posts (explore)
// @route   GET /api/social/explore?page=&limit=
const explorePosts = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const posts = await Post.find({ type: 'post', isHidden: { $ne: true } })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('shopId', 'shopName logo')
      .populate('ownerId', 'name avatar')
      .populate({
        path: 'comments.userId',
        select: 'name avatar',
      });

    // Filter hidden comments
    posts.forEach((post) => {
      post.comments = post.comments.filter((c) => !c.isHidden);
    });

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
    const likeIndex = post.likes.indexOf(userId);

    if (likeIndex > -1) {
      post.likes.splice(likeIndex, 1);
    } else {
      post.likes.push(userId);
    }
    await post.save();

    res.status(200).json({
      success: true,
      message: likeIndex > -1 ? 'Unliked' : 'Liked',
      data: { likesCount: post.likes.length, isLiked: likeIndex === -1 },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add comment to post
// @route   POST /api/social/posts/:id/comment
const addComment = async (req, res, next) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Comment text is required' });
    }

    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    post.comments.push({ userId: req.user._id, text: text.trim() });
    await post.save();

    // Populate the last comment
    await post.populate('comments.userId', 'name avatar');

    res.status(201).json({
      success: true,
      message: 'Comment added',
      data: post.comments[post.comments.length - 1],
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

    // Check ownership
    if (post.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized to update this post' });
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

    // Check ownership
    if (post.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this post' });
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

    // Check ownership
    if (post.ownerId.toString() !== req.user._id.toString()) {
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

    // Authorized if owner of post OR author of comment
    if (post.ownerId.toString() !== req.user._id.toString() && comment.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this comment' });
    }

    comment.deleteOne();
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

    // Only post owner can hide comments
    if (post.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Only post owner can hide comments' });
    }

    const comment = post.comments.id(req.params.commentId);
    if (!comment) return res.status(404).json({ success: false, message: 'Comment not found' });

    comment.isHidden = !comment.isHidden;
    await post.save();

    res.status(200).json({ success: true, message: comment.isHidden ? 'Comment hidden' : 'Comment unhidden', data: comment });
  } catch (error) {
    next(error);
  }
};

// @desc    Get post likers
// @route   GET /api/social/posts/:id/likes
const getPostLikes = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id).populate('likes', 'name avatar');
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    res.status(200).json({ success: true, count: post.likes.length, data: post.likes });
  } catch (error) {
    next(error);
  }
};

// @desc    Get my own posts (for shop owner management)
// @route   GET /api/social/my-posts
const getMyPosts = async (req, res, next) => {
  try {
    const posts = await Post.find({ ownerId: req.user._id })
      .sort({ createdAt: -1 })
      .populate('comments.userId', 'name avatar');

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
    const shop = await Shop.findOne({ ownerId: req.user._id });
    if (!shop) {
      return res.status(404).json({ success: false, message: 'You must register a shop first' });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Image is required for stories' });
    }

    const story = await Story.create({
      shopId: shop._id,
      ownerId: req.user._id,
      imageUrl: `/uploads/${req.file.filename}`,
      caption: req.body.caption || '',
    });

    res.status(201).json({ success: true, message: 'Story created', data: story });
  } catch (error) {
    next(error);
  }
};

// @desc    Get active stories (from followed shops)
// @route   GET /api/social/stories
const getStories = async (req, res, next) => {
  try {
    const follows = await Follow.find({ userId: req.user._id });
    const shopIds = follows.map((f) => f.shopId);

    // Get stories from followed shops, grouped by shop
    const stories = await Story.find({
      shopId: { $in: shopIds },
      expiresAt: { $gt: new Date() },
      isHidden: { $ne: true },
    })
      .sort({ createdAt: -1 })
      .populate('shopId', 'shopName logo');

    // Group by shop
    const grouped = {};
    stories.forEach((story) => {
      const sid = story.shopId._id.toString();
      if (!grouped[sid]) {
        grouped[sid] = {
          shop: story.shopId,
          stories: [],
        };
      }
      grouped[sid].stories.push(story);
    });

    res.status(200).json({ success: true, data: Object.values(grouped) });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a story
// @route   DELETE /api/social/stories/:id
const deleteStory = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id);

    if (!story) return res.status(404).json({ success: false, message: 'Story not found' });

    // Check ownership
    if (story.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this story' });
    }

    await Story.findByIdAndDelete(req.params.id);

    res.status(200).json({ success: true, message: 'Story deleted' });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle hide story
// @route   PATCH /api/social/stories/:id/hide
const toggleHideStory = async (req, res, next) => {
  try {
    const story = await Story.findById(req.params.id);

    if (!story) return res.status(404).json({ success: false, message: 'Story not found' });

    // Check ownership
    if (story.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    story.isHidden = !story.isHidden;
    await story.save();

    res.status(200).json({ success: true, message: story.isHidden ? 'Story hidden' : 'Story unhidden', data: story });
  } catch (error) {
    next(error);
  }
};

// @desc    Get my active stories
// @route   GET /api/social/my-stories
const getMyStories = async (req, res, next) => {
  try {
    const stories = await Story.find({ ownerId: req.user._id }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: stories.length, data: stories });
  } catch (error) {
    next(error);
  }
};

// ===================== REELS =====================

// @desc    Get reels feed
// @route   GET /api/social/reels?page=&limit=
const getReels = async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const reels = await Post.find({
      type: 'reel',
      videoUrl: { $ne: '' },
      isHidden: { $ne: true },
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('shopId', 'shopName logo')
      .populate('ownerId', 'name avatar');

    res.status(200).json({ success: true, count: reels.length, data: reels });
  } catch (error) {
    next(error);
  }
};

// ===================== FOLLOW =====================

// @desc    Toggle follow a shop
// @route   POST /api/social/follow/:shopId
const toggleFollow = async (req, res, next) => {
  try {
    const { shopId } = req.params;
    const userId = req.user._id;

    const existing = await Follow.findOne({ userId, shopId });

    if (existing) {
      await Follow.findByIdAndDelete(existing._id);
      return res.status(200).json({ success: true, message: 'Unfollowed', data: { isFollowing: false } });
    }

    await Follow.create({ userId, shopId });
    res.status(201).json({ success: true, message: 'Followed', data: { isFollowing: true } });
  } catch (error) {
    next(error);
  }
};

// @desc    Check if user follows a shop
// @route   GET /api/social/follow/:shopId/check
const checkFollow = async (req, res, next) => {
  try {
    const existing = await Follow.findOne({ userId: req.user._id, shopId: req.params.shopId });
    res.status(200).json({ success: true, data: { isFollowing: !!existing } });
  } catch (error) {
    next(error);
  }
};

// @desc    Get followers count for a shop
// @route   GET /api/social/follow/:shopId/count
const getFollowersCount = async (req, res, next) => {
  try {
    const count = await Follow.countDocuments({ shopId: req.params.shopId });
    res.status(200).json({ success: true, data: { count } });
  } catch (error) {
    next(error);
  }
};

// @desc    Get shops the current user follows
// @route   GET /api/social/follow/my-follows
const getMyFollowedShops = async (req, res, next) => {
  try {
    const follows = await Follow.find({ userId: req.user._id })
      .populate('shopId', 'shopName logo category address status rating openingTime closingTime phone');

    const shops = follows
      .filter((f) => f.shopId != null)
      .map((f) => f.shopId);

    res.status(200).json({ success: true, count: shops.length, data: shops });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createPost,
  getFeed,
  explorePosts,
  toggleLike,
  addComment,
  updatePost,
  deletePost,
  toggleHidePost,
  deleteComment,
  toggleHideComment,
  getPostLikes,
  getMyPosts,
  createStory,
  getStories,
  deleteStory,
  toggleHideStory,
  getMyStories,
  getReels,
  toggleFollow,
  checkFollow,
  getFollowersCount,
  getMyFollowedShops,
};
