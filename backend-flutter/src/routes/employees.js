const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, authorize } = require('../middleware/auth');
const Employee = require('../models/Employee');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);

// @route   GET /api/employees
// @desc    Get all employees (admin only)
// @access  Private
router.get('/', authorize('admin'), async (req, res) => {
  try {
    const { page = 1, limit = 20, search, department, role, isActive } = req.query;
    
    const query = {};
    
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { employeeId: { $regex: search, $options: 'i' } },
        { department: { $regex: search, $options: 'i' } },
        { position: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (department) query.department = department;
    if (role) query.role = role;
    if (isActive !== undefined) query.isActive = isActive === 'true';
    
    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { createdAt: -1 },
      select: '-password'
    };
    
    const employees = await Employee.paginate(query, options);
    
    res.json({
      success: true,
      data: employees
    });
  } catch (error) {
    console.error('Get employees error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/employees/profile
// @desc    Get employee profile
// @access  Private
router.get('/profile', async (req, res) => {
  try {
    const employee = await Employee.findById(req.user.id).select('-password');
    
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found',
      });
    }

    res.json({
      success: true,
      data: {
        employee,
      },
    });
  } catch (error) {
    console.error('Get employee profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/employees/:id
// @desc    Get employee by ID (admin only)
// @access  Private
router.get('/:id', authorize('admin'), async (req, res) => {
  try {
    const employee = await Employee.findById(req.params.id).select('-password');
    
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found',
      });
    }

    res.json({
      success: true,
      data: {
        employee,
      },
    });
  } catch (error) {
    console.error('Get employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/employees/profile
// @desc    Update employee profile
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

    const employee = await Employee.findById(req.user.id);
    
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found',
      });
    }

    // Update fields
    const updateFields = ['firstName', 'lastName', 'phoneNumber', 'avatar'];
    
    updateFields.forEach(field => {
      if (req.body[field] !== undefined) {
        employee[field] = req.body[field];
      }
    });

    await employee.save();

    // Remove password from response
    employee.password = undefined;

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        employee,
      },
    });
  } catch (error) {
    console.error('Update employee profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/employees/:id
// @desc    Update employee (admin only)
// @access  Private
router.put('/:id', authorize('admin'), [
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
  body('role')
    .optional()
    .isIn(['employee', 'manager', 'admin', 'supervisor'])
    .withMessage('Invalid role'),
  body('salary')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Salary must be a positive number'),
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

    const employee = await Employee.findById(req.params.id);
    
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found',
      });
    }

    // Update fields
    const updateFields = [
      'firstName', 'lastName', 'phoneNumber', 'avatar', 
      'department', 'position', 'role', 'salary', 'isActive'
    ];
    
    updateFields.forEach(field => {
      if (req.body[field] !== undefined) {
        employee[field] = req.body[field];
      }
    });

    await employee.save();

    // Remove password from response
    employee.password = undefined;

    res.json({
      success: true,
      message: 'Employee updated successfully',
      data: {
        employee,
      },
    });
  } catch (error) {
    console.error('Update employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/employees/change-password
// @desc    Change employee password
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

    const employee = await Employee.findById(req.user.id).select('+password');
    
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found',
      });
    }

    // Verify current password
    const isPasswordValid = await employee.comparePassword(currentPassword);
    if (!isPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    employee.password = newPassword;
    await employee.save();

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

// @route   POST /api/employees
// @desc    Create new employee (admin only)
// @access  Private
router.post('/', authorize('admin'), [
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
  body('role')
    .optional()
    .isIn(['employee', 'manager', 'admin', 'supervisor'])
    .withMessage('Invalid role'),
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
      role = 'employee',
      salary,
      hireDate
    } = req.body;

    // Check if employee already exists
    const existingEmployee = await Employee.findByEmail(email);
    if (existingEmployee) {
      return res.status(400).json({
        success: false,
        message: 'Employee with this email already exists',
      });
    }

    // Generate employee ID
    const employeeId = await Employee.generateEmployeeId();

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
      hireDate: hireDate || new Date(),
      permissions: getDefaultPermissions(role)
    });

    await employee.save();

    // Remove password from response
    employee.password = undefined;

    res.status(201).json({
      success: true,
      message: 'Employee created successfully',
      data: {
        employee,
      },
    });
  } catch (error) {
    console.error('Create employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/employees/:id
// @desc    Delete employee (admin only)
// @access  Private
router.delete('/:id', authorize('admin'), async (req, res) => {
  try {
    const employee = await Employee.findById(req.params.id);
    
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found',
      });
    }

    // Prevent deleting self
    if (employee._id.toString() === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account',
      });
    }

    await Employee.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Employee deleted successfully',
    });
  } catch (error) {
    console.error('Delete employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/employees/stats/summary
// @desc    Get employee statistics (admin only)
// @access  Private
router.get('/stats/summary', authorize('admin'), async (req, res) => {
  try {
    const totalEmployees = await Employee.countDocuments();
    const activeEmployees = await Employee.countDocuments({ isActive: true });
    const inactiveEmployees = totalEmployees - activeEmployees;
    
    const employeesByRole = await Employee.aggregate([
      { $group: { _id: '$role', count: { $sum: 1 } } }
    ]);
    
    const employeesByDepartment = await Employee.aggregate([
      { $group: { _id: '$department', count: { $sum: 1 } } }
    ]);
    
    const recentHires = await Employee.find({ isActive: true })
      .sort({ hireDate: -1 })
      .limit(5)
      .select('firstName lastName employeeId department position hireDate');

    res.json({
      success: true,
      data: {
        totalEmployees,
        activeEmployees,
        inactiveEmployees,
        employeesByRole,
        employeesByDepartment,
        recentHires
      }
    });
  } catch (error) {
    console.error('Get employee stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
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

module.exports = router;
