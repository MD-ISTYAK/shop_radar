const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const Shop = require('./models/Shop');
const Product = require('./models/Product');

dotenv.config();

const products = [
  {
    shopName: 'Fresh Mart Grocery',
    items: [
      { name: 'Organic Apples', price: 120, discount: 10, stock: 50, category: 'Fruits', unit: 'kg', description: 'Fresh organic apples from Himachal.' },
      { name: 'Amul Milk', price: 66, discount: 0, stock: 100, category: 'Dairy', unit: 'litre', description: 'Fresh pasteurized milk.' },
      { name: 'Brown Bread', price: 50, discount: 5, stock: 30, category: 'Bakery', unit: 'piece', description: 'Healthy whole wheat bread.' }
    ]
  },
  {
    shopName: 'Apollo Pharmacy',
    items: [
      { name: 'Paracetamol', price: 30, discount: 0, stock: 200, category: 'Medicine', unit: 'pack', description: 'Standard pain reliever.' },
      { name: 'Vitamin C Tablets', price: 150, discount: 15, stock: 100, category: 'Supplements', unit: 'pack', description: 'Immunity booster.' },
      { name: 'Digital Thermometer', price: 250, discount: 10, stock: 20, category: 'Medical Equipment', unit: 'piece', description: 'Fast and accurate reading.' }
    ]
  },
  {
    shopName: 'The Curry House',
    items: [
      { name: 'Butter Chicken', price: 350, discount: 10, stock: 50, category: 'Main Course', unit: 'piece', description: 'Rich and creamy chicken curry.' },
      { name: 'Garlic Naan', price: 40, discount: 0, stock: 100, category: 'Bread', unit: 'piece', description: 'Soft tandoori bread with garlic.' },
      { name: 'Mango Lassi', price: 80, discount: 5, stock: 40, category: 'Beverage', unit: 'piece', description: 'Refreshing mango yogurt drink.' }
    ]
  },
  {
    shopName: 'Modern Electronics',
    items: [
      { name: 'Wireless Earbuds', price: 1999, discount: 20, stock: 30, category: 'Audio', unit: 'piece', description: 'Noise cancelling TWS earbuds.' },
      { name: 'Power Bank 10000mAh', price: 899, discount: 10, stock: 50, category: 'Accessories', unit: 'piece', description: 'Fast charging slim power bank.' },
      { name: 'Mechanical Keyboard', price: 2499, discount: 15, stock: 15, category: 'Peripherals', unit: 'piece', description: 'RGB backlit mechanical keyboard.' }
    ]
  },
  {
    shopName: 'Style Studio Salon',
    items: [
      { name: 'Hair Cut & Styling', price: 300, discount: 0, stock: 10, category: 'Service', unit: 'other', description: 'Professional hair cut and styling.' },
      { name: 'Facial Treatment', price: 800, discount: 20, stock: 5, category: 'Service', unit: 'other', description: 'Deep cleansing facial treatment.' },
      { name: 'Argan Hair Oil', price: 450, discount: 10, stock: 25, category: 'Product', unit: 'piece', description: 'Nourishing oil for healthy hair.' }
    ]
  }
];

const seedProducts = async () => {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected!');

    // Clear existing products to avoid duplicates
    await Product.deleteMany({});
    console.log('Old products cleared.');

    for (const shopData of products) {
      const shop = await Shop.findOne({ shopName: shopData.shopName });
      if (shop) {
        console.log(`Seeding products for ${shop.shopName}...`);
        const itemsToSeed = shopData.items.map(item => ({
          ...item,
          shopId: shop._id
        }));
        await Product.insertMany(itemsToSeed);
      } else {
        console.log(`Shop ${shopData.shopName} not found, skipping.`);
      }
    }

    console.log('Seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding products:', error);
    process.exit(1);
  }
};

seedProducts();
