const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  clientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Client',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: [true, 'Product name is required'],
    trim: true,
    maxlength: [200, 'Product name cannot exceed 200 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  category: {
    type: String,
    required: [true, 'Category is required'],
    trim: true,
    maxlength: [100, 'Category cannot exceed 100 characters']
  },
  subcategory: {
    type: String,
    trim: true,
    maxlength: [100, 'Subcategory cannot exceed 100 characters']
  },
  brand: {
    type: String,
    trim: true,
    maxlength: [100, 'Brand cannot exceed 100 characters']
  },
  model: {
    type: String,
    trim: true,
    maxlength: [100, 'Model cannot exceed 100 characters']
  },
  sku: {
    type: String,
    required: [true, 'SKU is required'],
    trim: true,
    maxlength: [50, 'SKU cannot exceed 50 characters'],
    unique: true
  },
  costPrice: {
    type: Number,
    required: [true, 'Cost price is required'],
    min: [0, 'Cost price cannot be negative']
  },
  sellingPrice: {
    type: Number,
    required: [true, 'Selling price is required'],
    min: [0, 'Selling price cannot be negative']
  },
  wholesalePrice: {
    type: Number,
    required: [true, 'Wholesale price is required'],
    min: [0, 'Wholesale price cannot be negative']
  },
  stockQuantity: {
    type: Number,
    default: 0,
    min: [0, 'Stock quantity cannot be negative']
  },
  minStockLevel: {
    type: Number,
    default: 0,
    min: [0, 'Minimum stock level cannot be negative']
  },
  unit: {
    type: String,
    required: [true, 'Unit is required'],
    trim: true,
    maxlength: [20, 'Unit cannot exceed 20 characters']
  },
  imageUrl: {
    type: String,
    trim: true
  },
  specifications: {
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: {}
  },
  isActive: {
    type: Boolean,
    default: true
  },
  barcode: {
    type: String,
    trim: true,
    unique: true,
    sparse: true
  },
  weight: {
    type: Number,
    min: [0, 'Weight cannot be negative']
  },
  dimensions: {
    length: { type: Number, min: 0 },
    width: { type: Number, min: 0 },
    height: { type: Number, min: 0 }
  },
  supplier: {
    name: { type: String, trim: true },
    contact: { type: String, trim: true },
    email: { type: String, trim: true }
  },
  tags: [{
    type: String,
    trim: true
  }],
  reorderPoint: {
    type: Number,
    default: 0,
    min: [0, 'Reorder point cannot be negative']
  },
  reorderQuantity: {
    type: Number,
    default: 0,
    min: [0, 'Reorder quantity cannot be negative']
  },
  lastRestocked: {
    type: Date,
    default: null
  },
  totalSold: {
    type: Number,
    default: 0
  },
  totalRevenue: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for profit margin
productSchema.virtual('profitMargin').get(function() {
  return this.sellingPrice - this.costPrice;
});

// Virtual for profit margin percentage
productSchema.virtual('profitMarginPercentage').get(function() {
  return this.costPrice > 0 ? ((this.sellingPrice - this.costPrice) / this.costPrice) * 100 : 0;
});

// Virtual for low stock status
productSchema.virtual('isLowStock').get(function() {
  return this.stockQuantity <= this.minStockLevel;
});

// Virtual for out of stock status
productSchema.virtual('isOutOfStock').get(function() {
  return this.stockQuantity <= 0;
});

// Virtual for needs reorder status
productSchema.virtual('needsReorder').get(function() {
  return this.stockQuantity <= this.reorderPoint;
});

// Indexes for better query performance
productSchema.index({ clientId: 1, sku: 1 });
productSchema.index({ clientId: 1, category: 1 });
productSchema.index({ clientId: 1, brand: 1 });
productSchema.index({ clientId: 1, isActive: 1 });
productSchema.index({ clientId: 1, stockQuantity: 1 });
productSchema.index({ clientId: 1, createdAt: -1 });
productSchema.index({ barcode: 1 });

// Pre-save middleware to validate prices
productSchema.pre('save', function(next) {
  if (this.sellingPrice < this.costPrice) {
    return next(new Error('Selling price cannot be less than cost price'));
  }
  if (this.wholesalePrice < this.costPrice) {
    return next(new Error('Wholesale price cannot be less than cost price'));
  }
  next();
});

// Static method to find products by client
productSchema.statics.findByClient = function(clientId) {
  return this.find({ clientId, isActive: true });
};

// Static method to find low stock products
productSchema.statics.findLowStock = function(clientId) {
  return this.find({
    clientId,
    isActive: true,
    $expr: { $lte: ['$stockQuantity', '$minStockLevel'] }
  });
};

// Static method to find out of stock products
productSchema.statics.findOutOfStock = function(clientId) {
  return this.find({ clientId, isActive: true, stockQuantity: 0 });
};

// Static method to find products by category
productSchema.statics.findByCategory = function(clientId, category) {
  return this.find({ clientId, category, isActive: true });
};

// Static method to search products
productSchema.statics.search = function(clientId, searchTerm) {
  return this.find({
    clientId,
    isActive: true,
    $or: [
      { name: { $regex: searchTerm, $options: 'i' } },
      { sku: { $regex: searchTerm, $options: 'i' } },
      { brand: { $regex: searchTerm, $options: 'i' } },
      { category: { $regex: searchTerm, $options: 'i' } }
    ]
  });
};

module.exports = mongoose.model('Product', productSchema);
