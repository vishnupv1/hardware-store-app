const express = require('express');
const { body, validationResult, query } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Product = require('../models/Product');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);
router.use(authorize('client', 'admin', 'user'));;

// @route   GET /api/products
// @desc    Get all products with pagination and filters
// @access  Private
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('search').optional().trim(),
  query('category').optional().trim(),
  query('brand').optional().trim(),
  query('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
  query('stockStatus').optional().isIn(['in_stock', 'low_stock', 'out_of_stock']).withMessage('Invalid stock status'),
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
        { sku: { $regex: req.query.search, $options: 'i' } },
        { brand: { $regex: req.query.search, $options: 'i' } },
        { category: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    if (req.query.category) {
      filter.category = req.query.category;
    }

    if (req.query.brand) {
      filter.brand = req.query.brand;
    }

    if (req.query.isActive !== undefined) {
      filter.isActive = req.query.isActive === 'true';
    }

    if (req.query.stockStatus) {
      switch (req.query.stockStatus) {
        case 'out_of_stock':
          filter.stockQuantity = 0;
          break;
        case 'low_stock':
          filter.$expr = { $lte: ['$stockQuantity', '$minStockLevel'] };
          break;
        case 'in_stock':
          filter.$expr = { $gt: ['$stockQuantity', '$minStockLevel'] };
          break;
      }
    }

    const products = await Product.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Product.countDocuments(filter);
    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: {
        products,
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
    console.error('Get products error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/products/categories
// @desc    Get all product categories
// @access  Private
router.get('/categories', async (req, res) => {
  try {
    const categories = await Product.distinct('category', { clientId: req.user.id });
    
    res.json({
      success: true,
      data: { categories }
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/products/brands
// @desc    Get all product brands
// @access  Private
router.get('/brands', async (req, res) => {
  try {
    const brands = await Product.distinct('brand', { 
      clientId: req.user.id,
      brand: { $ne: null, $ne: '' }
    });
    
    res.json({
      success: true,
      data: { brands }
    });
  } catch (error) {
    console.error('Get brands error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/products/brands
// @desc    Add a new brand
// @access  Private
router.post('/brands', [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Brand name must be between 2 and 100 characters'),
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

    const { name } = req.body;
    
    // Check if brand already exists
    const existingBrand = await Product.findOne({
      clientId: req.user.id,
      brand: name
    });

    if (existingBrand) {
      return res.status(400).json({
        success: false,
        message: 'Brand already exists',
      });
    }

    // Create a temporary product to add the brand to the system
    const tempProduct = new Product({
      name: `Temp Product for ${name}`,
      description: 'Temporary product to add brand',
      sku: `TEMP-${Date.now()}`,
      category: 'Temporary',
      brand: name,
      sellingPrice: 0.01,
      costPrice: 0.01,
      wholesalePrice: 0.01,
      stockQuantity: 0,
      minStockLevel: 0,
      unit: 'pcs',
      isActive: false,
      clientId: req.user.id,
    });

    await tempProduct.save();

    // Delete the temporary product immediately
    await Product.findByIdAndDelete(tempProduct._id);

    res.json({
      success: true,
      message: 'Brand added successfully',
      data: { brand: name }
    });
  } catch (error) {
    console.error('Add brand error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/products/:id
// @desc    Get product by ID
// @access  Private
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    res.json({
      success: true,
      data: { product }
    });
  } catch (error) {
    console.error('Get product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/products
// @desc    Create a new product
// @access  Private
router.post('/', [
  body('name')
    .trim()
    .isLength({ min: 2, max: 200 })
    .withMessage('Product name must be between 2 and 200 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Description cannot exceed 1000 characters'),
  body('category')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Category must be between 2 and 100 characters'),
  body('subcategory')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Subcategory cannot exceed 100 characters'),
  body('brand')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Brand cannot exceed 100 characters'),
  body('model')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Model cannot exceed 100 characters'),
  body('sku')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('SKU must be between 2 and 50 characters'),
  body('costPrice')
    .isFloat({ min: 0 })
    .withMessage('Cost price must be a positive number'),
  body('sellingPrice')
    .isFloat({ min: 0 })
    .withMessage('Selling price must be a positive number'),
  body('wholesalePrice')
    .isFloat({ min: 0 })
    .withMessage('Wholesale price must be a positive number'),
  body('stockQuantity')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Stock quantity must be a non-negative integer'),
  body('minStockLevel')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Minimum stock level must be a non-negative integer'),
  body('unit')
    .trim()
    .isLength({ min: 1, max: 20 })
    .withMessage('Unit must be between 1 and 20 characters'),
  body('imageUrl')
    .optional()
    .trim()
    .isURL()
    .withMessage('Please enter a valid image URL'),
  body('barcode')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Barcode cannot exceed 50 characters'),
  body('weight')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Weight must be a positive number'),
  body('reorderPoint')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Reorder point must be a non-negative integer'),
  body('reorderQuantity')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Reorder quantity must be a non-negative integer'),
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

    // Check if SKU already exists for this client
    const existingProduct = await Product.findOne({
      clientId: req.user.id,
      sku: req.body.sku
    });

    if (existingProduct) {
      return res.status(400).json({
        success: false,
        message: 'Product with this SKU already exists',
      });
    }

    // Check if barcode already exists (if provided)
    if (req.body.barcode) {
      const existingBarcode = await Product.findOne({
        barcode: req.body.barcode
      });

      if (existingBarcode) {
        return res.status(400).json({
          success: false,
          message: 'Product with this barcode already exists',
        });
      }
    }

    // Validate prices
    if (req.body.sellingPrice < req.body.costPrice) {
      return res.status(400).json({
        success: false,
        message: 'Selling price cannot be less than cost price',
      });
    }

    if (req.body.wholesalePrice < req.body.costPrice) {
      return res.status(400).json({
        success: false,
        message: 'Wholesale price cannot be less than cost price',
      });
    }

    const productData = {
      ...req.body,
      clientId: req.user.id
    };

    const product = new Product(productData);
    await product.save();

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      data: { product }
    });
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/products/:id
// @desc    Update product
// @access  Private
router.put('/:id', [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 200 })
    .withMessage('Product name must be between 2 and 200 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Description cannot exceed 1000 characters'),
  body('category')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Category must be between 2 and 100 characters'),
  body('subcategory')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Subcategory cannot exceed 100 characters'),
  body('brand')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Brand cannot exceed 100 characters'),
  body('model')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Model cannot exceed 100 characters'),
  body('sku')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('SKU must be between 2 and 50 characters'),
  body('costPrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Cost price must be a positive number'),
  body('sellingPrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Selling price must be a positive number'),
  body('wholesalePrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Wholesale price must be a positive number'),
  body('stockQuantity')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Stock quantity must be a non-negative integer'),
  body('minStockLevel')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Minimum stock level must be a non-negative integer'),
  body('unit')
    .optional()
    .trim()
    .isLength({ min: 1, max: 20 })
    .withMessage('Unit must be between 1 and 20 characters'),
  body('imageUrl')
    .optional()
    .trim()
    .isURL()
    .withMessage('Please enter a valid image URL'),
  body('barcode')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Barcode cannot exceed 50 characters'),
  body('weight')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Weight must be a positive number'),
  body('reorderPoint')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Reorder point must be a non-negative integer'),
  body('reorderQuantity')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Reorder quantity must be a non-negative integer'),
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

    const product = await Product.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Check if SKU is being updated and if it already exists
    if (req.body.sku && req.body.sku !== product.sku) {
      const existingProduct = await Product.findOne({
        clientId: req.user.id,
        sku: req.body.sku,
        _id: { $ne: req.params.id }
      });

      if (existingProduct) {
        return res.status(400).json({
          success: false,
          message: 'Product with this SKU already exists',
        });
      }
    }

    // Check if barcode is being updated and if it already exists
    if (req.body.barcode && req.body.barcode !== product.barcode) {
      const existingBarcode = await Product.findOne({
        barcode: req.body.barcode,
        _id: { $ne: req.params.id }
      });

      if (existingBarcode) {
        return res.status(400).json({
          success: false,
          message: 'Product with this barcode already exists',
        });
      }
    }

    // Validate prices if being updated
    const updatedCostPrice = req.body.costPrice !== undefined ? req.body.costPrice : product.costPrice;
    const updatedSellingPrice = req.body.sellingPrice !== undefined ? req.body.sellingPrice : product.sellingPrice;
    const updatedWholesalePrice = req.body.wholesalePrice !== undefined ? req.body.wholesalePrice : product.wholesalePrice;

    if (updatedSellingPrice < updatedCostPrice) {
      return res.status(400).json({
        success: false,
        message: 'Selling price cannot be less than cost price',
      });
    }

    if (updatedWholesalePrice < updatedCostPrice) {
      return res.status(400).json({
        success: false,
        message: 'Wholesale price cannot be less than cost price',
      });
    }

    // Update product
    Object.keys(req.body).forEach(key => {
      if (req.body[key] !== undefined) {
        product[key] = req.body[key];
      }
    });

    await product.save();

    res.json({
      success: true,
      message: 'Product updated successfully',
      data: { product }
    });
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/products/:id
// @desc    Delete product (soft delete)
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const product = await Product.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Soft delete - set isActive to false
    product.isActive = false;
    await product.save();

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/products/:id/stock
// @desc    Update product stock quantity
// @access  Private
router.post('/:id/stock', [
  body('quantity')
    .isInt({ min: 0 })
    .withMessage('Quantity must be a non-negative integer'),
  body('type')
    .isIn(['add', 'subtract', 'set'])
    .withMessage('Type must be add, subtract, or set'),
  body('reason')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Reason cannot exceed 200 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const product = await Product.findOne({
      _id: req.params.id,
      clientId: req.user.id
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    const { quantity, type, reason } = req.body;
    let newQuantity = product.stockQuantity;

    switch (type) {
      case 'add':
        newQuantity += quantity;
        break;
      case 'subtract':
        newQuantity = Math.max(0, newQuantity - quantity);
        break;
      case 'set':
        newQuantity = quantity;
        break;
    }

    product.stockQuantity = newQuantity;
    
    // Update last restocked date if adding stock
    if (type === 'add' && quantity > 0) {
      product.lastRestocked = new Date();
    }

    await product.save();

    res.json({
      success: true,
      message: 'Stock updated successfully',
      data: {
        product,
        stockChange: {
          type,
          quantity,
          previousQuantity: product.stockQuantity - (type === 'add' ? quantity : -quantity),
          newQuantity: product.stockQuantity,
          reason
        }
      }
    });
  } catch (error) {
    console.error('Update stock error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/products/stats/summary
// @desc    Get product statistics summary
// @access  Private
router.get('/stats/summary', async (req, res) => {
  try {
    const pipeline = [
      { $match: { clientId: req.user.id } },
      {
        $group: {
          _id: null,
          totalProducts: { $sum: 1 },
          activeProducts: { $sum: { $cond: ['$isActive', 1, 0] } },
          totalStockValue: { $sum: { $multiply: ['$stockQuantity', '$costPrice'] } },
          totalStockQuantity: { $sum: '$stockQuantity' },
          lowStockProducts: { $sum: { $cond: [{ $lte: ['$stockQuantity', '$minStockLevel'] }, 1, 0] } },
          outOfStockProducts: { $sum: { $cond: [{ $eq: ['$stockQuantity', 0] }, 1, 0] } },
          totalRevenue: { $sum: '$totalRevenue' },
          totalSold: { $sum: '$totalSold' }
        }
      }
    ];

    const stats = await Product.aggregate(pipeline);
    const summary = stats[0] || {
      totalProducts: 0,
      activeProducts: 0,
      totalStockValue: 0,
      totalStockQuantity: 0,
      lowStockProducts: 0,
      outOfStockProducts: 0,
      totalRevenue: 0,
      totalSold: 0
    };

    res.json({
      success: true,
      data: summary
    });
  } catch (error) {
    console.error('Get product stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/products/low-stock
// @desc    Get products with low stock
// @access  Private
router.get('/low-stock', async (req, res) => {
  try {
    const products = await Product.findLowStock(req.user.id)
      .sort({ stockQuantity: 1 })
      .limit(20);

    res.json({
      success: true,
      data: { products }
    });
  } catch (error) {
    console.error('Get low stock products error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
