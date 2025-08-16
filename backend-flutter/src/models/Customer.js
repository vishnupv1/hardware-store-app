const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
  clientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Client',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: [true, 'Customer name is required'],
    trim: true,
    maxlength: [100, 'Customer name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    lowercase: true,
    trim: true,
    match: [
      /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
      'Please enter a valid email address'
    ]
  },
  phoneNumber: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    match: [
      /^\+?[\d\s\-\(\)]+$/,
      'Please enter a valid phone number'
    ]
  },
  companyName: {
    type: String,
    trim: true,
    maxlength: [100, 'Company name cannot exceed 100 characters']
  },
  gstNumber: {
    type: String,
    trim: true,
    maxlength: [15, 'GST number cannot exceed 15 characters']
  },
  address: {
    type: String,
    trim: true,
    maxlength: [200, 'Address cannot exceed 200 characters']
  },
  city: {
    type: String,
    trim: true,
    maxlength: [50, 'City cannot exceed 50 characters']
  },
  state: {
    type: String,
    trim: true,
    maxlength: [50, 'State cannot exceed 50 characters']
  },
  pincode: {
    type: String,
    trim: true,
    maxlength: [10, 'Pincode cannot exceed 10 characters']
  },
  customerType: {
    type: String,
    enum: ['wholesale', 'retail', 'contractor'],
    default: 'retail'
  },
  creditLimit: {
    type: Number,
    default: 0,
    min: [0, 'Credit limit cannot be negative']
  },
  currentBalance: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot exceed 500 characters']
  },
  tags: [{
    type: String,
    trim: true
  }],
  lastPurchaseDate: {
    type: Date,
    default: null
  },
  totalPurchases: {
    type: Number,
    default: 0
  },
  totalSpent: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for display name
customerSchema.virtual('displayName').get(function() {
  return this.companyName || this.name;
});

// Virtual for available credit
customerSchema.virtual('availableCredit').get(function() {
  return this.creditLimit - this.currentBalance;
});

// Virtual for over credit limit status
customerSchema.virtual('isOverCreditLimit').get(function() {
  return this.currentBalance > this.creditLimit;
});

// Indexes for better query performance
customerSchema.index({ clientId: 1, email: 1 });
customerSchema.index({ clientId: 1, phoneNumber: 1 });
customerSchema.index({ clientId: 1, customerType: 1 });
customerSchema.index({ clientId: 1, isActive: 1 });
customerSchema.index({ clientId: 1, createdAt: -1 });

// Pre-save middleware to update last purchase date
customerSchema.pre('save', function(next) {
  if (this.isModified('totalPurchases') && this.totalPurchases > 0) {
    this.lastPurchaseDate = new Date();
  }
  next();
});

// Static method to find customers by client
customerSchema.statics.findByClient = function(clientId) {
  return this.find({ clientId, isActive: true });
};

// Static method to find customers by type
customerSchema.statics.findByType = function(clientId, customerType) {
  return this.find({ clientId, customerType, isActive: true });
};

// Static method to find customers with low credit
customerSchema.statics.findLowCredit = function(clientId) {
  return this.find({
    clientId,
    isActive: true,
    $expr: { $gte: ['$currentBalance', '$creditLimit'] }
  });
};

module.exports = mongoose.model('Customer', customerSchema);
