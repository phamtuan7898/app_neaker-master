const mongoose = require('mongoose');

const cartItemSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  productId: { type: String, required: true },
  productName: { type: String, required: true },
  price: { type: String, required: true },
  quantity: { type: Number, required: true, default: 1, min: 1 },
  size: { type: String, required: true },
  color: { type: String, required: true },
  image: { type: String, default: '' }
});

module.exports = mongoose.model('CartItem', cartItemSchema);