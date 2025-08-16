const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const Client = require('../models/Client');
const { auth } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');

const router = express.Router();

// Rate limiting for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 requests per windowMs
  message: {
    error: 'Too many authentication attempts, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Validation middleware
const validateRegistration = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email address'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters'),
];

const validateClientRegistration = [
  ...validateRegistration,
  body('companyName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Company name must be between 2 and 100 characters'),
  body('contactPerson.firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Contact person first name must be between 2 and 50 characters'),
  body('contactPerson.lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Contact person last name must be between 2 and 50 characters'),
];

const validateLogin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email address'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
];

// Generate JWT token
const generateToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// @route   POST /api/auth/user/register
// @desc    Register a new user
// @access  Public
router.post('/user/register', authLimiter, validateRegistration, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { email, password, firstName, lastName, phoneNumber } = req.body;

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists',
      });
    }

    // Create new user
    const user = new User({
      email,
      password,
      firstName,
      lastName,
      phoneNumber,
    });

    await user.save();

    // Generate token
    const token = generateToken({
      id: user._id,
      email: user.email,
      role: 'user',
    });

    // Remove password from response
    user.password = undefined;

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    console.error('User registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration',
    });
  }
});

// @route   POST /api/auth/user/login
// @desc    Login user
// @access  Public
router.post('/user/login', authLimiter, validateLogin, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { email, password } = req.body;

    // Find user and include password for comparison
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if account is locked
    if (user.isLocked) {
      return res.status(423).json({
        success: false,
        message: 'Account is temporarily locked due to multiple failed login attempts',
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      await user.incLoginAttempts();
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Reset login attempts on successful login
    await user.resetLoginAttempts();

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate token
    const token = generateToken({
      id: user._id,
      email: user.email,
      role: 'user',
    });

    // Remove password from response
    user.password = undefined;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    console.error('User login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login',
    });
  }
});

// @route   POST /api/auth/client/register
// @desc    Register a new client
// @access  Public
router.post('/client/register', authLimiter, validateClientRegistration, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const {
      email,
      password,
      companyName,
      contactPerson,
      address,
      businessInfo,
    } = req.body;

    // Check if client already exists
    const existingClient = await Client.findByEmail(email);
    if (existingClient) {
      return res.status(400).json({
        success: false,
        message: 'Client with this email already exists',
      });
    }

    // Create new client
    const client = new Client({
      email,
      password,
      companyName,
      contactPerson,
      address,
      businessInfo,
    });

    await client.save();

    // Generate token
    const token = generateToken({
      id: client._id,
      email: client.email,
      role: 'client',
    });

    // Remove password from response
    client.password = undefined;

    res.status(201).json({
      success: true,
      message: 'Client registered successfully',
      data: {
        client,
        token,
      },
    });
  } catch (error) {
    console.error('Client registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration',
    });
  }
});

// @route   POST /api/auth/client/login
// @desc    Login client
// @access  Public
router.post('/client/login', authLimiter, validateLogin, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { email, password } = req.body;

    // Find client and include password for comparison
    const client = await Client.findOne({ email }).select('+password');
    console.log(client, 'client');
    if (!client) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if account is locked
    if (client.isLocked) {
      return res.status(423).json({
        success: false,
        message: 'Account is temporarily locked due to multiple failed login attempts',
      });
    }

    // Check if client is active
    if (!client.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Check subscription status
    if (!client.isSubscriptionActive) {
      return res.status(402).json({
        success: false,
        message: 'Subscription is not active',
      });
    }

    // Verify password
    const isPasswordValid = await client.comparePassword(password);
    if (!isPasswordValid) {
      await client.incLoginAttempts();
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Reset login attempts on successful login
    await client.resetLoginAttempts();

    // Update last login
    client.lastLogin = new Date();
    await client.save();

    // Generate token
    const token = generateToken({
      id: client._id,
      email: client.email,
      role: 'client',
    });

    // Remove password from response
    client.password = undefined;

    const responseData = {
      success: true,
      message: 'Login successful',
      data: {
        client,
        token,
      },
    };

    console.log('Sending response:', JSON.stringify(responseData, null, 2));
    res.json(responseData);
  } catch (error) {
    console.error('Client login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login',
    });
  }
});

// @route   GET /api/auth/me
// @desc    Get current user/client
// @access  Private
router.get('/me', auth, async (req, res) => {
  try {
    let user;
    
    if (req.user.role === 'user') {
      user = await User.findById(req.user.id);
    } else if (req.user.role === 'client') {
      user = await Client.findById(req.user.id);
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/auth/logout
// @desc    Logout user/client
// @access  Private
router.post('/logout', auth, (req, res) => {
  // In a stateless JWT setup, logout is handled client-side
  // You might want to implement a blacklist for tokens in production
  res.json({
    success: true,
    message: 'Logged out successfully',
  });
});

module.exports = router;
