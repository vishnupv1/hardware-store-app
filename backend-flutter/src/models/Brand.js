const mongoose = require('mongoose');

const brandSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Brand name is required'],
    trim: true,
    maxlength: [100, 'Brand name cannot exceed 100 characters'],
    minlength: [2, 'Brand name must be at least 2 characters']
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
  clientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Client',
    required: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true
});

// Compound index to ensure unique brand names per client
brandSchema.index({ name: 1, clientId: 1 }, { unique: true });

// Virtual for product count
brandSchema.virtual('productCount', {
  ref: 'Product',
  localField: '_id',
  foreignField: 'brandId',
  count: true
});

// Ensure virtual fields are serialized
brandSchema.set('toJSON', { virtuals: true });
brandSchema.set('toObject', { virtuals: true });

// Pre-save middleware to capitalize brand name
brandSchema.pre('save', function(next) {
  if (this.name) {
    this.name = this.name.charAt(0).toUpperCase() + this.name.slice(1).toLowerCase();
  }
  next();
});

module.exports = mongoose.model('Brand', brandSchema);
