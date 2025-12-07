const mongoose = require('mongoose');

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

module.exports = mongoose.model('Product', productSchema, 'products');