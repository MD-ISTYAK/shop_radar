const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const http = require('http');
const path = require('path');
const fs = require('fs');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');
const crypto = require('crypto');
require('dotenv').config();

const connectDB = require('./config/db');
const errorHandler = require('./middlewares/errorHandler');
const { initSocket } = require('./config/socketManager');
const logger = require('./config/logger');

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
const financialRoutes = require('./routes/financialRoutes');
const referralRoutes = require('./routes/referralRoutes');
const gamificationRoutes = require('./routes/gamificationRoutes');
const aiRoutes = require('./routes/aiRoutes');
const priceComparisonRoutes = require('./routes/priceComparisonRoutes');
const orderRoutes = require('./routes/orderRoutes');
const userRoutes = require('./routes/userRoutes');
const businessRoutes = require('./routes/businessRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const moderationRoutes = require('./routes/moderationRoutes');
const subscriptionRoutes = require('./routes/subscriptionRoutes');
const { startTrustScoreScheduler } = require('./services/trustScoreJob');

const app = express();
const server = http.createServer(app);

// Initialize Socket.io
const io = initSocket(server);

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// ── Security Middleware ──

// Request ID for tracing
app.use((req, res, next) => {
  req.requestId = crypto.randomUUID();
  res.setHeader('X-Request-Id', req.requestId);
  next();
});

// Request logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`, {
      requestId: req.requestId,
      userId: req.user?._id,
      method: req.method,
      path: req.originalUrl,
      statusCode: res.statusCode,
      duration,
    });
  });
  next();
});

app.use(compression());
app.use(helmet({ crossOriginResourcePolicy: false }));

// CORS — restrict in production
const corsOptions = {
  origin: process.env.NODE_ENV === 'production'
    ? (process.env.CORS_ORIGINS || '').split(',').map(s => s.trim())
    : '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
app.use(cors(corsOptions));

// Rate limiting — general
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use('/api/', generalLimiter);

// Rate limiting — auth (strict)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many login attempts, please try again after 15 minutes.' },
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

// Razorpay webhook needs raw body — must come BEFORE express.json()
app.use('/api/payments/webhook', express.raw({ type: 'application/json' }));

// Body parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// NoSQL injection prevention
app.use(mongoSanitize());

// HTTP parameter pollution protection
app.use(hpp());

// Static files for uploads
app.use('/uploads', express.static(uploadsDir));

// API Routes — Core
app.use('/api/auth', authRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);

// API Routes — Social
app.use('/api/social', socialRoutes);
app.use('/api/users', userRoutes);
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
app.use('/api/finance', financialRoutes);
app.use('/api/referrals', referralRoutes);

// API Routes — AI & Features
app.use('/api/ai', aiRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/gamification', gamificationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/emergency', emergencyRoutes);
app.use('/api/chat', chatRoutes);

// API Routes — Business
app.use('/api/business', businessRoutes);

// API Routes — Moderation (admin only)
app.use('/api/moderation', moderationRoutes);

// API Routes — Subscription
app.use('/api/subscription', subscriptionRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Shop Radar API is running',
    timestamp: new Date().toISOString(),
    version: '2.1.0',
  });
});

// 404 handler
app.use((req, res) => {
  console.log(`[Express 404 Handler] Route ${req.method} ${req.originalUrl} not found`);
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
    logger.info(`🚀 Server running on port ${PORT}`);
    logger.info(`📡 API: http://localhost:${PORT}/api`);
    logger.info(`🔌 Socket.io: enabled`);
    logger.info(`🛡️  Security: rate-limit, mongo-sanitize, hpp, helmet active`);

    // Start trust score background scheduler
    startTrustScoreScheduler();
  });
};

startServer();

module.exports = app;
