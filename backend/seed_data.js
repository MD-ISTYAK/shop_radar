const mongoose = require('mongoose');
require('dotenv').config();
const Shop = require('./models/Shop');
const User = require('./models/User');

const MONGO_URI = process.env.MONGO_URI;

const sampleShops = [
  {
    shopName: "Fresh Mart Grocery",
    category: "Grocery",
    description: "Your daily needs at best prices.",
    address: "Okhla Phase III, New Delhi",
    location: {
      type: "Point",
      coordinates: [77.2712, 28.5450] // Lng, Lat
    },
    openingTime: "08:00 AM",
    closingTime: "10:00 PM",
    phone: "9876543210",
    status: "open",
    rating: 4.5,
    totalRatings: 120
  },
  {
    shopName: "Apollo Pharmacy",
    category: "Pharmacy",
    description: "24/7 Healthcare services.",
    address: "Kalkaji, New Delhi",
    location: {
      type: "Point",
      coordinates: [77.2580, 28.5400]
    },
    openingTime: "12:00 AM",
    closingTime: "11:59 PM",
    phone: "9876543211",
    status: "open",
    is24x7: true,
    isEmergency: true,
    emergencyType: "medical_store",
    rating: 4.8,
    totalRatings: 350
  },
  {
    shopName: "The Curry House",
    category: "Food & Restaurant",
    description: "Authentic Indian Cuisines.",
    address: "Nehru Place, New Delhi",
    location: {
      type: "Point",
      coordinates: [77.2510, 28.5480]
    },
    openingTime: "11:00 AM",
    closingTime: "11:00 PM",
    phone: "9876543212",
    status: "open",
    features: ["wifi", "parking", "ac", "upi"],
    rating: 4.2,
    totalRatings: 85
  },
  {
    shopName: "Modern Electronics",
    category: "Electronics",
    description: "Latest gadgets and repair services.",
    address: "Govindpuri, New Delhi",
    location: {
      type: "Point",
      coordinates: [77.2650, 28.5350]
    },
    openingTime: "10:00 AM",
    closingTime: "09:00 PM",
    phone: "9876543213",
    status: "open",
    rating: 4.0,
    totalRatings: 45
  },
  {
    shopName: "Style Studio Salon",
    category: "Salon",
    description: "Premium grooming for men and women.",
    address: "Greater Kailash, New Delhi",
    location: {
      type: "Point",
      coordinates: [77.2350, 28.5400]
    },
    openingTime: "09:00 AM",
    closingTime: "08:00 PM",
    phone: "9876543214",
    status: "open",
    rating: 4.6,
    totalRatings: 210
  }
];

async function seed() {
  try {
    console.log('🚀 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected.');

    // Create a default owner user if not exists
    let owner = await User.findOne({ email: 'owner@shopradar.com' });
    if (!owner) {
      console.log('👤 Creating default owner user...');
      owner = await User.create({
        name: 'Demo Owner',
        email: 'owner@shopradar.com',
        password: 'password123',
        phone: '1234567890',
        role: 'owner',
        profileComplete: true
      });
      console.log('✅ Owner created.');
    }

    console.log('🧹 Clearing existing shops (optional, can comment out)...');
    // await Shop.deleteMany({}); 

    console.log('🌱 Seeding shops...');
    for (const shopData of sampleShops) {
      const exists = await Shop.findOne({ shopName: shopData.shopName });
      if (!exists) {
        await Shop.create({
          ...shopData,
          ownerId: owner._id
        });
        console.log(`   + Added: ${shopData.shopName}`);
      } else {
        console.log(`   - Skipped (exists): ${shopData.shopName}`);
      }
    }

    console.log('\n✨ Seeding completed successfully!');
  } catch (err) {
    console.error('❌ Error seeding data:', err.message);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected.');
  }
}

seed();
