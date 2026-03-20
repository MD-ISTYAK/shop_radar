const express = require('express');
const multer = require('multer');
const path = require('path');
const {
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
} = require('../controllers/socialController');
const { protect, authorize } = require('../middlewares/authMiddleware');

const router = express.Router();

// Multer config for social media uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) =>
    cb(null, `social-${Date.now()}-${Math.round(Math.random() * 1e6)}${path.extname(file.originalname)}`),
});

const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB for videos
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp|mp4|mov|avi/;
    const ext = allowed.test(path.extname(file.originalname).toLowerCase());
    if (ext) return cb(null, true);
    cb(new Error('Only image and video files are allowed'));
  },
});

const postUpload = upload.fields([
  { name: 'images', maxCount: 5 },
  { name: 'video', maxCount: 1 },
]);

// All routes require authentication
router.use(protect);

// Posts
router.post('/posts', authorize('owner'), postUpload, createPost);
router.get('/feed', getFeed);
router.get('/explore', explorePosts);
router.get('/my-posts', authorize('owner'), getMyPosts);
router.post('/posts/:id/like', toggleLike);
router.get('/posts/:id/likes', getPostLikes);
router.post('/posts/:id/comment', addComment);
router.put('/posts/:id', authorize('owner'), updatePost);
router.delete('/posts/:id', authorize('owner'), deletePost);
router.patch('/posts/:id/hide', authorize('owner'), toggleHidePost);
router.delete('/posts/:postId/comments/:commentId', deleteComment);
router.patch('/posts/:postId/comments/:commentId/hide', authorize('owner'), toggleHideComment);

// Stories
router.post('/stories', authorize('owner'), upload.single('image'), createStory);
router.get('/stories', getStories);
router.get('/my-stories', authorize('owner'), getMyStories);
router.delete('/stories/:id', authorize('owner'), deleteStory);
router.patch('/stories/:id/hide', authorize('owner'), toggleHideStory);

// Reels
router.get('/reels', getReels);

// Follow - my-follows MUST be before parameterized :shopId routes
router.get('/follow/my-follows', getMyFollowedShops);
router.post('/follow/:shopId', toggleFollow);
router.get('/follow/:shopId/check', checkFollow);
router.get('/follow/:shopId/count', getFollowersCount);

module.exports = router;
