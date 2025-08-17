const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Client = require('../models/Client');
const Admin = require('../models/Admin');
const Employee = require('../models/Employee');

const auth = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.header('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token, authorization denied',
      });
    }

    // Verify token
    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if user/client/admin/employee exists and is active
    let user;
    
    if (decoded.role === 'user') {
      user = await User.findById(decoded.id).select('-password');
      if (!user || !user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Token is not valid or user is inactive',
        });
      }
    } else if (decoded.role === 'client') {
      user = await Client.findById(decoded.id).select('-password');
      if (!user || !user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Token is not valid or client is inactive',
        });
      }
      
      // Check subscription status for clients
      if (!user.isSubscriptionActive) {
        return res.status(402).json({
          success: false,
          message: 'Subscription is not active',
        });
      }
    } else if (decoded.role === 'admin') {
      user = await Admin.findById(decoded.id).select('-password');
      if (!user || !user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Token is not valid or admin is inactive',
        });
      }
      
      // Check if admin is locked
      if (user.isLocked) {
        return res.status(401).json({
          success: false,
          message: 'Account is temporarily locked due to multiple failed login attempts',
        });
      }
    } else if (decoded.role === 'employee') {
      user = await Employee.findById(decoded.id).select('-password');
      if (!user || !user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Token is not valid or employee is inactive',
        });
      }
      
      // Check if employee is locked
      if (user.isLocked) {
        return res.status(401).json({
          success: false,
          message: 'Account is temporarily locked due to multiple failed login attempts',
        });
      }
    } else {
      return res.status(401).json({
        success: false,
        message: 'Invalid token role',
      });
    }

    console.log('✅ Auth middleware: Authentication successful');
    console.log('✅ Auth middleware: User role:', decoded.role);
    console.log('✅ Auth middleware: User ID:', decoded.id);
    
    req.user = decoded;
    req.userData = user;
    next();
  } catch (error) {
    console.error('🚨 Auth middleware error:', error);
    console.error('🚨 Auth middleware error type:', error.name);

    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token is not valid',
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token has expired',
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Server error in authentication',
    });
  }
};

// Optional auth middleware for routes that can work with or without authentication
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(); // Continue without authentication
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    let user;
    if (decoded.role === 'user') {
      user = await User.findById(decoded.id).select('-password');
    } else if (decoded.role === 'client') {
      user = await Client.findById(decoded.id).select('-password');
    } else if (decoded.role === 'admin') {
      user = await Admin.findById(decoded.id).select('-password');
    } else if (decoded.role === 'employee') {
      user = await Employee.findById(decoded.id).select('-password');
    }

    if (user && user.isActive) {
      req.user = decoded;
      req.userData = user;
    }
    
    next();
  } catch (error) {
    // Continue without authentication if token is invalid
    next();
  }
};

// Role-based authorization middleware
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Access denied, no token provided',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied, insufficient permissions',
      });
    }

    next();
  };
};

// Permission-based authorization middleware
const requirePermission = (permission) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Access denied, no token provided',
      });
    }

    if (!req.userData) {
      return res.status(401).json({
        success: false,
        message: 'User data not found',
      });
    }

    // Check if user has the required permission
    if (!req.userData.hasPermission || !req.userData.hasPermission(permission)) {
      return res.status(403).json({
        success: false,
        message: `Access denied, permission '${permission}' required`,
      });
    }

    next();
  };
};

// Admin-only authorization middleware
const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Access denied, no token provided',
    });
  }

  if (req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied, admin privileges required',
    });
  }

  next();
};

// Employee or Admin authorization middleware
const requireEmployeeOrAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Access denied, no token provided',
    });
  }

  if (!['employee', 'admin'].includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: 'Access denied, employee or admin privileges required',
    });
  }

  next();
};

module.exports = { 
  auth, 
  optionalAuth, 
  authorize, 
  requirePermission, 
  requireAdmin, 
  requireEmployeeOrAdmin 
};
