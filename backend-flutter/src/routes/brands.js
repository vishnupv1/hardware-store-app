const express = require('express');
const { body, validationResult, query } = require('express-validator');
const { auth, authorize, requireAdmin, requirePermission } = require('../middleware/auth');
const Brand = require('../models/Brand');
const Product = require('../models/Product');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);
router.use(authorize('client', 'admin', 'user', 'employee'));

// @route   GET /api/brands
// @desc    Get all brands with pagination and filters
// @access  Private
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('search').optional().trim(),
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
    const forDropdown = req.query.forDropdown === 'true';

    // If forDropdown is true, return all active brands without pagination
    if (forDropdown) {
      const brands = await Brand.find({ isActive: true })
        .select('name id')
        .sort({ name: 1 });
      
      return res.json({
        success: true,
        data: brands
      });
    }

    // Build filter object based on user role
    let filter = {};
    
    // For clients, filter by their clientId
    if (req.user.role === 'client') {
      filter.clientId = req.user.id;
    }
    // For regular users, they can see brands associated with their account
    else if (req.user.role === 'user') {
      filter.clientId = req.user.id;
    }
    // Admins and employees can see all brands
    
    if (req.query.search) {
      filter.name = { $regex: req.query.search, $options: 'i' };
    }

    if (req.query.isActive !== undefined) {
      filter.isActive = req.query.isActive === 'true';
    }

    const brands = await Brand.find(filter)
      .populate('createdBy', 'firstName lastName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Brand.countDocuments(filter);
    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: {
        brands,
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
    console.error('Get brands error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/brands
// @desc    Create a new brand (Admin only)
// @access  Private - Admin only
router.post('/', requireAdmin, [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Brand name must be between 2 and 100 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),
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
        message: 'Validation error',
        errors: errors.array(),
      });
    }

    const { name, description, isActive = true } = req.body;
    
    // Check if brand already exists for this client
    const existingBrand = await Brand.findOne({
      clientId: req.user.id,
      name: name
    });

    if (existingBrand) {
      return res.status(400).json({
        success: false,
        message: 'Brand already exists',
      });
    }

    const brand = new Brand({
      name,
      description,
      isActive,
      clientId: req.user.id,
      createdBy: req.user.id,
    });

    await brand.save();

    // Populate createdBy field
    await brand.populate('createdBy', 'firstName lastName');

    res.status(201).json({
      success: true,
      message: 'Brand created successfully',
      data: { brand }
    });
  } catch (error) {
    console.error('Create brand error:', error);
    
    // Handle duplicate key error
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Brand already exists',
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/brands/:id
// @desc    Get brand by ID
// @access  Private
router.get('/:id', async (req, res) => {
  try {
    const brand = await Brand.findOne({
      _id: req.params.id,
      clientId: req.user.id
    }).populate('createdBy', 'firstName lastName');

    if (!brand) {
      return res.status(404).json({
        success: false,
        message: 'Brand not found',
      });
    }

    res.json({
      success: true,
      data: { brand }
    });
  } catch (error) {
    console.error('Get brand error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/brands/:id
// @desc    Update brand
// @access  Private
router.put('/:id', [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Brand name must be between 2 and 100 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),
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
        message: 'Validation error',
        errors: errors.array(),
      });
    }

    const { name, description, isActive } = req.body;
    
    const brand = await Brand.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!brand) {
      return res.status(404).json({
        success: false,
        message: 'Brand not found',
      });
    }

    // Check if new name conflicts with existing brand
    if (name && name !== brand.name) {
      const existingBrand = await Brand.findOne({
        clientId: req.user.id,
        name: name,
        _id: { $ne: req.params.id }
      });

      if (existingBrand) {
        return res.status(400).json({
          success: false,
          message: 'Brand name already exists',
        });
      }
    }

    // Update fields
    if (name !== undefined) brand.name = name;
    if (description !== undefined) brand.description = description;
    if (isActive !== undefined) brand.isActive = isActive;

    await brand.save();
    await brand.populate('createdBy', 'firstName lastName');

    res.json({
      success: true,
      message: 'Brand updated successfully',
      data: { brand }
    });
  } catch (error) {
    console.error('Update brand error:', error);
    
    // Handle duplicate key error
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Brand name already exists',
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/brands/:id
// @desc    Delete brand
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const brand = await Brand.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!brand) {
      return res.status(404).json({
        success: false,
        message: 'Brand not found',
      });
    }

    // Check if brand is used by any products
    const productCount = await Product.countDocuments({
      brandId: req.params.id,
      clientId: req.user.id
    });

    if (productCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete brand. It is used by ${productCount} product(s).`,
      });
    }

    await Brand.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Brand deleted successfully',
    });
  } catch (error) {
    console.error('Delete brand error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/brands/stats/summary
// @desc    Get brand statistics
// @access  Private
router.get('/stats/summary', async (req, res) => {
  try {
    const totalBrands = await Brand.countDocuments({ clientId: req.user.id });
    const activeBrands = await Brand.countDocuments({ 
      clientId: req.user.id, 
      isActive: true 
    });
    const inactiveBrands = totalBrands - activeBrands;

    // Get brands with most products
    const topBrands = await Brand.aggregate([
      { $match: { clientId: req.user.id } },
      {
        $lookup: {
          from: 'products',
          localField: '_id',
          foreignField: 'brandId',
          as: 'products'
        }
      },
      {
        $project: {
          name: 1,
          productCount: { $size: '$products' },
          isActive: 1
        }
      },
      { $sort: { productCount: -1 } },
      { $limit: 5 }
    ]);

    res.json({
      success: true,
      data: {
        totalBrands,
        activeBrands,
        inactiveBrands,
        topBrands
      }
    });
  } catch (error) {
    console.error('Get brand stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
