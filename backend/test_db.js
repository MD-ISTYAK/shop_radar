const mongoose = require('mongoose');
const DeliveryPartner = require('./models/DeliveryPartner');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/shop_radar').then(async () => {
  const partner = await DeliveryPartner.findOne({ userId: '69f594b803a913af11876fc6' });
  console.log('PARTNER for 69f594b803a913af11876fc6:', partner ? 'FOUND' : 'NOT FOUND');
  process.exit(0);
});
