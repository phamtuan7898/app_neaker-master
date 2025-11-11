const express = require('express');
const router = express.Router();
const Comment = require('../models/Comment');
const Product = require('../models/Product');

// Get comments by product
router.get('/:productId', async (req, res) => {
  const { productId } = req.params;
  
  try {
    const comments = await Comment.find({ productId }).sort({ createdAt: -1 });
    res.json(comments);
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ error: 'Error fetching comments' });
  }
});

// Add comment
router.post('/', async (req, res) => {
  const { productId, userId, username, comment, rating } = req.body;
  
  try {
    const newComment = new Comment({ productId, userId, username, comment, rating });
    await newComment.save();
    
    // Update product rating
    const comments = await Comment.find({ productId });
    const totalRating = comments.reduce((sum, item) => sum + item.rating, 0);
    const averageRating = totalRating / comments.length;
    
    await Product.findByIdAndUpdate(
      productId,
      { rating: averageRating.toFixed(1) },
      { new: true }
    );
    
    res.status(201).json(newComment);
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({ error: 'Error adding comment' });
  }
});

module.exports = router;