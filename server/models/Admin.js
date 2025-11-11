const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
  adminname: { type: String, required: true, unique: true },
  adminpass: { type: String, required: true }
});

module.exports = mongoose.model('Admin', adminSchema);