const Shop = require('../models/Shop');
const { calculateDistance, formatDistance } = require('../utils/geoDistance');

// Emergency categories mapped to shop categories
const EMERGENCY_MAPPING = {
  hospital: ['Pharmacy', 'Other'],
  medical_store: ['Pharmacy'],
  petrol_pump: ['Other'],
  mechanic: ['Hardware', 'Other'],
};

// @desc    Get emergency services nearby
// @route   GET /api/emergency?type=&lat=&lng=
const getEmergencyServices = async (req, res, next) => {
  try {
    const { type, lat, lng } = req.query;

    const query = { isEmergency: true };

    if (type && EMERGENCY_MAPPING[type]) {
      query.emergencyType = type;
    }

    // Geospatial sort if coordinates provided
    if (lat && lng) {
      query.location = {
        $near: {
          $geometry: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
          $maxDistance: 20000, // 20km radius for emergencies
        },
      };
    }

    const services = await Shop.find(query).limit(20);

    const result = services.map((shop) => {
      const s = shop.toObject();
      if (lat && lng) {
        const dist = calculateDistance(parseFloat(lat), parseFloat(lng), shop.location.coordinates[1], shop.location.coordinates[0]);
        s.distance = dist;
        s.distanceFormatted = formatDistance(dist);
      }
      return s;
    });

    res.status(200).json({ success: true, count: result.length, data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = { getEmergencyServices };
