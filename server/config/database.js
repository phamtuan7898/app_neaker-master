require('dotenv').config(); // Thêm dòng này để đọc biến môi trường
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    // Lấy MongoDB URI từ biến môi trường
    const mongoURI = process.env.MONGODB_URI;
    
    // Kiểm tra xem URI có tồn tại không
    if (!mongoURI) {
      console.error('❌ MONGODB_URI is not defined in .env file');
      process.exit(1);
    }
    
    console.log('🔗 Attempting to connect to MongoDB...');
    
    // Kết nối với options đầy đủ
    await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000, // Timeout sau 5 giây
      socketTimeoutMS: 45000, // Socket timeout 45 giây
    });
    
    console.log('✅ Connected to MongoDB');
    console.log(`📁 Database: ${mongoose.connection.name}`);
    console.log(`🏠 Host: ${mongoose.connection.host}`);
    
  } catch (err) {
    console.error('❌ MongoDB connection error:', err.message);
    console.error('🔍 Error details:', {
      name: err.name,
      code: err.code
    });
    process.exit(1);
  }
};

// Xử lý sự kiện kết nối
mongoose.connection.on('error', err => {
  console.error('❌ MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('⚠️ MongoDB disconnected');
});

// Xử lý tín hiệu shutdown
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('📴 MongoDB connection closed through app termination');
  process.exit(0);
});

module.exports = connectDB;