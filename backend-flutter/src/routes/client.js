const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Client = require('../models/Client');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);
router.use(authorize('client', 'admin', 'user'));;

// @route   GET /api/client/profile
// @desc    Get client profile
// @access  Private
router.get('/profile', async (req, res) => {
  try {
    const client = await Client.findById(req.user.id).select('-password');
    
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    res.json({
      success: true,
      data: {
        client,
      },
    });
  } catch (error) {
    console.error('Get client profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/client/profile
// @desc    Update client profile
// @access  Private
router.put('/profile', [
  body('companyName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Company name must be between 2 and 100 characters'),
  body('contactPerson.firstName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Contact person first name must be between 2 and 50 characters'),
  body('contactPerson.lastName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Contact person last name must be between 2 and 50 characters'),
  body('contactPerson.phoneNumber')
    .optional()
    .trim()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
  body('contactPerson.position')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Position cannot exceed 100 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const client = await Client.findById(req.user.id);
    
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    // Update fields
    const updateFields = [
      'companyName',
      'contactPerson',
      'address',
      'businessInfo',
      'settings'
    ];

    updateFields.forEach(field => {
      if (req.body[field]) {
        if (field === 'contactPerson' || field === 'address' || field === 'businessInfo' || field === 'settings') {
          client[field] = { ...client[field], ...req.body[field] };
        } else {
          client[field] = req.body[field];
        }
      }
    });

    await client.save();

    // Remove password from response
    client.password = undefined;

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        client,
      },
    });
  } catch (error) {
    console.error('Update client profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/client/subscription
// @desc    Get client subscription details
// @access  Private
router.get('/subscription', async (req, res) => {
  try {
    const client = await Client.findById(req.user.id).select('subscription');
    
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    res.json({
      success: true,
      data: {
        subscription: client.subscription,
      },
    });
  } catch (error) {
    console.error('Get subscription error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/client/api-key
// @desc    Get client API key
// @access  Private
router.get('/api-key', async (req, res) => {
  try {
    const client = await Client.findById(req.user.id).select('apiKey apiKeyExpires');
    
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    // Check if API key is expired
    if (client.apiKeyExpires && client.apiKeyExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'API key has expired',
      });
    }

    res.json({
      success: true,
      data: {
        apiKey: client.apiKey,
        expiresAt: client.apiKeyExpires,
      },
    });
  } catch (error) {
    console.error('Get API key error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/client/regenerate-api-key
// @desc    Regenerate client API key
// @access  Private
router.post('/regenerate-api-key', async (req, res) => {
  try {
    const client = await Client.findById(req.user.id);
    
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    // Generate new API key
    const crypto = require('crypto');
    client.apiKey = crypto.randomBytes(32).toString('hex');
    client.apiKeyExpires = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year

    await client.save();

    res.json({
      success: true,
      message: 'API key regenerated successfully',
      data: {
        apiKey: client.apiKey,
        expiresAt: client.apiKeyExpires,
      },
    });
  } catch (error) {
    console.error('Regenerate API key error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/client/dashboard
// @desc    Get client dashboard data
// @access  Private
router.get('/dashboard', async (req, res) => {
  try {
    const client = await Client.findById(req.user.id).select('-password');
    
    if (!client) {
      return res.status(404).json({
        success: false,
        message: 'Client not found',
      });
    }

    // Mock dashboard data - replace with actual business logic
    const dashboardData = {
      subscriptionStatus: client.subscription.status,
      plan: client.subscription.plan,
      features: client.subscription.features,
      lastLogin: client.lastLogin,
      companyInfo: {
        name: client.companyName,
        industry: client.businessInfo.industry,
        size: client.businessInfo.companySize,
      },
      // Add more dashboard metrics here
      metrics: {
        totalUsers: 0, // Replace with actual count
        activeProjects: 0, // Replace with actual count
        storageUsed: '0 MB', // Replace with actual usage
      },
    };

    res.json({
      success: true,
      data: dashboardData,
    });
  } catch (error) {
    console.error('Get dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
