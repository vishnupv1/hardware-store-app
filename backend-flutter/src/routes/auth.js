const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const Client = require('../models/Client');
const Employee = require('../models/Employee');
const Admin = require('../models/Admin');
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

// @route   POST /api/auth/admin/register
// @desc    Register a new admin (super admin only)
// @access  Private
router.post('/admin/register', authLimiter, [
  ...validateRegistration,
  body('adminId')
    .trim()
    .isLength({ min: 2, max: 20 })
    .withMessage('Admin ID must be between 2 and 20 characters'),
  body('department')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Department must be between 2 and 100 characters'),
  body('position')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Position must be between 2 and 100 characters'),
  body('adminLevel')
    .optional()
    .isIn(['super_admin', 'admin', 'manager'])
    .withMessage('Invalid admin level'),
  body('accessLevel')
    .optional()
    .isIn(['full_access', 'limited_access', 'read_only'])
    .withMessage('Invalid access level'),
  body('salary')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Salary must be a positive number'),
], async (req, res) => {
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
      firstName, 
      lastName, 
      phoneNumber,
      adminId,
      department,
      position,
      adminLevel = 'admin',
      accessLevel = 'limited_access',
      salary
    } = req.body;

    // Check if admin already exists
    const existingAdmin = await Admin.findByEmail(email);
    if (existingAdmin) {
      return res.status(400).json({
        success: false,
        message: 'Admin with this email already exists',
      });
    }

    // Check if admin ID already exists
    const existingAdminId = await Admin.findByAdminId(adminId);
    if (existingAdminId) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID already exists',
      });
    }

    // Create new admin
    const admin = new Admin({
      email,
      password,
      firstName,
      lastName,
      phoneNumber,
      adminId,
      department,
      position,
      adminLevel,
      accessLevel,
      salary,
      hireDate: new Date(),
      permissions: getDefaultAdminPermissions(adminLevel),
      allowedModules: getDefaultAdminModules(accessLevel)
    });

    await admin.save();

    // Generate token
    const token = generateToken({
      id: admin._id,
      email: admin.email,
      role: 'admin',
    });

    // Remove password from response
    admin.password = undefined;

    res.status(201).json({
      success: true,
      message: 'Admin registered successfully',
      data: {
        admin,
        token,
      },
    });
  } catch (error) {
    console.error('Admin registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration',
    });
  }
});

// Helper function to get default admin permissions based on admin level
function getDefaultAdminPermissions(adminLevel) {
  const permissions = {
    manager: [
      'view_dashboard',
      'manage_customers',
      'manage_products',
      'manage_sales',
      'manage_inventory',
      'view_reports',
      'create_sales',
      'edit_sales',
      'delete_sales',
      'create_customers',
      'edit_customers',
      'delete_customers',
      'create_products',
      'edit_products',
      'delete_products',
      'manage_employees',
      'view_advanced_analytics',
      'export_data',
      'generate_reports'
    ],
    admin: [
      'view_dashboard',
      'manage_customers',
      'manage_products',
      'manage_sales',
      'manage_inventory',
      'manage_reports',
      'manage_employees',
      'manage_settings',
      'view_reports',
      'create_sales',
      'edit_sales',
      'delete_sales',
      'create_customers',
      'edit_customers',
      'delete_customers',
      'create_products',
      'edit_products',
      'delete_products',
      'view_advanced_analytics',
      'export_data',
      'generate_reports',
      'manage_business_settings',
      'manage_company_info',
      'view_financial_reports',
      'manage_content',
      'manage_notifications',
      'manage_announcements'
    ],
    super_admin: [
      'view_dashboard',
      'manage_customers',
      'manage_products',
      'manage_sales',
      'manage_inventory',
      'manage_reports',
      'manage_employees',
      'manage_settings',
      'view_reports',
      'create_sales',
      'edit_sales',
      'delete_sales',
      'create_customers',
      'edit_customers',
      'delete_customers',
      'create_products',
      'edit_products',
      'delete_products',
      'view_advanced_analytics',
      'export_data',
      'generate_reports',
      'view_audit_logs',
      'manage_dashboards',
      'manage_business_settings',
      'manage_company_info',
      'view_financial_reports',
      'manage_content',
      'manage_notifications',
      'manage_announcements',
      'manage_system_settings',
      'manage_database',
      'manage_backups',
      'manage_security',
      'view_system_logs',
      'manage_api_keys',
      'manage_all_users',
      'manage_clients',
      'manage_admins',
      'view_user_logs',
      'reset_user_passwords',
      'suspend_users',
      'delete_users',
      'manage_billing',
      'manage_subscriptions',
      'manage_tax_settings',
      'manage_templates',
      'manage_help_docs'
    ]
  };
  
  return permissions[adminLevel] || permissions.admin;
}

