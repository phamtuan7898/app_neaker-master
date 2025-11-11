const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  userId: { type: String, required: true },
  username: { type: String, required: true },
  comment: { type: String, required: true },
  rating: { type: Number, required: true, min: 1, max: 5 },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Comment', commentSchema);