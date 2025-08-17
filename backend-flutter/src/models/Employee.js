const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const employeeSchema = new mongoose.Schema({
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
  employeeId: {
    type: String,
    required: [true, 'Employee ID is required'],
    unique: true,
    trim: true,
    maxlength: [20, 'Employee ID cannot exceed 20 characters']
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
  role: {
    type: String,
    enum: ['employee', 'manager', 'admin', 'supervisor'],
    default: 'employee'
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
  }]
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for full name
employeeSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

// Virtual for account lock status
employeeSchema.virtual('isLocked').get(function() {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

// Virtual for years of service
employeeSchema.virtual('yearsOfService').get(function() {
  const now = new Date();
  const hireDate = this.hireDate;
  const diffTime = Math.abs(now - hireDate);
  const diffYears = Math.ceil(diffTime / (1000 * 60 * 60 * 24 * 365));
  return diffYears;
});

// Index for better query performance
employeeSchema.index({ email: 1 });
employeeSchema.index({ employeeId: 1 });
employeeSchema.index({ createdAt: -1 });
employeeSchema.index({ isActive: 1 });
employeeSchema.index({ department: 1 });
employeeSchema.index({ role: 1 });

// Pre-save middleware to hash password
employeeSchema.pre('save', async function(next) {
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified('password')) return next();

  try {
    // Hash password with cost of 12
    const hashedPassword = await bcrypt.hash(this.password, 12);
    this.password = hashedPassword;
    next();
  } catch (error) {
    next(error);
  }
});

// Instance method to check password
employeeSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Instance method to increment login attempts
employeeSchema.methods.incLoginAttempts = function() {
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
employeeSchema.methods.resetLoginAttempts = function() {
  return this.updateOne({
    $unset: { loginAttempts: 1, lockUntil: 1 }
  });
};

// Instance method to check if employee has permission
employeeSchema.methods.hasPermission = function(permission) {
  return this.permissions.includes(permission);
};

// Instance method to add permission
employeeSchema.methods.addPermission = function(permission) {
  if (!this.permissions.includes(permission)) {
    this.permissions.push(permission);
  }
  return this.save();
};

// Instance method to remove permission
employeeSchema.methods.removePermission = function(permission) {
  this.permissions = this.permissions.filter(p => p !== permission);
  return this.save();
};

// Static method to find employee by email
employeeSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

// Static method to find employee by employee ID
employeeSchema.statics.findByEmployeeId = function(employeeId) {
  return this.findOne({ employeeId: employeeId });
};

// Static method to find active employees
employeeSchema.statics.findActive = function() {
  return this.find({ isActive: true });
};

// Static method to find employees by department
employeeSchema.statics.findByDepartment = function(department) {
  return this.find({ department: department, isActive: true });
};

// Static method to find employees by role
employeeSchema.statics.findByRole = function(role) {
  return this.find({ role: role, isActive: true });
};

// Static method to generate employee ID
employeeSchema.statics.generateEmployeeId = async function() {
  const prefix = 'EMP';
  const year = new Date().getFullYear().toString().slice(-2);
  
  // Find the highest employee ID for this year
  const lastEmployee = await this.findOne({
    employeeId: new RegExp(`^${prefix}${year}`)
  }).sort({ employeeId: -1 });
  
  let sequence = 1;
  if (lastEmployee) {
    const lastSequence = parseInt(lastEmployee.employeeId.slice(-4));
    sequence = lastSequence + 1;
  }
  
  return `${prefix}${year}${sequence.toString().padStart(4, '0')}`;
};

module.exports = mongoose.model('Employee', employeeSchema);
