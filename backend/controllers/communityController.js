const CommunityQuestion = require('../models/CommunityQuestion');

// Post a question
exports.postQuestion = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { text, area, lat, lng, tags } = req.body;

    const question = await CommunityQuestion.create({
      userId,
      text,
      area: area || '',
      location: {
        type: 'Point',
        coordinates: [lng || 0, lat || 0],
      },
      tags: tags || [],
    });

    const populated = await CommunityQuestion.findById(question._id)
      .populate('userId', 'name avatar');

    res.status(201).json({ success: true, data: populated });
  } catch (error) {
    next(error);
  }
};

// Answer a question
exports.answerQuestion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;
    const { text, shopMentioned } = req.body;

    const question = await CommunityQuestion.findById(id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    question.answers.push({
      userId,
      text,
      shopMentioned: shopMentioned || null,
    });
    await question.save();

    const populated = await CommunityQuestion.findById(id)
      .populate('userId', 'name avatar')
      .populate('answers.userId', 'name avatar')
      .populate('answers.shopMentioned', 'shopName logo');

    res.json({ success: true, data: populated });
  } catch (error) {
    next(error);
  }
};

// Upvote an answer
exports.upvoteAnswer = async (req, res, next) => {
  try {
    const { id, answerId } = req.params;
    const userId = req.user._id;

    const question = await CommunityQuestion.findById(id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    const answer = question.answers.id(answerId);
    if (!answer) return res.status(404).json({ success: false, message: 'Answer not found' });

    const index = answer.upvotes.indexOf(userId);
    if (index > -1) {
      answer.upvotes.splice(index, 1);
    } else {
      answer.upvotes.push(userId);
    }
    await question.save();

    res.json({ success: true, data: question, upvoted: index === -1 });
  } catch (error) {
    next(error);
  }
};

// Get nearby questions
exports.getNearbyQuestions = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const { tag } = req.query;

    const filter = {};
    if (tag) filter.tags = tag;

    const questions = await CommunityQuestion.find(filter)
      .populate('userId', 'name avatar')
      .populate('answers.userId', 'name avatar')
      .populate('answers.shopMentioned', 'shopName logo')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await CommunityQuestion.countDocuments(filter);

    res.json({
      success: true,
      data: questions,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// Get single question
exports.getQuestion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const question = await CommunityQuestion.findById(id)
      .populate('userId', 'name avatar')
      .populate('answers.userId', 'name avatar')
      .populate('answers.shopMentioned', 'shopName logo');

    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    question.viewCount += 1;
    await question.save();

    res.json({ success: true, data: question });
  } catch (error) {
    next(error);
  }
};

// Delete a question
exports.deleteQuestion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const question = await CommunityQuestion.findById(id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    if (question.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await CommunityQuestion.findByIdAndDelete(id);
    res.json({ success: true, message: 'Question deleted' });
  } catch (error) {
    next(error);
  }
};
