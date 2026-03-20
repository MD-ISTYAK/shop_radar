const express = require('express');
const { getEmergencyServices } = require('../controllers/emergencyController');

const router = express.Router();

// Public route — no auth needed for emergencies
router.get('/', getEmergencyServices);

module.exports = router;
