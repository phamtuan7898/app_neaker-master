const express = require('express');
const router = express.Router();
const Product = require('../models/Product');

// Get all products
router.get('/', async (req, res) => {
  try {
    const products = await Product.find();
    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Error fetching products' });
  }
});

// Add new product
router.post('/', async (req, res) => {
  const { productName, shoeType, image, price, rating, description, color, size } = req.body;
  try {
    const newProduct = new Product({ productName, shoeType, image, price, rating, description, color, size });
    await newProduct.save();
    res.status(201).json(newProduct);
  } catch (error) {
    console.error('Error adding product:', error);
    res.status(500).json({ error: 'Error adding product' });
  }
});

// Update product
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { productName, shoeType, image, price, rating, description, color, size } = req.body;

  try {
    const updatedProduct = await Product.findByIdAndUpdate(
      id,
      { productName, shoeType, image, price, rating, description, color, size },
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

// Delete product
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await Product.findByIdAndDelete(id);
    res.status(200).json({ message: 'Product deleted successfully' });
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ error: 'Error deleting product' });
  }
});

module.exports = router;