// Helper function to get default admin modules based on access level
function getDefaultAdminModules(accessLevel) {
  const modules = {
    read_only: [
      'dashboard',
      'customers',
      'products',
      'sales',
      'inventory',
      'reports'
    ],
    limited_access: [
      'dashboard',
      'customers',
      'products',
      'sales',
      'inventory',
      'employees',
      'reports',
      'settings',
      'analytics'
    ],
    full_access: [
      'dashboard',
      'customers',
      'products',
      'sales',
      'inventory',
      'employees',
      'reports',
      'settings',
      'analytics',
      'admin_panel',
      'system_settings',
      'user_management',
      'billing',
      'content_management'
    ]
  };
  
  return modules[accessLevel] || modules.limited_access;
}

// @route   POST /api/auth/employee/register
// @desc    Register a new employee
// @access  Public
router.post('/employee/register', authLimiter, [
  ...validateRegistration,
  body('employeeId')
    .trim()
    .isLength({ min: 2, max: 20 })
    .withMessage('Employee ID must be between 2 and 20 characters'),
  body('department')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Department must be between 2 and 100 characters'),
  body('position')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Position must be between 2 and 100 characters'),
  body('role')
    .optional()
    .isIn(['employee', 'manager', 'admin', 'supervisor'])
    .withMessage('Invalid role'),
  body('salary')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Salary must be a positive number'),
], async (req, res) => {
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
      firstName, 
      lastName, 
      phoneNumber,
      employeeId,
      department,
      position,
      role = 'employee',
      salary
    } = req.body;

    // Check if employee already exists
    const existingEmployee = await Employee.findByEmail(email);
    if (existingEmployee) {
      return res.status(400).json({
        success: false,
        message: 'Employee with this email already exists',
      });
    }

    // Check if employee ID already exists
    const existingEmployeeId = await Employee.findByEmployeeId(employeeId);
    if (existingEmployeeId) {
      return res.status(400).json({
        success: false,
        message: 'Employee ID already exists',
      });
    }

    // Create new employee
    const employee = new Employee({
      email,
      password,
      firstName,
      lastName,
      phoneNumber,
      employeeId,
      department,
      position,
      role,
      salary,
      hireDate: new Date(),
      permissions: getDefaultPermissions(role)
    });

    await employee.save();

    // Generate token
    const token = generateToken({
      id: employee._id,
      email: employee.email,
      role: 'employee',
    });

    // Remove password from response
    employee.password = undefined;

    res.status(201).json({
      success: true,
      message: 'Employee registered successfully',
      data: {
        employee,
        token,
      },
    });
  } catch (error) {
    console.error('Employee registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration',
    });
  }
});

// Helper function to get default permissions based on role
function getDefaultPermissions(role) {
  const permissions = {
    employee: [
      'view_dashboard',
      'view_customers',
      'view_products',
      'create_sales',
      'view_reports'
    ],
    supervisor: [
      'view_dashboard',
      'manage_customers',
      'view_products',
      'manage_sales',
      'view_reports',
      'edit_sales',
      'create_customers',
      'edit_customers'
    ],
    manager: [
      'view_dashboard',
      'manage_customers',
      'manage_products',
      'manage_sales',
      'manage_inventory',
      'view_reports',
      'create_sales',
      'edit_sales',
      'delete_sales',
      'create_customers',
      'edit_customers',
      'delete_customers',
      'create_products',
      'edit_products',
      'delete_products'
    ],
    admin: [
      'view_dashboard',
      'manage_customers',
      'manage_products',
      'manage_sales',
      'manage_inventory',
      'manage_reports',
      'manage_employees',
      'manage_settings',
      'view_reports',
      'create_sales',
      'edit_sales',
      'delete_sales',
      'create_customers',
      'edit_customers',
      'delete_customers',
      'create_products',
      'edit_products',
      'delete_products'
    ]
  };
  
  return permissions[role] || permissions.employee;
}

