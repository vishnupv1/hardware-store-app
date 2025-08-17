const express = require('express');
const mongoose = require('mongoose');
const { auth, authorize } = require('../middleware/auth');
const Customer = require('../models/Customer');
const Product = require('../models/Product');
const Sale = require('../models/Sale');

const router = express.Router();

// Apply auth middleware to all routes
router.use(auth);
router.use(authorize('client', 'admin', 'user'));

// @route   GET /api/dashboard/stats
// @desc    Get all dashboard statistics in a single call
// @access  Private
router.get('/stats', async (req, res) => {
  try {
    const startDate = req.query.startDate ? new Date(req.query.startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
    const endDate = req.query.endDate ? new Date(req.query.endDate) : new Date();

    // Get customer statistics
    const customerPipeline = [
      { $match: { clientId:new mongoose.Types.ObjectId(req.user.id) } },
      {
        $group: {
          _id: null,
          totalCustomers: { $sum: 1 },
          activeCustomers: { $sum: { $cond: ['$isActive', 1, 0] } },
          wholesaleCustomers: { $sum: { $cond: [{ $eq: ['$customerType', 'wholesale'] }, 1, 0] } },
          retailCustomers: { $sum: { $cond: [{ $eq: ['$customerType', 'retail'] }, 1, 0] } },
          contractorCustomers: { $sum: { $cond: [{ $eq: ['$customerType', 'contractor'] }, 1, 0] } },
          totalCreditLimit: { $sum: { $ifNull: ['$creditLimit', 0] } },
          totalCurrentBalance: { $sum: { $ifNull: ['$currentBalance', 0] } },
          customersOverLimit: { $sum: { $cond: [{ $gt: [{ $ifNull: ['$currentBalance', 0] }, { $ifNull: ['$creditLimit', 0] }] }, 1, 0] } }
        }
      }
    ];

    // Get product statistics
    const productPipeline = [
      { $match: { clientId: new mongoose.Types.ObjectId(req.user.id) } },
      {
        $group: {
          _id: null,
          totalProducts: { $sum: 1 },
          activeProducts: { $sum: { $cond: ['$isActive', 1, 0] } },
          totalStockValue: { $sum: { $multiply: [{ $ifNull: ['$stockQuantity', 0] }, { $ifNull: ['$costPrice', 0] }] } },
          totalStockQuantity: { $sum: { $ifNull: ['$stockQuantity', 0] } },
          lowStockProducts: { $sum: { $cond: [{ $lte: [{ $ifNull: ['$stockQuantity', 0] }, { $ifNull: ['$minStockLevel', 0] }] }, 1, 0] } },
          outOfStockProducts: { $sum: { $cond: [{ $eq: [{ $ifNull: ['$stockQuantity', 0] }, 0] }, 1, 0] } },
          totalRevenue: { $sum: { $ifNull: ['$totalRevenue', 0] } },
          totalSold: { $sum: { $ifNull: ['$totalSold', 0] } }
        }
      }
    ];

    // Get sales statistics
    const salesPipeline = [
      { $match: { clientId: new mongoose.Types.ObjectId(req.user.id) } },
      { $match: { saleDate: { $gte: startDate, $lte: endDate } } },
      { $match: { saleStatus: 'completed' } },
      {
        $group: {
          _id: null,
          totalSales: { $sum: 1 },
          totalRevenue: { $sum: { $ifNull: ['$totalAmount', 0] } },
          totalItems: { $sum: { $ifNull: ['$totalItems', 0] } },
          averageOrderValue: { $avg: { $ifNull: ['$totalAmount', 0] } }
        }
      }
    ];

    // Execute all aggregations in parallel
    const customerCount = await Customer.countDocuments({ clientId: new mongoose.Types.ObjectId(req.user.id) });
    const productCount = await Product.countDocuments({ clientId: new mongoose.Types.ObjectId(req.user.id) });
    const saleCount = await Sale.countDocuments({ clientId: new mongoose.Types.ObjectId(req.user.id) });
    
    const [customerStats, productStats, salesStats] = await Promise.all([
      Customer.aggregate(customerPipeline),
      Product.aggregate(productPipeline),
      Sale.aggregate(salesPipeline)
    ]);

    // Get recent activity (last 5 sales, customers, products)
    const recentSales = await Sale.find({ clientId: new mongoose.Types.ObjectId(req.user.id) })
      .populate('customerId', 'name')
      .sort({ createdAt: -1 })
      .limit(5)
      .select('invoiceNumber customerName totalAmount saleDate saleStatus');

    const recentCustomers = await Customer.find({ clientId: new mongoose.Types.ObjectId(req.user.id) })
      .sort({ createdAt: -1 })
      .limit(5)
      .select('name email phoneNumber customerType createdAt');

    const lowStockProducts = await Product.find({
      clientId: new mongoose.Types.ObjectId(req.user.id),
      $expr: { $lte: ['$stockQuantity', '$minStockLevel'] }
    })
      .sort({ stockQuantity: 1 })
      .limit(5)
      .select('name sku stockQuantity minStockLevel');

    // Compile dashboard data with fallbacks
    
    const dashboardData = {
      customerStats: customerStats[0] || {
        totalCustomers: customerCount,
        activeCustomers: 0,
        wholesaleCustomers: 0,
        retailCustomers: 0,
        contractorCustomers: 0,
        totalCreditLimit: 0,
        totalCurrentBalance: 0,
        customersOverLimit: 0
      },
      productStats: productStats[0] || {
        totalProducts: productCount,
        activeProducts: 0,
        totalStockValue: 0,
        totalStockQuantity: 0,
        lowStockProducts: 0,
        outOfStockProducts: 0,
        totalRevenue: 0,
        totalSold: 0
      },
      salesStats: salesStats[0] || {
        totalSales: saleCount,
        totalRevenue: 0,
        totalItems: 0,
        averageOrderValue: 0
      },
      recentActivity: {
        recentSales,
        recentCustomers,
        lowStockProducts
      }
    };

    res.json({
      success: true,
      data: dashboardData
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;
