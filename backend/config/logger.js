const winston = require('winston');
const path = require('path');

const isProduction = process.env.NODE_ENV === 'production';

const logger = winston.createLogger({
  level: isProduction ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'shop-radar-api' },
  transports: [
    // Console transport (always)
    new winston.transports.Console({
      format: isProduction
        ? winston.format.json()
        : winston.format.combine(
            winston.format.colorize(),
            winston.format.printf(({ timestamp, level, message, requestId, userId, ...rest }) => {
              let log = `${timestamp} [${level}]`;
              if (requestId) log += ` [req:${requestId}]`;
              if (userId) log += ` [user:${userId}]`;
              log += ` ${message}`;
              const extra = Object.keys(rest).filter(k => k !== 'service').length;
              if (extra > 0) {
                const filtered = { ...rest };
                delete filtered.service;
                log += ` ${JSON.stringify(filtered)}`;
              }
              return log;
            })
          ),
    }),
  ],
});

// File transport in production
if (isProduction) {
  logger.add(
    new winston.transports.File({
      filename: path.join(__dirname, '..', 'logs', 'error.log'),
      level: 'error',
      maxsize: 5 * 1024 * 1024, // 5MB
      maxFiles: 5,
    })
  );
  logger.add(
    new winston.transports.File({
      filename: path.join(__dirname, '..', 'logs', 'combined.log'),
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 5,
    })
  );
}

module.exports = logger;
