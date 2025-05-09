const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const multer = require('multer');
const nodemailer = require('nodemailer');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5002;
const upload = multer({ dest: 'uploads/' });

app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Connect to MongoDB
mongoose.connect('mongodb+srv://haydygame:24HqXHnUuyIMvJJo@cluster0.bpo9e.mongodb.net/')
  .then(() => {
    console.log('Connected to MongoDB');
  }).catch((err) => {
    console.error('MongoDB connection error:', err);
});

// User Schema
const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  password: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  img: { type: String, default: '' },
  phone: { type: String, default: '' },
  address: { type: String, default: '' },
});

// Product Schema
const productSchema = new mongoose.Schema({
  productName: { type: String, required: true },
  shoeType: { type: String, required: true },
  image: [String],
  price: { type: String, required: true },
  rating: { type: Number, required: true },
  description: { type: String, required: true },
  color: [String],
  size: [String],
});

// Cart Schema
const cartItemSchema = new mongoose.Schema({
  userId: { 
    type: String,
    required: true 
  },
  productId: { 
    type: String, 
    required: true 
  },
  productName: { 
    type: String, 
    required: true 
  },
  price: { 
    type: String, 
    required: true 
  },
  quantity: { 
    type: Number, 
    required: true,
    default: 1,
    min: 1
  },
  size: {      
    type: String,
    required: true
  },
  color: {     
    type: String,
    required: true
  },
  image: { // Thêm trường image
    type: String,
    default: ''
  }
});

// Comment Schema
const commentSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  userId: { type: String, required: true },
  username: { type: String, required: true },
  comment: { type: String, required: true },
  rating: { type: Number, required: true, min: 1, max: 5 },
  createdAt: { type: Date, default: Date.now }
});

// Admin Schema
const adminSchema = new mongoose.Schema({
  adminname: { 
    type: String, 
    required: true,
    unique: true
  },
  adminpass: { 
    type: String, 
    required: true 
  }
});

// Order Schema
const orderSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  items: [{
    productId: String,
    productName: String,
    price: String,
    quantity: Number,
    size: String,
    color: String,
    image: String // Thêm trường image
  }],
  totalAmount: { type: Number, required: true },
  orderDate: { type: Date, default: Date.now },
  status: { type: String, default: 'completed' },
  phone: { type: String, required: true },
  address: { type: String, required: true }
});

const Order = mongoose.model('Order', orderSchema);
const Admin = mongoose.model('Admin', adminSchema);
const CartItem = mongoose.model('CartItem', cartItemSchema);
const Product = mongoose.model('Product', productSchema);
const User = mongoose.model('User', userSchema);
const Comment = mongoose.model('Comment', commentSchema);

// Process payment and create order endpoint
app.post('/process-payment/:userId', async (req, res) => {
  const { userId } = req.params;
  const { items, totalAmount, phone, address } = req.body;
  
  if (!phone || phone.trim().length < 10) {
    return res.status(400).json({
      success: false,
      error: 'Invalid phone number'
    });
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const newOrder = new Order({
      userId,
      items: items.map(item => ({
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
        size: item.size,
        color: item.color,
        image: item.image // Lưu trường image
      })),
      totalAmount,
      phone,
      address
    });
    await newOrder.save({ session });

    await CartItem.deleteMany({ userId }, { session });

    await session.commitTransaction();
    res.status(200).json({ 
      success: true, 
      message: 'Payment processed successfully',
      orderId: newOrder._id 
    });
  } catch (error) {
    await session.abortTransaction();
    console.error('Payment processing error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Payment processing failed' 
    });
  } finally {
    session.endSession();
  }
});

// Get all orders for a user
app.get('/orders/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    const orders = await Order.find({ userId })
      .sort({ orderDate: -1 });
    
    res.json(orders);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ error: 'Error fetching orders' });
  }
});

// Get single order details
app.get('/orders/:userId/:orderId', async (req, res) => {
  const { userId, orderId } = req.params;
  
  try {
    const order = await Order.findOne({
      _id: orderId,
      userId: userId
    });
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    res.json(order);
  } catch (error) {
    console.error('Error fetching order details:', error);
    res.status(500).json({ error: 'Error fetching order details' });
  }
});

