const express = require('express');
const multer = require('multer');
const compression = require('compression');
const {
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
  votePoll,
  answerQuestion,
  createReport,
  getSavedPosts,
  getFriends,
} = require('../controllers/socialController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

const { storage } = require('../config/cloudinary');

const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB for videos
});

const postUpload = upload.fields([
  { name: 'images', maxCount: 10 },
  { name: 'video', maxCount: 1 },
]);

// All routes require authentication
router.use(protect);

// ===================== POSTS =====================
router.post('/posts', postUpload, createPost);
router.get('/feed', compression(), getFeed);
router.get('/explore', compression(), explorePosts);
router.get('/my-posts', getMyPosts);
router.post('/posts/:id/like', toggleLike);
router.get('/posts/:id/likes', getPostLikes);
router.get('/posts/:id/comments', getPostComments);
router.post('/posts/:id/comment', addComment);
router.post('/posts/:id/save', savePost);
router.delete('/posts/:id/save', unsavePost);
router.put('/posts/:id', updatePost);
router.delete('/posts/:id', deletePost);
router.patch('/posts/:id/hide', toggleHidePost);
router.delete('/posts/:postId/comments/:commentId', deleteComment);
router.patch('/posts/:postId/comments/:commentId/hide', toggleHideComment);

// ===================== INTERACTIVE ELEMENTS =====================
router.post('/posts/:id/poll/vote', votePoll);
router.post('/posts/:id/question/answer', answerQuestion);
router.post('/stories/:id/poll/vote', votePoll);
router.post('/stories/:id/question/answer', answerQuestion);

// ===================== USER POSTS =====================
router.get('/users/suggested', protect, getSuggestedUsers);
router.get('/users/:userId/posts', getUserPosts);

// ===================== STORIES =====================
router.post('/stories', upload.single('image'), createStory);
router.get('/stories', getStories);
router.post('/stories/:id/view', markStoryViewed);
router.get('/my-stories', getMyStories);
router.delete('/stories/:id', deleteStory);
router.patch('/stories/:id/hide', toggleHideStory);

// ===================== REELS =====================
router.get('/reels', getReels);
router.post('/reels/:id/like', likeReel);

// ===================== FOLLOW =====================
// Static routes MUST come before parameterized :userId routes
router.get('/follow/my-follows', getMyFollowedShops);
router.post('/follow/:userId', toggleFollow);
router.delete('/unfollow/:userId', unfollowUser);
router.get('/follow/:userId/check', checkFollow);
router.get('/follow/:userId/count', getFollowersCount);
router.get('/followers/:userId', getFollowers);
router.get('/following/:userId', getFollowing);
router.get('/friends/:userId', getFriends);

// ===================== PROFILE =====================
router.get('/profile/:userId', getUserProfile);

// ===================== REPORTS & SAVED =====================
router.post('/report', createReport);
router.get('/saved-posts', getSavedPosts);

module.exports = router;
