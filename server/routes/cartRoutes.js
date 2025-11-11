const express = require('express');
const router = express.Router();
const CartItem = require('../models/CartItem');

// Get cart items
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    const cartItems = await CartItem.find({ userId: userId });
    res.json(cartItems);
  } catch (error) {
    console.error('Error fetching cart items:', error);
    res.status(500).json({ error: 'Error fetching cart items' });
  }
});

// Add to cart
router.post('/', async (req, res) => {
  const { userId, productId, productName, price, quantity, size, color, image } = req.body;
  
  try {
    const existingItem = await CartItem.findOne({ 
      userId: userId,
      productId: productId,
      size: size,
      color: color
    });

    if (existingItem) {
      existingItem.quantity += quantity;
      await existingItem.save();
      res.status(200).json(existingItem);
    } else {
      const newCartItem = new CartItem({ userId, productId, productName, price, quantity, size, color, image });
      await newCartItem.save();
      res.status(201).json(newCartItem);
    }
  } catch (error) {
    console.error('Error adding cart item:', error);
    res.status(500).json({ error: 'Error adding cart item' });
  }
});

// Update cart item quantity
router.put('/:userId/:productId', async (req, res) => {
  const { userId, productId } = req.params;
  const { quantity } = req.body;
  
  if (!quantity || quantity < 1) {
    return res.status(400).json({ message: 'Invalid quantity value' });
  }

  try {
    const updatedItem = await CartItem.findOneAndUpdate(
      { userId: userId.toString(), productId: productId.toString() },
      { quantity: quantity },
      { new: true }
    );
    
    if (!updatedItem) {
      return res.status(404).json({ message: 'Cart item not found' });
    }
    
    res.json(updatedItem);
  } catch (error) {
    console.error('Error updating cart item:', error);
    res.status(500).json({ error: 'Error updating cart item' });
  }
});

// Delete cart item
router.delete('/:userId/:productId', async (req, res) => {
  const { userId, productId } = req.params;
  
  try {
    const result = await CartItem.findOneAndDelete({ userId: userId, productId: productId });
    
    if (!result) {
      return res.status(404).json({ message: 'Cart item not found' });
    }
    
    res.json({ message: 'Cart item deleted successfully' });
  } catch (error) {
    console.error('Error deleting cart item:', error);
    res.status(500).json({ error: 'Error deleting cart item' });
  }
});

module.exports = router;