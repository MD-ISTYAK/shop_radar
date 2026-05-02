const express = require('express');
const multer = require('multer');
const { storage } = require('../config/cloudinary');
const { register, login, getProfile, updateProfile, refreshAccessToken } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');
const { registerValidation, loginValidation } = require('../middlewares/validationMiddleware');

const router = express.Router();

const upload = multer({ storage });

router.post('/register', registerValidation, register);
router.post('/login', loginValidation, login);
router.post('/refresh-token', refreshAccessToken);
router.get('/profile', protect, getProfile);
router.put('/profile', protect, upload.single('profilePic'), updateProfile);

module.exports = router;
