const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [
      /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
      'Please enter a valid email address'
    ]
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters long'],
    select: false // Don't include password in queries by default
  },
  role: {
    type: String,
    required: [true, 'Role is required'],
    enum: ['admin', 'manager', 'super_admin'],
    default: 'admin'
  },
  firstName: {
    type: String,
    required: [true, 'First name is required'],
    trim: true,
    maxlength: [50, 'First name cannot exceed 50 characters']
  },
  lastName: {
    type: String,
    required: [true, 'Last name is required'],
    trim: true,
    maxlength: [50, 'Last name cannot exceed 50 characters']
  },
  phoneNumber: {
    type: String,
    trim: true,
    match: [
      /^\+?[\d\s\-\(\)]+$/,
      'Please enter a valid phone number'
    ]
  },
  avatar: {
    type: String,
    default: null
  },
  adminId: {
    type: String,
    required: [true, 'Admin ID is required'],
    unique: true,
    trim: true,
    maxlength: [20, 'Admin ID cannot exceed 20 characters']
  },
  department: {
    type: String,
    required: [true, 'Department is required'],
    trim: true,
    maxlength: [100, 'Department cannot exceed 100 characters']
  },
  position: {
    type: String,
    required: [true, 'Position is required'],
    trim: true,
    maxlength: [100, 'Position cannot exceed 100 characters']
  },
  hireDate: {
    type: Date,
    required: [true, 'Hire date is required'],
    default: Date.now
  },
  salary: {
    type: Number,
    min: [0, 'Salary cannot be negative']
  },
  adminLevel: {
    type: String,
    enum: ['super_admin', 'admin', 'manager'],
    default: 'admin'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  passwordResetToken: String,
  passwordResetExpires: Date,
  lastLogin: {
    type: Date,
    default: null
  },
  loginAttempts: {
    type: Number,
    default: 0
  },
  lockUntil: {
    type: Date,
    default: null
  },
  permissions: [{
    type: String,
    enum: [
      // System Management
      'manage_system_settings',
      'manage_database',
      'manage_backups',
      'manage_security',
      'view_system_logs',
      'manage_api_keys',
      
      // User Management
      'manage_all_users',
      'manage_employees',
      'manage_clients',
      'manage_admins',
      'view_user_logs',
      'reset_user_passwords',
      'suspend_users',
      'delete_users',
      
      // Business Management
      'manage_business_settings',
      'manage_company_info',
      'manage_billing',
      'manage_subscriptions',
      'view_financial_reports',
      'manage_tax_settings',
      
      // Content Management
      'manage_content',
      'manage_templates',
      'manage_notifications',
      'manage_announcements',
      'manage_help_docs',
      
      // Advanced Analytics
      'view_advanced_analytics',
      'export_data',
      'generate_reports',
      'view_audit_logs',
      'manage_dashboards',
      
      // All Employee Permissions
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
      'view_customers',
      'create_customers',
      'edit_customers',
      'delete_customers',
      'view_products',
      'create_products',
      'edit_products',
      'delete_products'
    ]
  }],
  accessLevel: {
    type: String,
    enum: ['full_access', 'limited_access', 'read_only'],
    default: 'limited_access'
  },
  allowedModules: [{
    type: String,
    enum: [
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
  }],
  ipWhitelist: [{
    type: String,
    trim: true
  }],
  sessionTimeout: {
    type: Number,
    default: 30, // minutes
    min: [5, 'Session timeout must be at least 5 minutes'],
    max: [480, 'Session timeout cannot exceed 8 hours']
  },
  twoFactorEnabled: {
    type: Boolean,
    default: false
  },
  twoFactorSecret: {
    type: String,
    select: false
  },
  lastPasswordChange: {
    type: Date,
    default: Date.now
  },
  passwordExpiryDays: {
    type: Number,
    default: 90,
    min: [30, 'Password expiry must be at least 30 days'],
    max: [365, 'Password expiry cannot exceed 1 year']
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for full name
adminSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

// Virtual for account lock status
adminSchema.virtual('isLocked').get(function() {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

// Virtual for years of service
adminSchema.virtual('yearsOfService').get(function() {
  const now = new Date();
  const hireDate = this.hireDate;
  const diffTime = Math.abs(now - hireDate);
  const diffYears = Math.ceil(diffTime / (1000 * 60 * 60 * 24 * 365));
  return diffYears;
});

// Virtual for password expiry status
adminSchema.virtual('isPasswordExpired').get(function() {
  const now = new Date();
  const expiryDate = new Date(this.lastPasswordChange);
  expiryDate.setDate(expiryDate.getDate() + this.passwordExpiryDays);
  return now > expiryDate;
});

// Virtual for days until password expiry
adminSchema.virtual('daysUntilPasswordExpiry').get(function() {
  const now = new Date();
  const expiryDate = new Date(this.lastPasswordChange);
  expiryDate.setDate(expiryDate.getDate() + this.passwordExpiryDays);
  const diffTime = expiryDate - now;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return Math.max(0, diffDays);
});

// Index for better query performance
adminSchema.index({ email: 1 });
adminSchema.index({ adminId: 1 });
adminSchema.index({ createdAt: -1 });
adminSchema.index({ isActive: 1 });
adminSchema.index({ department: 1 });
adminSchema.index({ adminLevel: 1 });

// Pre-save middleware to hash password
adminSchema.pre('save', async function(next) {
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified('password')) return next();

  try {
    // Hash password with cost of 12
    const hashedPassword = await bcrypt.hash(this.password, 12);
    this.password = hashedPassword;
    this.lastPasswordChange = new Date();
    next();
  } catch (error) {
    next(error);
  }
});

// Instance method to check password
adminSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Instance method to increment login attempts
adminSchema.methods.incLoginAttempts = function() {
  // If we have a previous lock that has expired, restart at 1
  if (this.lockUntil && this.lockUntil < Date.now()) {
    return this.updateOne({
      $unset: { lockUntil: 1 },
      $set: { loginAttempts: 1 }
    });
  }
  
  const updates = { $inc: { loginAttempts: 1 } };
  
  // Lock account after 5 failed attempts
  if (this.loginAttempts + 1 >= 5 && !this.isLocked) {
    updates.$set = { lockUntil: Date.now() + 2 * 60 * 60 * 1000 }; // 2 hours
  }
  
  return this.updateOne(updates);
};

// Instance method to reset login attempts
adminSchema.methods.resetLoginAttempts = function() {
  return this.updateOne({
    $unset: { loginAttempts: 1, lockUntil: 1 }
  });
};

// Instance method to check if admin has permission
adminSchema.methods.hasPermission = function(permission) {
  return this.permissions.includes(permission);
};

// Instance method to add permission
adminSchema.methods.addPermission = function(permission) {
  if (!this.permissions.includes(permission)) {
    this.permissions.push(permission);
  }
  return this.save();
};

// Instance method to remove permission
adminSchema.methods.removePermission = function(permission) {
  this.permissions = this.permissions.filter(p => p !== permission);
  return this.save();
};

// Instance method to check if admin can access module
adminSchema.methods.canAccessModule = function(module) {
  return this.allowedModules.includes(module);
};

// Instance method to check if admin has full access
adminSchema.methods.hasFullAccess = function() {
  return this.accessLevel === 'full_access';
};

// Instance method to check if admin is super admin
adminSchema.methods.isSuperAdmin = function() {
  return this.adminLevel === 'super_admin';
};

// Static method to find admin by email
adminSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

// Static method to find admin by admin ID
adminSchema.statics.findByAdminId = function(adminId) {
  return this.findOne({ adminId: adminId });
};

// Static method to find active admins
adminSchema.statics.findActive = function() {
  return this.find({ isActive: true });
};

// Static method to find admins by level
adminSchema.statics.findByLevel = function(level) {
  return this.find({ adminLevel: level, isActive: true });
};

// Static method to find admins by department
adminSchema.statics.findByDepartment = function(department) {
  return this.find({ department: department, isActive: true });
};

// Static method to generate admin ID
adminSchema.statics.generateAdminId = async function() {
  const prefix = 'ADM';
  const year = new Date().getFullYear().toString().slice(-2);
  
  // Find the highest admin ID for this year
  const lastAdmin = await this.findOne({
    adminId: new RegExp(`^${prefix}${year}`)
  }).sort({ adminId: -1 });
  
  let sequence = 1;
  if (lastAdmin) {
    const lastSequence = parseInt(lastAdmin.adminId.slice(-4));
    sequence = lastSequence + 1;
  }
  
  return `${prefix}${year}${sequence.toString().padStart(4, '0')}`;
};

// Static method to get admin statistics
adminSchema.statics.getAdminStats = async function() {
  const totalAdmins = await this.countDocuments();
  const activeAdmins = await this.countDocuments({ isActive: true });
  const superAdmins = await this.countDocuments({ adminLevel: 'super_admin' });
  const adminsByLevel = await this.aggregate([
    { $group: { _id: '$adminLevel', count: { $sum: 1 } } }
  ]);
  
  return {
    totalAdmins,
    activeAdmins,
    inactiveAdmins: totalAdmins - activeAdmins,
    superAdmins,
    adminsByLevel
  };
};

module.exports = mongoose.model('Admin', adminSchema);
