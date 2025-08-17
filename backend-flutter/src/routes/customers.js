const express = require('express');
const { body, validationResult, query } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Customer = require('../models/Customer');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);
router.use(authorize('client', 'admin', 'user'));

// @route   GET /api/customers
// @desc    Get all customers with pagination and filters
// @access  Private
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('search').optional().trim(),
  query('customerType').optional().isIn(['wholesale', 'retail', 'contractor']).withMessage('Invalid customer type'),
  query('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
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

    // Build filter object
    const filter = { clientId: req.user.id };
    
    if (req.query.search) {
      filter.$or = [
        { name: { $regex: req.query.search, $options: 'i' } },
        { email: { $regex: req.query.search, $options: 'i' } },
        { phoneNumber: { $regex: req.query.search, $options: 'i' } },
        { companyName: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    if (req.query.customerType) {
      filter.customerType = req.query.customerType;
    }

    if (req.query.isActive !== undefined) {
      filter.isActive = req.query.isActive === 'true';
    }

    // Check if forDropdown parameter is present
    if (req.query.forDropdown === 'true') {
      const customers = await Customer.find(filter)
        .select('_id name email phoneNumber companyName address city state pincode')
        .sort({ name: 1 });
      
      res.json({
        success: true,
        data: customers
      });
    } else {
      const customers = await Customer.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);

      const total = await Customer.countDocuments(filter);
      const totalPages = Math.ceil(total / limit);

      res.json({
        success: true,
        data: {
          customers,
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
    }
  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/customers/:id
// @desc    Get customer by ID
// @access  Private
router.get('/:id', async (req, res) => {
  try {
    const customer = await Customer.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });



    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    res.json({
      success: true,
      data: { customer }
    });
  } catch (error) {
    console.error('Get customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/customers
// @desc    Create a new customer
// @access  Private
router.post('/', [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email address'),
  body('phoneNumber')
    .trim()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
  body('companyName')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Company name cannot exceed 100 characters'),
  body('gstNumber')
    .optional()
    .trim()
    .isLength({ max: 15 })
    .withMessage('GST number cannot exceed 15 characters'),
  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Address cannot exceed 200 characters'),
  body('city')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('City cannot exceed 50 characters'),
  body('state')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('State cannot exceed 50 characters'),
  body('pincode')
    .optional()
    .trim()
    .isLength({ max: 10 })
    .withMessage('Pincode cannot exceed 10 characters'),
  body('customerType')
    .optional()
    .isIn(['wholesale', 'retail', 'contractor'])
    .withMessage('Invalid customer type'),
  body('creditLimit')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Credit limit must be a positive number'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters'),
  body('tags')
    .optional()
    .isArray()
    .withMessage('Tags must be an array'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    // Check if email already exists for this client
    const existingCustomer = await Customer.findOne({
      clientId: req.user.id,
      email: req.body.email
    });

    if (existingCustomer) {
      return res.status(400).json({
        success: false,
        message: 'Customer with this email already exists',
      });
    }

    const customerData = {
      ...req.body,
      clientId: req.user.id
    };

    const customer = new Customer(customerData);
    await customer.save();

    res.status(201).json({
      success: true,
      message: 'Customer created successfully',
      data: { customer }
    });
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/customers/:id
// @desc    Update customer
// @access  Private
router.put('/:id', [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('email')
    .optional()
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email address'),
  body('phoneNumber')
    .optional()
    .trim()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
  body('companyName')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Company name cannot exceed 100 characters'),
  body('gstNumber')
    .optional()
    .trim()
    .isLength({ max: 15 })
    .withMessage('GST number cannot exceed 15 characters'),
  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Address cannot exceed 200 characters'),
  body('city')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('City cannot exceed 50 characters'),
  body('state')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('State cannot exceed 50 characters'),
  body('pincode')
    .optional()
    .trim()
    .isLength({ max: 10 })
    .withMessage('Pincode cannot exceed 10 characters'),
  body('customerType')
    .optional()
    .isIn(['wholesale', 'retail', 'contractor'])
    .withMessage('Invalid customer type'),
  body('creditLimit')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Credit limit must be a positive number'),
  body('currentBalance')
    .optional()
    .isFloat()
    .withMessage('Current balance must be a number'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters'),
  body('tags')
    .optional()
    .isArray()
    .withMessage('Tags must be an array'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const customer = await Customer.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    // Check if email is being updated and if it already exists
    if (req.body.email && req.body.email !== customer.email) {
      const existingCustomer = await Customer.findOne({
        clientId: req.user.id,
        email: req.body.email,
        _id: { $ne: req.params.id }
      });

      if (existingCustomer) {
        return res.status(400).json({
          success: false,
          message: 'Customer with this email already exists',
        });
      }
    }

    // Update customer
    Object.keys(req.body).forEach(key => {
      if (req.body[key] !== undefined) {
        customer[key] = req.body[key];
      }
    });

    await customer.save();

    res.json({
      success: true,
      message: 'Customer updated successfully',
      data: { customer }
    });
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/customers/:id
// @desc    Delete customer (soft delete)
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const customer = await Customer.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    // Soft delete - set isActive to false
    customer.isActive = false;
    await customer.save();

    res.json({
      success: true,
      message: 'Customer deleted successfully'
    });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/customers/stats/summary
// @desc    Get customer statistics summary
// @access  Private
router.get('/stats/summary', async (req, res) => {
  try {
    const pipeline = [
      { $match: { clientId: req.user.id } },
      {
        $group: {
          _id: null,
          totalCustomers: { $sum: 1 },
          activeCustomers: { $sum: { $cond: ['$isActive', 1, 0] } },
          wholesaleCustomers: { $sum: { $cond: [{ $eq: ['$customerType', 'wholesale'] }, 1, 0] } },
          retailCustomers: { $sum: { $cond: [{ $eq: ['$customerType', 'retail'] }, 1, 0] } },
          contractorCustomers: { $sum: { $cond: [{ $eq: ['$customerType', 'contractor'] }, 1, 0] } },
          totalCreditLimit: { $sum: '$creditLimit' },
          totalCurrentBalance: { $sum: '$currentBalance' },
          customersOverLimit: { $sum: { $cond: [{ $gt: ['$currentBalance', '$creditLimit'] }, 1, 0] } }
        }
      }
    ];

    const stats = await Customer.aggregate(pipeline);
    const summary = stats[0] || {
      totalCustomers: 0,
      activeCustomers: 0,
      wholesaleCustomers: 0,
      retailCustomers: 0,
      contractorCustomers: 0,
      totalCreditLimit: 0,
      totalCurrentBalance: 0,
      customersOverLimit: 0
    };

    res.json({
      success: true,
      data: summary
    });
  } catch (error) {
    console.error('Get customer stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/customers/low-credit
// @desc    Get customers with low credit
// @access  Private
router.get('/low-credit', async (req, res) => {
  try {
    const customers = await Customer.findLowCredit(req.user.id)
      .sort({ currentBalance: -1 })
      .limit(10);

    res.json({
      success: true,
      data: { customers }
    });
  } catch (error) {
    console.error('Get low credit customers error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
