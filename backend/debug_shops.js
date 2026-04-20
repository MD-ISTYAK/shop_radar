require('dotenv').config();
const mongoose = require('mongoose');

async function debug() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('shops');

    // 1. Check total shops
    const count = await collection.countDocuments();
    console.log(`\n🏪 Total shops in DB: ${count}`);

    // 2. List all shops with coordinates
    const shops = await collection.find({}).project({ shopName: 1, location: 1, category: 1, status: 1 }).toArray();
    shops.forEach(s => {
      console.log(`   -> ${s.shopName} | location: ${JSON.stringify(s.location)} | category: ${s.category} | status: ${s.status}`);
    });

    // 3. Check existing indexes
    const indexes = await collection.indexes();
    console.log(`\n📑 Indexes on 'shops' collection:`);
    indexes.forEach(idx => {
      console.log(`   -> ${idx.name}: ${JSON.stringify(idx.key)}`);
    });

    // 4. Check if 2dsphere index exists
    const has2dsphere = indexes.some(idx => {
      return Object.values(idx.key).includes('2dsphere');
    });

    if (!has2dsphere) {
      console.log('\n⚠️  NO 2dsphere index found! Creating one now...');
      await collection.createIndex({ location: '2dsphere' });
      console.log('✅ 2dsphere index created successfully!');
    } else {
      console.log('\n✅ 2dsphere index already exists');
    }

    // 5. Test a geo query with huge radius
    if (shops.length > 0 && shops[0].location?.coordinates) {
      const [lng, lat] = shops[0].location.coordinates;
      console.log(`\n🧪 Testing $near query with first shop's coordinates: [${lng}, ${lat}]`);
      try {
        const nearbyResults = await collection.find({
          location: {
            $near: {
              $geometry: { type: 'Point', coordinates: [lng, lat] },
              $maxDistance: 50000 // 50km
            }
          }
        }).toArray();
        console.log(`✅ $near query returned ${nearbyResults.length} results`);
      } catch (err) {
        console.error(`❌ $near query failed: ${err.message}`);
      }
    }

  } catch (err) {
    console.error('❌ Error:', err.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected');
  }
}

debug();
