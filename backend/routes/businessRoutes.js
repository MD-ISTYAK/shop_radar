const express = require('express');
const {
  registerBusiness,
  getMyBusinesses,
  getBusinessById,
  updateBusiness,
  deleteBusiness,
  linkShop,
} = require('../controllers/businessController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

// All routes are protected
router.use(protect);

router.post('/register', registerBusiness);
router.get('/my-businesses', getMyBusinesses);
router.get('/:id', getBusinessById);
router.put('/:id', updateBusiness);
router.delete('/:id', deleteBusiness);
router.post('/:id/link-shop', linkShop);

module.exports = router;
