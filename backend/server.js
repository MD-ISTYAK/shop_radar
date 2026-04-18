const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const http = require('http');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const connectDB = require('./config/db');
const errorHandler = require('./middlewares/errorHandler');
const { initSocket } = require('./config/socketManager');

// Route imports
const authRoutes = require('./routes/authRoutes');
const shopRoutes = require('./routes/shopRoutes');
const productRoutes = require('./routes/productRoutes');
const cartRoutes = require('./routes/cartRoutes');
const socialRoutes = require('./routes/socialRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const tokenRoutes = require('./routes/tokenRoutes');
const deliveryRoutes = require('./routes/deliveryRoutes');
const recommendationRoutes = require('./routes/recommendationRoutes');
const emergencyRoutes = require('./routes/emergencyRoutes');
const chatRoutes = require('./routes/chatRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const checkInRoutes = require('./routes/checkInRoutes');
const dealRoutes = require('./routes/dealRoutes');
const communityRoutes = require('./routes/communityRoutes');
const deliveryPartnerRoutes = require('./routes/deliveryPartnerRoutes');
const walletRoutes = require('./routes/walletRoutes');
const referralRoutes = require('./routes/referralRoutes');
const gamificationRoutes = require('./routes/gamificationRoutes');
const aiRoutes = require('./routes/aiRoutes');
const priceComparisonRoutes = require('./routes/priceComparisonRoutes');
const orderRoutes = require('./routes/orderRoutes');

const app = express();
const server = http.createServer(app);

// Initialize Socket.io
const io = initSocket(server);

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Middleware
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files for uploads
app.use('/uploads', express.static(uploadsDir));

// API Routes — Core
app.use('/api/auth', authRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);

// API Routes — Social
app.use('/api/social', socialRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/checkins', checkInRoutes);
app.use('/api/community', communityRoutes);

// API Routes — Commerce
app.use('/api/deals', dealRoutes);
app.use('/api/prices', priceComparisonRoutes);

// API Routes — Delivery
app.use('/api/delivery', deliveryRoutes);
app.use('/api/delivery-partner', deliveryPartnerRoutes);
app.use('/api/tokens', tokenRoutes);

// API Routes — Finance
app.use('/api/wallet', walletRoutes);
app.use('/api/referrals', referralRoutes);

// API Routes — AI & Features
app.use('/api/ai', aiRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/gamification', gamificationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/emergency', emergencyRoutes);
app.use('/api/chat', chatRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Shop Radar API is running',
    timestamp: new Date().toISOString(),
    version: '2.0.0',
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
  });
});

// Global error handler
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  server.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📡 API: http://localhost:${PORT}/api`);
    console.log(`🔌 Socket.io: enabled`);
  });
};

startServer();

module.exports = app;
