const Token = require('../models/Token');
const Shop = require('../models/Shop');

// @desc    Take a token (user joins queue)
// @route   POST /api/tokens/take
const takeToken = async (req, res, next) => {
  try {
    const { shopId } = req.body;

    // Check if user already has an active token at this shop
    const existing = await Token.findOne({
      shopId,
      userId: req.user._id,
      status: { $in: ['waiting', 'serving'] },
    });
    if (existing) {
      return res.status(400).json({ success: false, message: 'You already have an active token at this shop' });
    }

    // Get the last token number for this shop today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const lastToken = await Token.findOne({
      shopId,
      createdAt: { $gte: today },
    }).sort({ tokenNumber: -1 });

    const tokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

    // Count waiting tokens for estimated wait time (5 min per token)
    const waitingCount = await Token.countDocuments({ shopId, status: 'waiting' });
    const estimatedWaitMinutes = waitingCount * 5;

    const token = await Token.create({
      shopId,
      userId: req.user._id,
      tokenNumber,
      estimatedWaitMinutes,
    });

    res.status(201).json({
      success: true,
      message: `Token #${tokenNumber} taken`,
      data: token,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get queue status for a shop
// @route   GET /api/tokens/shop/:shopId
const getQueueStatus = async (req, res, next) => {
  try {
    const { shopId } = req.params;

    const serving = await Token.findOne({ shopId, status: 'serving' })
      .populate('userId', 'name');

    const waiting = await Token.find({ shopId, status: 'waiting' })
      .sort({ tokenNumber: 1 })
      .populate('userId', 'name');

    res.status(200).json({
      success: true,
      data: {
        currentlyServing: serving ? serving.tokenNumber : 0,
        waitingCount: waiting.length,
        waitingTokens: waiting,
        estimatedWaitMinutes: waiting.length * 5,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's active token
// @route   GET /api/tokens/my-token
const getMyToken = async (req, res, next) => {
  try {
    const token = await Token.findOne({
      userId: req.user._id,
      status: { $in: ['waiting', 'serving'] },
    }).populate('shopId', 'shopName');

    if (!token) {
      return res.status(200).json({ success: true, data: null });
    }

    // Get position in queue
    const ahead = await Token.countDocuments({
      shopId: token.shopId,
      status: 'waiting',
      tokenNumber: { $lt: token.tokenNumber },
    });

    const tokenData = token.toObject();
    tokenData.positionInQueue = ahead + 1;
    tokenData.estimatedWaitMinutes = ahead * 5;

    res.status(200).json({ success: true, data: tokenData });
  } catch (error) {
    next(error);
  }
};

// @desc    Advance queue (owner marks current as completed, serves next)
// @route   POST /api/tokens/advance/:shopId
const advanceQueue = async (req, res, next) => {
  try {
    const { shopId } = req.params;

    // Verify ownership
    const shop = await Shop.findById(shopId);
    if (!shop || shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    // Complete current serving token
    await Token.findOneAndUpdate({ shopId, status: 'serving' }, { status: 'completed' });

    // Serve next waiting token
    const nextToken = await Token.findOneAndUpdate(
      { shopId, status: 'waiting' },
      { status: 'serving' },
      { new: true, sort: { tokenNumber: 1 } }
    );

    res.status(200).json({
      success: true,
      message: nextToken ? `Now serving token #${nextToken.tokenNumber}` : 'Queue is empty',
      data: nextToken,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Cancel token
// @route   DELETE /api/tokens/:id
const cancelToken = async (req, res, next) => {
  try {
    const token = await Token.findById(req.params.id);
    if (!token) return res.status(404).json({ success: false, message: 'Token not found' });

    if (token.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    token.status = 'cancelled';
    await token.save();

    res.status(200).json({ success: true, message: 'Token cancelled' });
  } catch (error) {
    next(error);
  }
};

module.exports = { takeToken, getQueueStatus, getMyToken, advanceQueue, cancelToken };
