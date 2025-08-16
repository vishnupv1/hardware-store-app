const mongoose = require('mongoose');

const saleItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true
  },
  productName: {
    type: String,
    required: true,
    trim: true
  },
  sku: {
    type: String,
    required: true,
    trim: true
  },
  quantity: {
    type: Number,
    required: true,
    min: [1, 'Quantity must be at least 1']
  },
  unitPrice: {
    type: Number,
    required: true,
    min: [0, 'Unit price cannot be negative']
  },
  totalPrice: {
    type: Number,
    required: true,
    min: [0, 'Total price cannot be negative']
  },
  discount: {
    type: Number,
    default: 0,
    min: [0, 'Discount cannot be negative']
  }
}, { _id: false });

const saleSchema = new mongoose.Schema({
  clientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Client',
    required: true,
    index: true
  },
  invoiceNumber: {
    type: String,
    required: [true, 'Invoice number is required'],
    unique: true,
    trim: true
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: true
  },
  customerName: {
    type: String,
    required: [true, 'Customer name is required'],
    trim: true
  },
  items: [saleItemSchema],
  subtotal: {
    type: Number,
    required: true,
    min: [0, 'Subtotal cannot be negative']
  },
  taxAmount: {
    type: Number,
    default: 0,
    min: [0, 'Tax amount cannot be negative']
  },
  discountAmount: {
    type: Number,
    default: 0,
    min: [0, 'Discount amount cannot be negative']
  },
  totalAmount: {
    type: Number,
    required: true,
    min: [0, 'Total amount cannot be negative']
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'bank_transfer', 'credit', 'upi', 'cheque'],
    required: [true, 'Payment method is required']
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'partial', 'failed'],
    default: 'pending'
  },
  saleStatus: {
    type: String,
    enum: ['completed', 'cancelled', 'returned', 'refunded'],
    default: 'completed'
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot exceed 500 characters']
  },
  createdBy: {
    type: String,
    required: [true, 'Created by is required'],
    trim: true
  },
  saleDate: {
    type: Date,
    default: Date.now
  },
  dueDate: {
    type: Date
  },
  taxRate: {
    type: Number,
    default: 0,
    min: [0, 'Tax rate cannot be negative']
  },
  shippingAddress: {
    street: { type: String, trim: true },
    city: { type: String, trim: true },
    state: { type: String, trim: true },
    pincode: { type: String, trim: true },
    country: { type: String, trim: true }
  },
  shippingCost: {
    type: Number,
    default: 0,
    min: [0, 'Shipping cost cannot be negative']
  },
  paymentDetails: {
    transactionId: { type: String, trim: true },
    cardLast4: { type: String, trim: true },
    bankName: { type: String, trim: true },
    chequeNumber: { type: String, trim: true }
  },
  refundAmount: {
    type: Number,
    default: 0,
    min: [0, 'Refund amount cannot be negative']
  },
  refundReason: {
    type: String,
    trim: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for total items count
saleSchema.virtual('totalItems').get(function() {
  return this.items.reduce((sum, item) => sum + item.quantity, 0);
});

// Virtual for final total (including shipping)
saleSchema.virtual('finalTotal').get(function() {
  return this.totalAmount + this.shippingCost;
});

// Virtual for paid amount
saleSchema.virtual('paidAmount').get(function() {
  if (this.paymentStatus === 'paid') return this.finalTotal;
  if (this.paymentStatus === 'partial') {
    // This would need to be calculated from payment history
    return 0;
  }
  return 0;
});

// Virtual for outstanding amount
saleSchema.virtual('outstandingAmount').get(function() {
  return this.finalTotal - this.paidAmount;
});

// Indexes for better query performance
saleSchema.index({ clientId: 1, invoiceNumber: 1 });
saleSchema.index({ clientId: 1, customerId: 1 });
saleSchema.index({ clientId: 1, saleDate: -1 });
saleSchema.index({ clientId: 1, paymentStatus: 1 });
saleSchema.index({ clientId: 1, saleStatus: 1 });
saleSchema.index({ clientId: 1, createdBy: 1 });
saleSchema.index({ invoiceNumber: 1 });

// Pre-save middleware to generate invoice number
saleSchema.pre('save', async function(next) {
  if (this.isNew && !this.invoiceNumber) {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    
    // Get count of sales for this month
    const count = await this.constructor.countDocuments({
      clientId: this.clientId,
      saleDate: {
        $gte: new Date(year, date.getMonth(), 1),
        $lt: new Date(year, date.getMonth() + 1, 1)
      }
    });
    
    this.invoiceNumber = `INV-${year}${month}-${String(count + 1).padStart(4, '0')}`;
  }
  next();
});

// Pre-save middleware to update customer stats
saleSchema.pre('save', async function(next) {
  if (this.isNew && this.saleStatus === 'completed') {
    const Customer = mongoose.model('Customer');
    await Customer.findByIdAndUpdate(this.customerId, {
      $inc: {
        totalPurchases: 1,
        totalSpent: this.finalTotal
      },
      lastPurchaseDate: this.saleDate
    });
  }
  next();
});

// Static method to find sales by client
saleSchema.statics.findByClient = function(clientId) {
  return this.find({ clientId }).populate('customerId', 'name email phoneNumber');
};

// Static method to find sales by customer
saleSchema.statics.findByCustomer = function(clientId, customerId) {
  return this.find({ clientId, customerId });
};

// Static method to find sales by date range
saleSchema.statics.findByDateRange = function(clientId, startDate, endDate) {
  return this.find({
    clientId,
    saleDate: {
      $gte: startDate,
      $lte: endDate
    }
  });
};

// Static method to find pending payments
saleSchema.statics.findPendingPayments = function(clientId) {
  return this.find({
    clientId,
    paymentStatus: { $in: ['pending', 'partial'] }
  });
};

// Static method to get sales summary
saleSchema.statics.getSalesSummary = async function(clientId, startDate, endDate) {
  const pipeline = [
    { $match: { clientId: clientId } },
    { $match: { saleDate: { $gte: startDate, $lte: endDate } } },
    { $match: { saleStatus: 'completed' } },
    {
      $group: {
        _id: null,
        totalSales: { $sum: 1 },
        totalRevenue: { $sum: '$totalAmount' },
        totalItems: { $sum: '$totalItems' },
        averageOrderValue: { $avg: '$totalAmount' }
      }
    }
  ];
  
  const result = await this.aggregate(pipeline);
  return result[0] || {
    totalSales: 0,
    totalRevenue: 0,
    totalItems: 0,
    averageOrderValue: 0
  };
};

module.exports = mongoose.model('Sale', saleSchema);
