const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Category name is required'],
    trim: true,
    maxlength: [100, 'Category name cannot exceed 100 characters'],
    unique: true
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot exceed 500 characters']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  productCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Index for better query performance
categorySchema.index({ name: 1 });
categorySchema.index({ isActive: 1 });
categorySchema.index({ createdBy: 1 });

module.exports = mongoose.model('Category', categorySchema);
