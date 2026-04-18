const express = require('express');
const router = express.Router();
const multer = require('multer');
const { storage } = require('../config/cloudinary');

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
});

const { protect } = require('../middlewares/authMiddleware');
const {
  registerAsPartner,
  updateKYC,
  toggleOnline,
  updateLocation,
  getAvailableDeliveries,
  acceptDelivery,
  completeDelivery,
  getMyPartnerProfile,
  getEarnings,
} = require('../controllers/deliveryPartnerController');

router.post('/register', protect, registerAsPartner);
router.put('/kyc', protect, updateKYC);
router.post('/toggle-online', protect, toggleOnline);
router.post('/update-location', protect, updateLocation);
router.get('/available', protect, getAvailableDeliveries);
router.post('/accept/:deliveryId', protect, acceptDelivery);
router.post('/complete/:deliveryId', protect, upload.array('images', 5), completeDelivery);
router.get('/profile', protect, getMyPartnerProfile);
router.get('/earnings', protect, getEarnings);

module.exports = router;
