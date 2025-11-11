const express = require('express');
const router = express.Router();
const Admin = require('../models/Admin');

// Admin login
router.post('/login', async (req, res) => {
  const { adminname, adminpass } = req.body;
  
  try {
    const admin = await Admin.findOne({ adminname });
    
    if (!admin || admin.adminpass !== adminpass) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    res.json({ message: 'Login successful', adminId: admin._id });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Get all admins
router.get('/', async (req, res) => {
  try {
    const admins = await Admin.find({}, { adminpass: 0 });
    res.json(admins);
  } catch (error) {
    console.error('Error fetching admins:', error);
    res.status(500).json({ error: 'Error fetching admins' });
  }
});

module.exports = router;