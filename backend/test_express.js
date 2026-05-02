const mongoose = require('mongoose');
const User = require('./models/User');
const { generateToken } = require('./config/jwt');
const http = require('http');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/shop_radar').then(async () => {
  const user = await User.findById('69f594b803a913af11876fc6');
  if (!user) {
    console.log('USER NOT FOUND IN DB');
    process.exit(1);
  }
  const token = generateToken({ id: user._id.toString() });

  const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/social/profile/69f594b803a913af11876fc6',
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  };

  const req = http.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('BODY:', data);
      process.exit(0);
    });
  });

  req.on('error', (e) => {
    console.error(`problem with request: ${e.message}`);
    process.exit(1);
  });

  req.end();
});
