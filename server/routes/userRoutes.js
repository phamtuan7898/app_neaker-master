const express = require('express');
const router = express.Router();
const User = require('../models/User');
const CartItem = require('../models/CartItem');
const Comment = require('../models/Comment');
const Order = require('../models/Order');
const mongoose = require('mongoose');
const upload = require('../middleware/upload');

// Register User
router.post('/register', async (req, res) => {
  const { username, password, email } = req.body;
  const img = req.body.img || '';
  const phone = req.body.phone || '';
  const address = req.body.address || '';

  try {
    const newUser = new User({ username, password, email, img, phone, address });
    await newUser.save();
    res.status(201).json(newUser);
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ error: 'Error registering user' });
  }
});

// User Login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const user = await User.findOne({
      $or: [{ username: username }, { email: username }],
    });

    if (!user || user.password !== password) {
      return res.status(400).json({ error: 'Invalid username or password' });
    }

    res.json(user);
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Check user exists
router.post('/check-user', async (req, res) => {
  const { emailOrUsername } = req.body;
  
  try {
    const user = await User.findOne({
      $or: [{ email: emailOrUsername }, { username: emailOrUsername }]
    });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'No account found' });
    }

    res.json({ success: true, userId: user._id, message: 'Valid account' });
  } catch (error) {
    console.error('Error checking user:', error);
    res.status(500).json({ success: false, message: 'Error checking account' });
  }
});

// Forgot Password
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'No user found' });
    }

    // Email sending logic here...
    res.json({ success: true, message: 'Password reset email has been sent' });
  } catch (error) {
    console.error('Error handling forgotten password:', error);
    res.status(500).json({ success: false, message: 'Error processing request' });
  }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
  const { userId, newPassword } = req.body;
  
  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.password = newPassword;
    await user.save();
    res.json({ success: true, message: 'Password updated successfully' });
  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({ success: false, message: 'Error resetting password' });
  }
});

// Get user profile
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const user = await User.findById(id);
    if (user) {
      res.json(user);
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Error fetching user profile' });
  }
});

// Update user profile
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { username, email, phone, address, img } = req.body;

  try {
    const updatedUser = await User.findByIdAndUpdate(
      id,
      { username, email, phone, address, img },
      { new: true }
    );

    if (updatedUser) {
      res.json(updatedUser);
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ error: 'Error updating user profile' });
  }
});

// Upload user image
router.post('/:id/upload-image', upload.single('image'), async (req, res) => {
  const { id } = req.params;
  try {
    const user = await User.findById(id);
    if (user) {
      user.img = req.file.path;
      await user.save();
      res.status(200).json(user);
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).json({ error: 'Error uploading image' });
  }
});

// Change password
router.put('/:userId/change-password', async (req, res) => {
  const { userId } = req.params;
  const { oldPassword, newPassword } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).send('User not found');
    if (user.password !== oldPassword) return res.status(401).send('Old password is incorrect');

    user.password = newPassword;
    await user.save();
    return res.status(200).send('Password updated successfully');
  } catch (error) {
    console.error('Error changing password:', error);
    return res.status(500).send('Internal server error');
  }
});

// Delete account - UPDATED VERSION for your CartItem model
router.delete('/:id/delete-account', async (req, res) => {
  const { id } = req.params;
  const { password } = req.body;

  try {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // Tìm user với session
      const user = await User.findById(id).session(session);
      if (!user) {
        await session.abortTransaction();
        return res.status(404).json({ message: 'User not found' });
      }

      // Kiểm tra password
      if (user.password !== password) {
        await session.abortTransaction();
        return res.status(401).json({ message: 'Invalid password' });
      }

      // XÓA TOÀN BỘ DỮ LIỆU NGƯỜI DÙNG TRONG TRANSACTION
      
      // 1. Xóa cart items
      await CartItem.deleteMany({ userId: id }).session(session);
      console.log(`Deleted cart items for user: ${id}`);
      
      // 2. Xóa comments
      await Comment.deleteMany({ userId: id }).session(session);
      console.log(`Deleted comments for user: ${id}`);
      
      // 3. Xóa orders
      await Order.deleteMany({ userId: id }).session(session);
      console.log(`Deleted orders for user: ${id}`);
      
      // 4. Xóa user account
      await User.findByIdAndDelete(id).session(session);
      console.log(`Deleted user account: ${id}`);
      
      await session.commitTransaction();
      console.log('Account deletion transaction completed successfully');
      
      return res.status(200).json({ 
        message: 'Account and all associated data deleted successfully' 
      });
    } catch (error) {
      await session.abortTransaction();
      console.error('Transaction error:', error);
      throw error;
    } finally {
      session.endSession();
    }
  } catch (error) {
    console.error('Error deleting account:', error);
    return res.status(500).json({ 
      error: 'Error deleting account', 
      details: error.message 
    });
  }
});
// Route để xóa tất cả comments của user
router.delete('/:userId/comments', async (req, res) => {
  try {
    const { userId } = req.params;
    await Comment.deleteMany({ userId });
    res.status(200).json({ message: 'All user comments deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting comments', error: error.message });
  }
});

// Route để xóa tất cả orders của user
router.delete('/:userId/orders', async (req, res) => {
  try {
    const { userId } = req.params;
    await Order.deleteMany({ userId });
    res.status(200).json({ message: 'All user orders deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting orders', error: error.message });
  }
});

// Route để xóa tất cả cart items của user
router.delete('/:userId/cart', async (req, res) => {
  try {
    const { userId } = req.params;
    await CartItem.deleteMany({ userId });
    res.status(200).json({ message: 'All user cart items deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting cart items', error: error.message });
  }
});


module.exports = router;