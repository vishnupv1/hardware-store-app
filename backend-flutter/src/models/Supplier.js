const mongoose = require('mongoose');

const supplierSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Supplier name is required'],
    trim: true,
    maxlength: [100, 'Supplier name cannot exceed 100 characters']
  },
  contactPerson: {
    name: {
      type: String,
      trim: true,
      maxlength: [100, 'Contact person name cannot exceed 100 characters']
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        'Please enter a valid email address'
      ]
    },
    phone: {
      type: String,
      trim: true,
      match: [
        /^\+?[\d\s\-\(\)]+$/,
        'Please enter a valid phone number'
      ]
    }
  },
  address: {
    street: {
      type: String,
      trim: true,
      maxlength: [200, 'Street address cannot exceed 200 characters']
    },
    city: {
      type: String,
      trim: true,
      maxlength: [100, 'City cannot exceed 100 characters']
    },
    state: {
      type: String,
      trim: true,
      maxlength: [100, 'State cannot exceed 100 characters']
    },
    zipCode: {
      type: String,
      trim: true,
      maxlength: [20, 'Zip code cannot exceed 20 characters']
    },
    country: {
      type: String,
      trim: true,
      maxlength: [100, 'Country cannot exceed 100 characters']
    }
  },
  businessInfo: {
    website: {
      type: String,
      trim: true,
      match: [
        /^https?:\/\/.+/,
        'Please enter a valid website URL'
      ]
    },
    taxId: {
      type: String,
      trim: true,
      maxlength: [50, 'Tax ID cannot exceed 50 characters']
    },
    paymentTerms: {
      type: String,
      trim: true,
      maxlength: [100, 'Payment terms cannot exceed 100 characters']
    }
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
supplierSchema.index({ name: 1 });
supplierSchema.index({ isActive: 1 });
supplierSchema.index({ createdBy: 1 });
supplierSchema.index({ 'contactPerson.email': 1 });

module.exports = mongoose.model('Supplier', supplierSchema);
