const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const CartItem = require('../models/CartItem');
const User = require('../models/User');
const mongoose = require('mongoose');

// Process payment and create order - FIXED VERSION
router.post('/process-payment/:userId', async (req, res) => {
  const { userId } = req.params;
  const { items, totalAmount, phone, address } = req.body;
  
  if (!phone || phone.trim().length < 10) {
    return res.status(400).json({ success: false, error: 'Invalid phone number' });
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // 1. Tạo order mới
    const newOrder = new Order({
      userId,
      items: items.map(item => ({
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
        size: item.size,
        color: item.color,
        image: item.image
      })),
      totalAmount,
      phone,
      address
    });
    await newOrder.save({ session });

    // 2. SỬA: Chỉ xóa các sản phẩm ĐÃ THANH TOÁN
    const paidProductIds = items.map(item => item.productId);
    await CartItem.deleteMany({ 
      userId: userId, 
      productId: { $in: paidProductIds } // CHỈ xóa sản phẩm trong đơn hàng
    }, { session });

    await session.commitTransaction();
    
    res.status(200).json({ 
      success: true, 
      message: 'Payment processed successfully',
      orderId: newOrder._id 
    });
  } catch (error) {
    await session.abortTransaction();
    console.error('Payment processing error:', error);
    res.status(500).json({ success: false, error: 'Payment processing failed' });
  } finally {
    session.endSession();
  }
});

// Process single item payment - NEW ROUTE
router.post('/process-single-payment/:userId', async (req, res) => {
  const { userId } = req.params;
  const { item, totalAmount, phone, address } = req.body;
  
  if (!phone || phone.trim().length < 10) {
    return res.status(400).json({ success: false, error: 'Invalid phone number' });
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // 1. Tạo order mới với chỉ 1 sản phẩm
    const newOrder = new Order({
      userId,
      items: [{
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
        size: item.size,
        color: item.color,
        image: item.image
      }],
      totalAmount,
      phone,
      address
    });
    await newOrder.save({ session });

    // 2. Chỉ xóa sản phẩm đã thanh toán
    await CartItem.deleteOne({ 
      userId: userId, 
      productId: item.productId 
    }, { session });

    await session.commitTransaction();
    
    res.status(200).json({ 
      success: true, 
      message: 'Single item payment processed successfully',
      orderId: newOrder._id 
    });
  } catch (error) {
    await session.abortTransaction();
    console.error('Single item payment processing error:', error);
    res.status(500).json({ success: false, error: 'Single item payment processing failed' });
  } finally {
    session.endSession();
  }
});

// Get user orders
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    const orders = await Order.find({ userId }).sort({ orderDate: -1 });
    res.json(orders);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ error: 'Error fetching orders' });
  }
});

// Get order details
router.get('/:userId/:orderId', async (req, res) => {
  const { userId, orderId } = req.params;
  
  try {
    const order = await Order.findOne({ _id: orderId, userId: userId });
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    res.json(order);
  } catch (error) {
    console.error('Error fetching order details:', error);
    res.status(500).json({ error: 'Error fetching order details' });
  }
});

// Check user address
router.get('/check-address/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({ 
      hasAddress: !!user.address,
      currentAddress: user.address,
      currentPhone: user.phone
    });
  } catch (error) {
    console.error('Error checking address:', error);
    res.status(500).json({ error: 'Error checking address status' });
  }
});

// Update user address
router.put('/update-address/:userId', async (req, res) => {
  const { userId } = req.params;
  const { address, phone } = req.body;

  try {
    const user = await User.findByIdAndUpdate(
      userId,
      { address, phone },
      { new: true }
    );

    if (!user) return res.status(404).json({ error: 'User not found' });
    
    res.json({ 
      success: true, 
      address: user.address,
      phone: user.phone
    });
  } catch (error) {
    console.error('Error updating address and phone:', error);
    res.status(500).json({ error: 'Error updating address and phone' });
  }
});

module.exports = router;