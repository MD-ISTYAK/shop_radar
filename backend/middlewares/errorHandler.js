const logger = require('../config/logger');

const errorHandler = (err, req, res, _next) => {
  const requestId = req.requestId || 'unknown';
  
  logger.error(err.message, {
    requestId,
    stack: err.stack,
    method: req.method,
    path: req.originalUrl,
    userId: req.user?._id?.toString(),
  });

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map((e) => e.message);
    return res.status(400).json({
      success: false,
      message: 'Validation Error',
      errors: messages,
      requestId,
    });
  }

  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    return res.status(400).json({
      success: false,
      message: `Duplicate value for field: ${field}`,
      requestId,
    });
  }

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    return res.status(400).json({
      success: false,
      message: `Invalid ${err.path}: ${err.value}`,
      requestId,
    });
  }

  // Mongoose document not found
  if (err.name === 'DocumentNotFoundError') {
    return res.status(404).json({
      success: false,
      message: 'Document not found',
      requestId,
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid token',
      requestId,
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token expired',
      requestId,
    });
  }

  // Default server error
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: statusCode === 500 ? 'Internal Server Error' : err.message,
    requestId,
  });
};

module.exports = errorHandler;