// Check if user has address
app.get('/check-address/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    console.log('User address and phone:', user.address, user.phone);
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
app.put('/update-address/:userId', async (req, res) => {
  const { userId } = req.params;
  const { address, phone } = req.body;

  try {
    const user = await User.findByIdAndUpdate(
      userId,
      { address, phone },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    console.log('Updated user address and phone:', user);
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

// Admin login
app.post('/admin/login', async (req, res) => {
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
app.get('/admin', async (req, res) => {
  try {
    const admins = await Admin.find({}, { adminpass: 0 });
    res.json(admins);
  } catch (error) {
    console.error('Error fetching admins:', error);
    res.status(500).json({ error: 'Error fetching admins' });
  }
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Not an image! Please upload only images.'), false);
  }
};

const uploads = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024
  }
});

app.post('/uploads-images', upload.array('images', 5), async (req, res) => {
  try {
    const files = req.files;
    if (!files || files.length === 0) {
      return res.status(400).json({ 
        success: false,
        error: 'No files uploaded' 
      });
    }

    const imageUrls = files.map(file => 
      `${req.protocol}://${req.get('host')}/uploads/${file.filename}`
    );
    
    res.status(200).json({
      success: true,
      imageUrls: imageUrls
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Error uploading files'
    });
  }
});

// Register User
app.post('/register', async (req, res) => {
  const { username, password, email } = req.body;
  const img = req.body.img || '';
  const phone = req.body.phone || '';
  const address = req.body.address || '';

  console.log("Received data:", req.body);
  try {
    const newUser = new User({ username, password, email, img, phone, address });
    await newUser.save();
    res.status(201).json(newUser);
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ error: 'Error registering user' });
  }
});

// Endpoint for uploading user profile images
app.post('/User/:id/upload-image', upload.single('image'), async (req, res) => {
  const { id } = req.params;
  try {
    const user = await User.findById(id);
    if (user) {
      user.img = req.file.path;
      await user.save();
      console.log("Updated user data:", user);
      res.status(200).json(user);
    } else {
      res.status(404).json({ message: 'User not found' });
    }
    
  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).json({ error: 'Error uploading image' });
  }
});

// User Login
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const user = await User.findOne({
      $or: [{ username: username }, { email: username }],
    });

    console.log("User found:", user);
    if (!user || user.password !== password) {
      console.log("Invalid credentials");
      return res.status(400).json({ error: 'Invalid username or password' });
    }

    res.json(user);
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

app.post('/check-user', async (req, res) => {
  const { emailOrUsername } = req.body;
  
  try {
    const user = await User.findOne({
      $or: [
        { email: emailOrUsername },
        { username: emailOrUsername }
      ]
    });
    
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'No account found with this information' 
      });
    }

    res.json({ 
      success: true,
      userId: user._id,
      message: 'Valid account' 
    });

  } catch (error) {
    console.error('Error checking user:', error);
    res.status(500).json({ 
      success: false,
      message: 'An error occurred while checking account' 
    });
  }
});

// Forgot Password (send reset email)
app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'No user found with this email' 
      });
    }

    let transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: {
        user: 'your-actual-email@gmail.com',
        pass: 'your-app-password'
      },
    });

    const resetLink = `http://your-domain.com/reset-password/${user._id}`;

    let mailOptions = {
      from: 'your-actual-email@gmail.com',
      to: email,
      subject: 'Password reset request',
      html: `
        <h2>Password reset request</h2>
        <p>You have requested a password reset for your account.</p>
        <p>Please click the link below to reset your password:</p>
        <a href="${resetLink}">Reset Password</a>
        <p>This link will expire in 1 hour.</p>
        <p>If you did not request a password reset, please ignore this email.</p>
      `
    };

    await transporter.sendMail(mailOptions);
    
    res.json({ 
      success: true,
      message: 'Password reset email has been sent' 
    });

  } catch (error) {
    console.error('Error handling forgotten password:', error);
    res.status(500).json({ 
      success: false,
      message: 'An error occurred while processing the request.' 
    });
  }
});

app.post('/reset-password', async (req, res) => {
  const { userId, newPassword } = req.body;
  
  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'User not found' 
      });
    }

    user.password = newPassword;
    await user.save();

    res.json({ 
      success: true,
      message: 'Password updated successfully' 
    });

  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({ 
      success: false,
      message: 'An error occurred while resetting password.' 
    });
  }
});

