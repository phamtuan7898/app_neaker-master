const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  items: [{
    productId: String,
    productName: String,
    price: String,
    quantity: Number,
    size: String,
    color: String,
    image: String
  }],
  totalAmount: { type: Number, required: true },
  orderDate: { type: Date, default: Date.now },
  status: { type: String, default: 'completed' },
  phone: { type: String, required: true },
  address: { type: String, required: true }
});

module.exports = mongoose.model('Order', orderSchema);