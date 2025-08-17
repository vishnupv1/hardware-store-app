const express = require('express');
const { body, validationResult, query } = require('express-validator');
const { auth, authorize, requireAdmin, requirePermission } = require('../middleware/auth');
const Sale = require('../models/Sale');
const Product = require('../models/Product');
const Customer = require('../models/Customer');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);
router.use(authorize('client', 'admin', 'user', 'employee'));

// @route   GET /api/sales
// @desc    Get all sales with pagination and filters
// @access  Private
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('customerId').optional().isMongoId().withMessage('Invalid customer ID'),
  query('paymentStatus').optional().isIn(['pending', 'paid', 'partial', 'failed']).withMessage('Invalid payment status'),
  query('saleStatus').optional().isIn(['completed', 'cancelled', 'returned', 'refunded']).withMessage('Invalid sale status'),
  query('startDate').optional().isISO8601().withMessage('Invalid start date'),
  query('endDate').optional().isISO8601().withMessage('Invalid end date'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Build filter object based on user role
    let filter = {};
    
    // For clients, filter by their clientId
    if (req.user.role === 'client') {
      filter.clientId = req.user.id;
    }
    // For regular users, they can see sales associated with their account
    else if (req.user.role === 'user') {
      filter.clientId = req.user.id;
    }
    // Admins and employees can see all sales
    
    if (req.query.customerId) {
      filter.customerId = req.query.customerId;
    }

    if (req.query.paymentStatus) {
      filter.paymentStatus = req.query.paymentStatus;
    }

    if (req.query.saleStatus) {
      filter.saleStatus = req.query.saleStatus;
    }

    if (req.query.startDate || req.query.endDate) {
      filter.saleDate = {};
      if (req.query.startDate) {
        filter.saleDate.$gte = new Date(req.query.startDate);
      }
      if (req.query.endDate) {
        filter.saleDate.$lte = new Date(req.query.endDate);
      }
    }

    const sales = await Sale.find(filter)
      .populate('customerId', 'name email phoneNumber companyName')
      .sort({ saleDate: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Sale.countDocuments(filter);
    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: {
        sales,
        pagination: {
          page,
          limit,
          total,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      }
    });
  } catch (error) {
    console.error('Get sales error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/sales/:id
// @desc    Get sale by ID
// @access  Private
router.get('/:id', async (req, res) => {
  try {
    const sale = await Sale.findOne({
      _id: req.params.id,
      clientId: req.user.id
    }).populate('customerId', 'name email phoneNumber companyName address city state pincode');

    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found',
      });
    }

    res.json({
      success: true,
      data: { sale }
    });
  } catch (error) {
    console.error('Get sale error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/sales
// @desc    Create a new sale
// @access  Private
router.post('/', [
  body('customerId')
    .isMongoId()
    .withMessage('Valid customer ID is required'),
  body('items')
    .isArray({ min: 1 })
    .withMessage('At least one item is required'),
  body('items.*.productId')
    .isMongoId()
    .withMessage('Valid product ID is required for each item'),
  body('items.*.quantity')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1 for each item'),
  body('paymentMethod')
    .isIn(['cash', 'card', 'bank_transfer', 'credit', 'upi', 'cheque'])
    .withMessage('Invalid payment method'),
  body('paymentStatus')
    .optional()
    .isIn(['pending', 'paid', 'partial', 'failed'])
    .withMessage('Invalid payment status'),
  body('saleStatus')
    .optional()
    .isIn(['completed', 'cancelled', 'returned', 'refunded'])
    .withMessage('Invalid sale status'),
  body('taxAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Tax amount must be a non-negative number'),
  body('discountAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Discount amount must be a non-negative number'),
  body('shippingCost')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Shipping cost must be a non-negative number'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    // Validate customer exists
    const customer = await Customer.findOne({
      _id: req.body.customerId,
      clientId: req.user.id,
      isActive: true
    });

    if (!customer) {
      return res.status(400).json({
        success: false,
        message: 'Customer not found or inactive',
      });
    }

    // Validate products and calculate totals
    const items = [];
    let subtotal = 0;

    for (const item of req.body.items) {
      const product = await Product.findOne({
        _id: item.productId,
        clientId: req.user.id,
        isActive: true
      });

      if (!product) {
        return res.status(400).json({
          success: false,
          message: `Product with ID ${item.productId} not found or inactive`,
        });
      }

      if (product.stockQuantity < item.quantity) {
        return res.status(400).json({
          success: false,
          message: `Insufficient stock for product ${product.name}. Available: ${product.stockQuantity}`,
        });
      }

      const unitPrice = item.unitPrice || product.sellingPrice;
      const totalPrice = unitPrice * item.quantity;
      const discount = item.discount || 0;

      items.push({
        productId: product._id,
        productName: product.name,
        sku: product.sku,
        quantity: item.quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        discount: discount
      });

      subtotal += totalPrice - discount;
    }

    const taxAmount = req.body.taxAmount || 0;
    const discountAmount = req.body.discountAmount || 0;
    const shippingCost = req.body.shippingCost || 0;
    const totalAmount = subtotal + taxAmount - discountAmount + shippingCost;

    const saleData = {
      clientId: req.user.id,
      customerId: customer._id,
      customerName: customer.displayName,
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      paymentMethod: req.body.paymentMethod,
      paymentStatus: req.body.paymentStatus || 'pending',
      saleStatus: req.body.saleStatus || 'completed',
      notes: req.body.notes,
      createdBy: req.user.companyName || 'System',
      saleDate: req.body.saleDate || new Date(),
      shippingCost: shippingCost,
      shippingAddress: req.body.shippingAddress
    };

    const sale = new Sale(saleData);
    await sale.save();

    // Update product stock quantities
    for (const item of items) {
      await Product.findByIdAndUpdate(item.productId, {
        $inc: {
          stockQuantity: -item.quantity,
          totalSold: item.quantity,
          totalRevenue: item.totalPrice - item.discount
        }
      });
    }

    // Update customer stats
    await Customer.findByIdAndUpdate(customer._id, {
      $inc: {
        totalPurchases: 1,
        totalSpent: totalAmount
      },
      lastPurchaseDate: sale.saleDate
    });

    res.status(201).json({
      success: true,
      message: 'Sale created successfully',
      data: { sale }
    });
  } catch (error) {
    console.error('Create sale error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/sales/:id
// @desc    Update sale
// @access  Private
router.put('/:id', [
  body('paymentStatus')
    .optional()
    .isIn(['pending', 'paid', 'partial', 'failed'])
    .withMessage('Invalid payment status'),
  body('saleStatus')
    .optional()
    .isIn(['completed', 'cancelled', 'returned', 'refunded'])
    .withMessage('Invalid sale status'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters'),
  body('refundAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Refund amount must be a non-negative number'),
  body('refundReason')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Refund reason cannot exceed 200 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const sale = await Sale.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found',
      });
    }

    // Update sale
    Object.keys(req.body).forEach(key => {
      if (req.body[key] !== undefined) {
        sale[key] = req.body[key];
      }
    });

    await sale.save();

    res.json({
      success: true,
      message: 'Sale updated successfully',
      data: { sale }
    });
  } catch (error) {
    console.error('Update sale error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/sales/:id
// @desc    Cancel sale (soft delete)
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const sale = await Sale.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found',
      });
    }

    if (sale.saleStatus === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Sale is already cancelled',
      });
    }

    // Cancel the sale
    sale.saleStatus = 'cancelled';
    await sale.save();

    // Restore product stock quantities
    for (const item of sale.items) {
      await Product.findByIdAndUpdate(item.productId, {
        $inc: {
          stockQuantity: item.quantity,
          totalSold: -item.quantity,
          totalRevenue: -(item.totalPrice - item.discount)
        }
      });
    }

    // Update customer stats
    await Customer.findByIdAndUpdate(sale.customerId, {
      $inc: {
        totalPurchases: -1,
        totalSpent: -sale.totalAmount
      }
    });

    res.json({
      success: true,
      message: 'Sale cancelled successfully'
    });
  } catch (error) {
    console.error('Cancel sale error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/sales/:id/return
// @desc    Return sale items
// @access  Private
router.post('/:id/return', [
  body('items')
    .isArray({ min: 1 })
    .withMessage('At least one item is required for return'),
  body('items.*.productId')
    .isMongoId()
    .withMessage('Valid product ID is required for each item'),
  body('items.*.quantity')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1 for each item'),
  body('refundAmount')
    .isFloat({ min: 0 })
    .withMessage('Refund amount must be a non-negative number'),
  body('refundReason')
    .trim()
    .isLength({ min: 1, max: 200 })
    .withMessage('Refund reason must be between 1 and 200 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const sale = await Sale.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found',
      });
    }

    if (sale.saleStatus === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Cannot return a cancelled sale',
      });
    }

    // Validate return items
    for (const returnItem of req.body.items) {
      const saleItem = sale.items.find(item => item.productId.toString() === returnItem.productId);
      
      if (!saleItem) {
        return res.status(400).json({
          success: false,
          message: `Product ${returnItem.productId} not found in this sale`,
        });
      }

      if (returnItem.quantity > saleItem.quantity) {
        return res.status(400).json({
          success: false,
          message: `Return quantity cannot exceed sold quantity for product ${saleItem.productName}`,
        });
      }
    }

    // Update sale status and refund info
    sale.saleStatus = 'returned';
    sale.refundAmount = req.body.refundAmount;
    sale.refundReason = req.body.refundReason;
    await sale.save();

    // Restore product stock for returned items
    for (const returnItem of req.body.items) {
      await Product.findByIdAndUpdate(returnItem.productId, {
        $inc: {
          stockQuantity: returnItem.quantity,
          totalSold: -returnItem.quantity
        }
      });
    }

    res.json({
      success: true,
      message: 'Sale returned successfully',
      data: { sale }
    });
  } catch (error) {
    console.error('Return sale error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/sales/stats/summary
// @desc    Get sales statistics summary
// @access  Private
router.get('/stats/summary', async (req, res) => {
  try {
    const startDate = req.query.startDate ? new Date(req.query.startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
    const endDate = req.query.endDate ? new Date(req.query.endDate) : new Date();

    const summary = await Sale.getSalesSummary(req.user.id, startDate, endDate);

    res.json({
      success: true,
      data: summary
    });
  } catch (error) {
    console.error('Get sales stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/sales/pending-payments
// @desc    Get sales with pending payments
// @access  Private
router.get('/pending-payments', async (req, res) => {
  try {
    const sales = await Sale.findPendingPayments(req.user.id)
      .populate('customerId', 'name email phoneNumber')
      .sort({ saleDate: -1 })
      .limit(20);

    res.json({
      success: true,
      data: { sales }
    });
  } catch (error) {
    console.error('Get pending payments error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/sales/customer/:customerId
// @desc    Get sales by customer
// @access  Private
router.get('/customer/:customerId', async (req, res) => {
  try {
    const sales = await Sale.findByCustomer(req.user.id, req.params.customerId)
      .sort({ saleDate: -1 })
      .limit(50);

    res.json({
      success: true,
      data: { sales }
    });
  } catch (error) {
    console.error('Get customer sales error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