// @route   POST /api/auth/admin/login
// @desc    Login admin
// @access  Public
router.post('/admin/login', authLimiter, validateLogin, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { email, password } = req.body;



    // Find admin and include password for comparison
    const admin = await Admin.findOne({ email }).select('+password');
    if (!admin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }



    // Check if account is locked
    if (admin.isLocked) {
      return res.status(423).json({
        success: false,
        message: 'Account is temporarily locked due to multiple failed login attempts',
      });
    }

    // Check if admin is active
    if (!admin.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Check if password is expired
    if (admin.isPasswordExpired) {
      return res.status(401).json({
        success: false,
        message: 'Password has expired. Please reset your password.',
      });
    }

    // Verify password
    const isPasswordValid = await admin.comparePassword(password);
    if (!isPasswordValid) {
      await admin.incLoginAttempts();
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Reset login attempts on successful login
    await admin.resetLoginAttempts();

    // Update last login
    admin.lastLogin = new Date();
    await admin.save();

    // Generate token
    const token = generateToken({
      id: admin._id,
      email: admin.email,
      role: 'admin',
    });

    // Remove password from response
    admin.password = undefined;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        admin,
        token,
      },
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login',
    });
  }
});

// @route   POST /api/auth/employee/login
// @desc    Login employee
// @access  Public
router.post('/employee/login', authLimiter, validateLogin, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { email, password } = req.body;

    // Find employee and include password for comparison
    const employee = await Employee.findOne({ email }).select('+password');
    if (!employee) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if account is locked
    if (employee.isLocked) {
      return res.status(423).json({
        success: false,
        message: 'Account is temporarily locked due to multiple failed login attempts',
      });
    }

    // Check if employee is active
    if (!employee.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Verify password
    const isPasswordValid = await employee.comparePassword(password);
    if (!isPasswordValid) {
      await employee.incLoginAttempts();
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Reset login attempts on successful login
    await employee.resetLoginAttempts();

    // Update last login
    employee.lastLogin = new Date();
    await employee.save();

    // Generate token
    const token = generateToken({
      id: employee._id,
      email: employee.email,
      role: 'employee',
    });

    // Remove password from response
    employee.password = undefined;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        employee,
        token,
      },
    });
  } catch (error) {
    console.error('Employee login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login',
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


    res.json(responseData);
  } catch (error) {
    console.error('Client login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login',
    });
  }
});

// @route   POST /api/auth/vendor/login
// @desc    Login vendor
// @access  Public
router.post('/vendor/login', authLimiter, validateLogin, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { email, password } = req.body;

    // Find user with vendor role and include password for comparison
    const vendor = await User.findOne({ email, role: 'vendor' }).select('+password');

    if (!vendor) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if account is locked
    if (vendor.isLocked) {
      return res.status(423).json({
        success: false,
        message: 'Account is temporarily locked due to multiple failed login attempts',
      });
    }

    // Check if vendor is active
    if (!vendor.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Verify password
    const isPasswordValid = await vendor.comparePassword(password);
    if (!isPasswordValid) {
      await vendor.incLoginAttempts();
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Reset login attempts on successful login
    await vendor.resetLoginAttempts();

    // Update last login
    vendor.lastLogin = new Date();
    await vendor.save();

    // Generate token
    const token = generateToken({
      id: vendor._id,
      email: vendor.email,
      role: 'vendor',
    });

    // Remove password from response
    vendor.password = undefined;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: vendor,
        token,
      },
    });
  } catch (error) {
    console.error('Vendor login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login',
    });
  }
});

// @route   GET /api/auth/me
// @desc    Get current user/client/employee/admin
// @access  Private
router.get('/me', auth, async (req, res) => {
  try {
    let user;
    
    if (req.user.role === 'user' || req.user.role === 'vendor') {
      user = await User.findById(req.user.id);
    } else if (req.user.role === 'client') {
      user = await Client.findById(req.user.id);
    } else if (req.user.role === 'employee') {
      user = await Employee.findById(req.user.id);
    } else if (req.user.role === 'admin') {
      user = await Admin.findById(req.user.id);
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
