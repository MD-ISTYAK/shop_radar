const express = require('express');
const {
  getModerationDashboard,
  getReportedVideos,
  getVideoModerationDetails,
  approveVideo,
  deleteVideo,
  getUserModerationProfile,
  toggleBanUser,
  getModerationLogs,
} = require('../controllers/moderationController');
const { protect, authorize } = require('../middlewares/authMiddleware');

const router = express.Router();

// All routes require admin authentication
router.use(protect);
router.use(authorize('admin'));

// Dashboard
router.get('/dashboard', getModerationDashboard);

// Reports
router.get('/reports', getReportedVideos);

// Video moderation
router.get('/videos/:id', getVideoModerationDetails);
router.post('/videos/:id/approve', approveVideo);
router.post('/videos/:id/delete', deleteVideo);

// User moderation
router.get('/users/:id', getUserModerationProfile);
router.post('/users/:id/ban', toggleBanUser);

// Logs
router.get('/logs', getModerationLogs);

module.exports = router;
