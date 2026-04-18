const Review = require('../models/Review');
const Shop = require('../models/Shop');
const User = require('../models/User');

// Create a review
exports.createReview = async (req, res, next) => {
  try {
    const { shopId, rating, text } = req.body;
    const userId = req.user._id;

    // Check if user already reviewed this shop
    const existing = await Review.findOne({ userId, shopId });
    if (existing) {
      return res.status(400).json({ success: false, message: 'You already reviewed this shop' });
    }

    const review = await Review.create({
      userId,
      shopId,
      rating,
      text,
      images: req.body.images || [],
    });

    // Update shop rating
    const reviews = await Review.find({ shopId, isHidden: false });
    const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
    await Shop.findByIdAndUpdate(shopId, {
      rating: Math.round(avgRating * 10) / 10,
      totalRatings: reviews.length,
    });

    // Update user stats
    await User.findByIdAndUpdate(userId, { $inc: { totalReviews: 1 } });

    const populated = await Review.findById(review._id).populate('userId', 'name avatar');
    res.status(201).json({ success: true, data: populated });
  } catch (error) {
    next(error);
  }
};

// Get reviews for a shop
exports.getShopReviews = async (req, res, next) => {
  try {
    const { shopId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const reviews = await Review.find({ shopId, isHidden: false })
      .populate('userId', 'name avatar')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Review.countDocuments({ shopId, isHidden: false });

    res.json({
      success: true,
      data: reviews,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// Upvote a review
exports.upvoteReview = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const review = await Review.findById(id);
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

    const index = review.upvotes.indexOf(userId);
    if (index > -1) {
      review.upvotes.splice(index, 1);
    } else {
      review.upvotes.push(userId);
    }
    await review.save();

    res.json({ success: true, data: review, upvoted: index === -1 });
  } catch (error) {
    next(error);
  }
};

// Add owner reply to a review
exports.addOwnerReply = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { text } = req.body;
    const userId = req.user._id;

    const review = await Review.findById(id).populate('shopId');
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

    // Verify the user is the shop owner
    if (review.shopId.ownerId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Only shop owner can reply' });
    }

    review.ownerReply = { text, repliedAt: new Date() };
    await review.save();

    res.json({ success: true, data: review });
  } catch (error) {
    next(error);
  }
};

// Delete a review (by review author or admin)
exports.deleteReview = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const review = await Review.findById(id);
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

    if (review.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await Review.findByIdAndDelete(id);

    // Recalculate shop rating
    const reviews = await Review.find({ shopId: review.shopId, isHidden: false });
    const avgRating = reviews.length > 0
      ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
      : 0;
    await Shop.findByIdAndUpdate(review.shopId, {
      rating: Math.round(avgRating * 10) / 10,
      totalRatings: reviews.length,
    });

    await User.findByIdAndUpdate(userId, { $inc: { totalReviews: -1 } });

    res.json({ success: true, message: 'Review deleted' });
  } catch (error) {
    next(error);
  }
};
