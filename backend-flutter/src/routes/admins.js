const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Admin = require('../models/Admin');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);

// @route   GET /api/admins
// @desc    Get all admins (super admin only)
// @access  Private
router.get('/', authorize('super_admin'), async (req, res) => {
  try {
    const { page = 1, limit = 20, search, department, adminLevel, isActive } = req.query;
    
    const query = {};
    
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { adminId: { $regex: search, $options: 'i' } },
        { department: { $regex: search, $options: 'i' } },
        { position: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (department) query.department = department;
    if (adminLevel) query.adminLevel = adminLevel;
    if (isActive !== undefined) query.isActive = isActive === 'true';
    
    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { createdAt: -1 },
      select: '-password -twoFactorSecret'
    };
    
    const admins = await Admin.paginate(query, options);
    
    res.json({
      success: true,
      data: admins
    });
  } catch (error) {
    console.error('Get admins error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/admins/profile
// @desc    Get admin profile
// @access  Private
router.get('/profile', async (req, res) => {
  try {
    const admin = await Admin.findById(req.user.id).select('-password -twoFactorSecret');
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    res.json({
      success: true,
      data: {
        admin,
      },
    });
  } catch (error) {
    console.error('Get admin profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/admins/:id
// @desc    Get admin by ID (super admin only)
// @access  Private
router.get('/:id', authorize('super_admin'), async (req, res) => {
  try {
    const admin = await Admin.findById(req.params.id).select('-password -twoFactorSecret');
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    res.json({
      success: true,
      data: {
        admin,
      },
    });
  } catch (error) {
    console.error('Get admin error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/admins/profile
// @desc    Update admin profile
// @access  Private
router.put('/profile', [
  body('firstName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters'),
  body('lastName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters'),
  body('phoneNumber')
    .optional()
    .trim()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
  body('avatar')
    .optional()
    .isURL()
    .withMessage('Please enter a valid avatar URL'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const admin = await Admin.findById(req.user.id);
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    // Update fields
    const updateFields = ['firstName', 'lastName', 'phoneNumber', 'avatar'];
    
    updateFields.forEach(field => {
      if (req.body[field] !== undefined) {
        admin[field] = req.body[field];
      }
    });

    await admin.save();

    // Remove sensitive fields from response
    admin.password = undefined;
    admin.twoFactorSecret = undefined;

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        admin,
      },
    });
  } catch (error) {
    console.error('Update admin profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/admins/:id
// @desc    Update admin (super admin only)
// @access  Private
router.put('/:id', authorize('super_admin'), [
  body('firstName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters'),
  body('lastName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters'),
  body('phoneNumber')
    .optional()
    .trim()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
  body('department')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Department must be between 2 and 100 characters'),
  body('position')
    .optional()
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
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean'),
  body('sessionTimeout')
    .optional()
    .isInt({ min: 5, max: 480 })
    .withMessage('Session timeout must be between 5 and 480 minutes'),
  body('passwordExpiryDays')
    .optional()
    .isInt({ min: 30, max: 365 })
    .withMessage('Password expiry must be between 30 and 365 days'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const admin = await Admin.findById(req.params.id);
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    // Prevent super admin from being demoted
    if (admin.adminLevel === 'super_admin' && req.body.adminLevel && req.body.adminLevel !== 'super_admin') {
      return res.status(400).json({
        success: false,
        message: 'Cannot demote super admin',
      });
    }

    // Update fields
    const updateFields = [
      'firstName', 'lastName', 'phoneNumber', 'avatar', 
      'department', 'position', 'adminLevel', 'accessLevel', 'salary', 'isActive',
      'sessionTimeout', 'passwordExpiryDays', 'allowedModules', 'permissions'
    ];
    
    updateFields.forEach(field => {
      if (req.body[field] !== undefined) {
        admin[field] = req.body[field];
      }
    });

    await admin.save();

    // Remove sensitive fields from response
    admin.password = undefined;
    admin.twoFactorSecret = undefined;

    res.json({
      success: true,
      message: 'Admin updated successfully',
      data: {
        admin,
      },
    });
  } catch (error) {
    console.error('Update admin error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/admins/change-password
// @desc    Change admin password
// @access  Private
router.put('/change-password', [
  body('currentPassword')
    .notEmpty()
    .withMessage('Current password is required'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { currentPassword, newPassword } = req.body;

    const admin = await Admin.findById(req.user.id).select('+password');
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    // Verify current password
    const isPasswordValid = await admin.comparePassword(currentPassword);
    if (!isPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    admin.password = newPassword;
    await admin.save();

    res.json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/admins
// @desc    Create new admin (super admin only)
// @access  Private
router.post('/', authorize('super_admin'), [
  body('email')
    .isEmail()
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
  body('phoneNumber')
    .optional()
    .trim()
    .matches(/^\+?[\d\s\-\(\)]+$/)
    .withMessage('Please enter a valid phone number'),
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
  body('hireDate')
    .optional()
    .isISO8601()
    .withMessage('Please enter a valid hire date'),
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
      department,
      position,
      adminLevel = 'admin',
      accessLevel = 'limited_access',
      salary,
      hireDate
    } = req.body;

    // Check if admin already exists
    const existingAdmin = await Admin.findByEmail(email);
    if (existingAdmin) {
      return res.status(400).json({
        success: false,
        message: 'Admin with this email already exists',
      });
    }

    // Generate admin ID
    const adminId = await Admin.generateAdminId();

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
      hireDate: hireDate || new Date(),
      permissions: getDefaultPermissions(adminLevel),
      allowedModules: getDefaultModules(accessLevel)
    });

    await admin.save();

    // Remove sensitive fields from response
    admin.password = undefined;
    admin.twoFactorSecret = undefined;

    res.status(201).json({
      success: true,
      message: 'Admin created successfully',
      data: {
        admin,
      },
    });
  } catch (error) {
    console.error('Create admin error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/admins/:id
// @desc    Delete admin (super admin only)
// @access  Private
router.delete('/:id', authorize('super_admin'), async (req, res) => {
  try {
    const admin = await Admin.findById(req.params.id);
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    // Prevent deleting self
    if (admin._id.toString() === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account',
      });
    }

    // Prevent deleting super admin
    if (admin.adminLevel === 'super_admin') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete super admin',
      });
    }

    await Admin.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Admin deleted successfully',
    });
  } catch (error) {
    console.error('Delete admin error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/admins/stats/summary
// @desc    Get admin statistics (super admin only)
// @access  Private
router.get('/stats/summary', authorize('super_admin'), async (req, res) => {
  try {
    const stats = await Admin.getAdminStats();
    
    const adminsByDepartment = await Admin.aggregate([
      { $group: { _id: '$department', count: { $sum: 1 } } }
    ]);
    
    const recentHires = await Admin.find({ isActive: true })
      .sort({ hireDate: -1 })
      .limit(5)
      .select('firstName lastName adminId department position hireDate adminLevel');

    res.json({
      success: true,
      data: {
        ...stats,
        adminsByDepartment,
        recentHires
      }
    });
  } catch (error) {
    console.error('Get admin stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// Helper function to get default permissions based on admin level
function getDefaultPermissions(adminLevel) {
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

// Helper function to get default modules based on access level
function getDefaultModules(accessLevel) {
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

module.exports = router;
