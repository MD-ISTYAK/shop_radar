const express = require('express');
const { sendMessage, getConversations, getMessages, startConversation } = require('../controllers/chatController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/send', sendMessage);
router.get('/conversations', getConversations);
router.get('/messages/:conversationId', getMessages);
router.post('/start', startConversation);

module.exports = router;