// Get user profile by ID
app.get('/User/:id', async (req, res) => {
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
app.put('/User/:id', async (req, res) => {
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

app.put('/User/:userId/change-password', async (req, res) => {
  const { userId } = req.params;
  const { oldPassword, newPassword } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).send('User not found');
    }

    if (user.password !== oldPassword) {
      return res.status(401).send('Old password is incorrect');
    }

    user.password = newPassword;
    await user.save();

    return res.status(200).send('Password updated successfully');
  } catch (error) {
    console.error('Error changing password:', error);
    return res.status(500).send('Internal server error');
  }
});

// Delete account route
app.delete('/User/:id/delete-account', async (req, res) => {
  const { id } = req.params;
  const { password } = req.body;

  try {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const user = await User.findById(id).session(session);
      if (!user || user.password !== password) {
        await session.abortTransaction();
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      await CartItem.deleteMany({ userId: id }).session(session);
      await User.findByIdAndDelete(id).session(session);

      await session.commitTransaction();
      return res.status(200).json({ message: 'Account deleted successfully' });

    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  } catch (error) {
    console.error('Error deleting account:', error);
    return res.status(500).json({ error: 'Error deleting account' });
  }
});

// Add new product
app.post('/products', async (req, res) => {
  const { productName, shoeType, image, price, rating, description, color, size } = req.body;
  try {
    const newProduct = new Product({ 
      productName, 
      shoeType, 
      image,
      price, 
      rating, 
      description, 
      color,
      size
    });
    await newProduct.save();
    res.status(201).json(newProduct);
  } catch (error) {
    console.error('Error adding product:', error);
    res.status(500).json({ error: 'Error adding product' });
  }
});

// Get list of products
app.get('/products', async (req, res) => {
  try {
    const products = await Product.find();
    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Error fetching products' });
  }
});

app.delete('/products/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await Product.findByIdAndDelete(id);
    res.status(200).json({ message: 'Product has been deleted successfully' });
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ error: 'Error deleting product' });
  }
});

app.put('/product/update/:id', async (req, res) => {
  const { id } = req.params;
  const { 
    productName, 
    shoeType, 
    image, 
    price, 
    rating, 
    description, 
    color, 
    size 
  } = req.body;

  try {
    const updatedProduct = await Product.findByIdAndUpdate(
      id,
      {
        productName,
        shoeType,
        image,
        price,
        rating,
        description,
        color,
        size
      },
      { new: true }
    );

    if (!updatedProduct) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.status(200).json(updatedProduct);
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(500).json({ error: 'Error updating product' });
  }
});

// Add new cart item
app.post('/cart', async (req, res) => {
  const { userId, productId, productName, price, quantity, size, color, image } = req.body;
  
  try {
    // Check if item with the same product, size, and color already exists
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
      // Create new cart item with image
      const newCartItem = new CartItem({
        userId,
        productId,
        productName,
        price,
        quantity,
        size,
        color,
        image // Lưu trường image
      });
      await newCartItem.save();
      res.status(201).json(newCartItem);
    }
  } catch (error) {
    console.error('Error adding cart item:', error);
    res.status(500).json({ error: 'Error adding cart item' });
  }
});

// Get list of cart items
app.get('/cart/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    const cartItems = await CartItem.find({ userId: userId });
    res.json(cartItems);
  } catch (error) {
    console.error('Error fetching cart items:', error);
    res.status(500).json({ error: 'Error fetching cart items' });
  }
});

// Delete cart item
app.delete('/cart/:userId/:productId', async (req, res) => {
  const { userId, productId } = req.params;
  
  try {
    const result = await CartItem.findOneAndDelete({
      userId: userId,
      productId: productId
    });
    
    if (!result) {
      return res.status(404).json({ message: 'Cart item not found' });
    }
    
    res.json({ message: 'Cart item deleted successfully' });
  } catch (error) {
    console.error('Error deleting cart item:', error);
    res.status(500).json({ error: 'Error deleting cart item' });
  }
});

// Update cart item quantity
app.put('/cart/:userId/:productId', async (req, res) => {
  const { userId, productId } = req.params;
  const { quantity } = req.body;
  
  if (!quantity || quantity < 1) {
    return res.status(400).json({ message: 'Invalid quantity value' });
  }

  try {
    console.log(`Updating cart item: userId=${userId}, productId=${productId}, quantity=${quantity}`);
    
    const updatedItem = await CartItem.findOneAndUpdate(
      { 
        userId: userId.toString(),
        productId: productId.toString()
      },
      { quantity: quantity },
      { new: true }
    );
    
    if (!updatedItem) {
      console.log('Cart item not found with:', { userId, productId });
      return res.status(404).json({ 
        message: 'Cart item not found',
        details: { userId, productId }
      });
    }
    
    console.log('Successfully updated cart item:', updatedItem);
    res.json(updatedItem);
  } catch (error) {
    console.error('Error updating cart item:', error);
    res.status(500).json({ 
      error: 'Error updating cart item',
      details: error.message 
    });
  }
});

// Thêm bình luận mới
app.post('/comments', async (req, res) => {
  const { productId, userId, username, comment, rating } = req.body;
  
  try {
    const newComment = new Comment({
      productId,
      userId,
      username,
      comment,
      rating
    });
    
    await newComment.save();
    
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

// Lấy bình luận theo productId
app.get('/comments/:productId', async (req, res) => {
  const { productId } = req.params;
  
  try {
    const comments = await Comment.find({ productId })
                                 .sort({ createdAt: -1 });
    res.json(comments);
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ error: 'Error fetching comments' });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});