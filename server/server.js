require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const upload = require('./middleware/upload');

const connectDB = require('./config/database');
// Import routes
const userRoutes = require('./routes/userRoutes');
const productRoutes = require('./routes/productRoutes');
const cartRoutes = require('./routes/cartRoutes');
const commentRoutes = require('./routes/commentRoutes');
const adminRoutes = require('./routes/adminRoutes');
const orderRoutes = require('./routes/orderRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to database
connectDB();

// ========== CORS CONFIGURATION ==========
// CHO PHÉP TẤT CẢ TRONG DEVELOPMENT
app.use(cors({
  origin: true, // Cho phép tất cả origins
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
}));

// Xử lý preflight requests
app.options('*', cors());

// ========== REQUEST LOGGING MIDDLEWARE ==========
app.use((req, res, next) => {
  console.log('\n📥 ========== REQUEST ==========');
  console.log(`🕐 ${new Date().toISOString()}`);
  console.log(`🌐 ${req.method} ${req.url}`);
  console.log(`🔗 Origin: ${req.headers.origin || 'No Origin'}`);
  console.log(`📱 User-Agent: ${req.headers['user-agent']?.substring(0, 50)}...`);
  console.log(`📦 Body: ${JSON.stringify(req.body)}`);
  console.log('========================================');
  
  next();
});

// ========== BODY PARSER ==========
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// ========== STATIC FILES ==========
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ========== TEST ENDPOINTS ==========
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    serverTime: new Date().toISOString(),
    message: 'Server is running!',
    ip: getIPAddress(),
    port: PORT,
    env: process.env.NODE_ENV || 'development'
  });
});

app.get('/api/test-cors', (req, res) => {
  res.json({
    success: true,
    message: 'CORS test successful!',
    origin: req.headers.origin,
    timestamp: new Date().toISOString()
  });
});

app.post('/api/test-post', (req, res) => {
  console.log('📨 Test POST received:', req.body);
  res.json({
    success: true,
    message: 'POST test successful!',
    receivedData: req.body,
    timestamp: new Date().toISOString()
  });
});

// ========== ROUTES ==========
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/orders', orderRoutes);

// ========== UPLOAD ENDPOINT ==========
app.post('/api/uploads-images', upload.array('images', 5), async (req, res) => {
  try {
    const files = req.files;
    if (!files || files.length === 0) {
      return res.status(400).json({ success: false, error: 'No files uploaded' });
    }

    const imageUrls = files.map(file => 
      `${req.protocol}://${req.get('host')}/uploads/${file.filename}`
    );
    
    res.status(200).json({ success: true, imageUrls: imageUrls });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ success: false, error: 'Error uploading files' });
  }
});

// ========== ERROR HANDLING ==========
// 404 handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    error: `Route ${req.url} not found`,
    method: req.method,
    availableRoutes: [
      '/api/health',
      '/api/users/register',
      '/api/users/login',
      '/api/products',
      '/api/test-cors',
      '/api/test-post'
    ]
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('🚨 Server Error:', err);
  
  res.status(500).json({
    success: false,
    error: err.message || 'Internal server error',
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// ========== START SERVER ==========
app.listen(PORT, '0.0.0.0', () => {
  console.log(`========================================`);
  console.log(`🚀 Server is running in ${process.env.NODE_ENV || 'development'} mode`);
  console.log(`📍 Local: http://localhost:${PORT}`);
  console.log(`🌐 Network: http://${getIPAddress()}:${PORT}`);
  console.log(`🔗 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`🔗 CORS Test: http://localhost:${PORT}/api/test-cors`);
  console.log(`========================================`);
});

// ========== HELPER FUNCTIONS ==========
function getIPAddress() {
  const interfaces = require('os').networkInterfaces();
  for (const name in interfaces) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}