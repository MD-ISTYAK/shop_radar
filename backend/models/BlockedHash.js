const mongoose = require('mongoose');

const blockedHashSchema = new mongoose.Schema(
  {
    hash: {
      type: String,
      required: true,
      index: true,
    },
    hashType: {
      type: String,
      enum: ['video', 'audio'],
      required: true,
    },
    reason: {
      type: String,
      default: '',
    },
    addedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    sourceVideoId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
    },
  },
  { timestamps: true }
);

blockedHashSchema.index({ hash: 1, hashType: 1 });

module.exports = mongoose.model('BlockedHash', blockedHashSchema);
