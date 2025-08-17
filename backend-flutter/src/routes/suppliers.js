const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Supplier = require('../models/Supplier');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);
router.use(authorize('admin', 'user', 'client'));

// @route   GET /api/suppliers
// @desc    Get all suppliers with pagination and filters
// @access  Private
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const search = req.query.search;
    const isActive = req.query.isActive;
    const forDropdown = req.query.forDropdown === 'true';

    // If forDropdown is true, return all active suppliers without pagination
    if (forDropdown) {
      const suppliers = await Supplier.find({ isActive: true })
        .select('name id')
        .sort({ name: 1 });
      
      return res.json({
        success: true,
        data: suppliers
      });
    }

    // Build query
    const query = {};
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { 'contactPerson.name': { $regex: search, $options: 'i' } },
        { 'contactPerson.email': { $regex: search, $options: 'i' } }
      ];
    }
    
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }

    // Calculate skip value
    const skip = (page - 1) * limit;

    // Execute query
    const suppliers = await Supplier.find(query)
      .populate('createdBy', 'firstName lastName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Get total count for pagination
    const total = await Supplier.countDocuments(query);
    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: {
        suppliers,
        pagination: {
          currentPage: page,
          totalPages,
          totalItems: total,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      }
    });
  } catch (error) {
    console.error('Get suppliers error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/suppliers
// @desc    Create a new supplier
// @access  Private
router.post('/', [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Supplier name must be between 2 and 100 characters'),
  body('contactPerson.name')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Contact person name cannot exceed 100 characters'),
  body('contactPerson.email')
    .optional()
    .isEmail()
    .withMessage('Please enter a valid email address'),
  body('contactPerson.phone')
    .optional()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
  body('address.street')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Street address cannot exceed 200 characters'),
  body('address.city')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('City cannot exceed 100 characters'),
  body('address.state')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('State cannot exceed 100 characters'),
  body('address.zipCode')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Zip code cannot exceed 20 characters'),
  body('address.country')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Country cannot exceed 100 characters'),
  body('businessInfo.website')
    .optional()
    .matches(/^https?:\/\/.+/)
    .withMessage('Please enter a valid website URL'),
  body('businessInfo.taxId')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Tax ID cannot exceed 50 characters'),
  body('businessInfo.paymentTerms')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Payment terms cannot exceed 100 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const {
      name,
      contactPerson,
      address,
      businessInfo
    } = req.body;

    // Create new supplier
    const supplier = new Supplier({
      name,
      contactPerson,
      address,
      businessInfo,
      createdBy: req.user.id
    });

    await supplier.save();

    // Populate createdBy field
    await supplier.populate('createdBy', 'firstName lastName');

    res.status(201).json({
      success: true,
      message: 'Supplier created successfully',
      data: supplier
    });
  } catch (error) {
    console.error('Create supplier error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/suppliers/:id
// @desc    Get supplier by ID
// @access  Private
router.get('/:id', async (req, res) => {
  try {
    const supplier = await Supplier.findById(req.params.id)
      .populate('createdBy', 'firstName lastName');

    if (!supplier) {
      return res.status(404).json({
        success: false,
        message: 'Supplier not found'
      });
    }

    res.json({
      success: true,
      data: supplier
    });
  } catch (error) {
    console.error('Get supplier error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/suppliers/:id
// @desc    Update supplier
// @access  Private
router.put('/:id', [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Supplier name must be between 2 and 100 characters'),
  body('contactPerson.name')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Contact person name cannot exceed 100 characters'),
  body('contactPerson.email')
    .optional()
    .isEmail()
    .withMessage('Please enter a valid email address'),
  body('contactPerson.phone')
    .optional()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
  body('address.street')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Street address cannot exceed 200 characters'),
  body('address.city')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('City cannot exceed 100 characters'),
  body('address.state')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('State cannot exceed 100 characters'),
  body('address.zipCode')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Zip code cannot exceed 20 characters'),
  body('address.country')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Country cannot exceed 100 characters'),
  body('businessInfo.website')
    .optional()
    .matches(/^https?:\/\/.+/)
    .withMessage('Please enter a valid website URL'),
  body('businessInfo.taxId')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Tax ID cannot exceed 50 characters'),
  body('businessInfo.paymentTerms')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Payment terms cannot exceed 100 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const {
      name,
      contactPerson,
      address,
      businessInfo,
      isActive
    } = req.body;

    const supplier = await Supplier.findById(req.params.id);
    if (!supplier) {
      return res.status(404).json({
        success: false,
        message: 'Supplier not found'
      });
    }

    // Update fields
    if (name !== undefined) supplier.name = name;
    if (contactPerson !== undefined) supplier.contactPerson = { ...supplier.contactPerson, ...contactPerson };
    if (address !== undefined) supplier.address = { ...supplier.address, ...address };
    if (businessInfo !== undefined) supplier.businessInfo = { ...supplier.businessInfo, ...businessInfo };
    if (isActive !== undefined) supplier.isActive = isActive;

    await supplier.save();
    await supplier.populate('createdBy', 'firstName lastName');

    res.json({
      success: true,
      message: 'Supplier updated successfully',
      data: supplier
    });
  } catch (error) {
    console.error('Update supplier error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/suppliers/:id
// @desc    Delete supplier
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const supplier = await Supplier.findById(req.params.id);
    if (!supplier) {
      return res.status(404).json({
        success: false,
        message: 'Supplier not found'
      });
    }

    // Check if supplier has products
    if (supplier.productCount > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete supplier with associated products'
      });
    }

    await Supplier.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Supplier deleted successfully'
    });
  } catch (error) {
    console.error('Delete supplier error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
