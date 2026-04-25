const express = require('express');
const { sendMessage, getConversations, getMessages, startConversation } = require('../controllers/chatController');
const { protect } = require('../middlewares/authMiddleware');
const multer = require('multer');
const { storage } = require('../config/cloudinary');

const router = express.Router();
const upload = multer({ storage });

router.use(protect);

router.post('/send', upload.single('media'), sendMessage);
router.get('/conversations', getConversations);
router.get('/messages/:conversationId', getMessages);
router.post('/start', startConversation);

module.exports = router;
