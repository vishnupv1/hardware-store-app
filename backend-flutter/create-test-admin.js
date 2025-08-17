const mongoose = require('mongoose');
const Admin = require('./src/models/Admin');
require('dotenv').config();

async function createTestAdmin() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Check if test admin already exists
    const existingAdmin = await Admin.findOne({ email: 'admin@test.com' });
    if (existingAdmin) {
      console.log('⚠️ Test admin already exists');
      console.log('Email: admin@test.com');
      console.log('Password: Admin123!');
      return;
    }

    // Create test admin
    const testAdmin = new Admin({
      email: 'admin@test.com',
      password: 'Admin123!',
      firstName: 'Test',
      lastName: 'Admin',
      phoneNumber: '+1234567890',
      adminId: 'ADM24001',
      department: 'IT',
      position: 'System Administrator',
      hireDate: new Date(),
      salary: 75000,
      adminLevel: 'admin',
      isActive: true,
      isEmailVerified: true,
      permissions: [
        'manage_system_settings',
        'manage_all_users',
        'manage_employees',
        'manage_clients',
        'manage_admins',
        'manage_business_settings',
        'view_advanced_analytics',
        'export_data',
        'generate_reports',
        'view_audit_logs',
        'manage_dashboards',
        'view_dashboard',
        'manage_customers',
        'manage_products',
        'manage_sales',
        'manage_inventory',
        'manage_reports',
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
      ],
      accessLevel: 'full_access',
      allowedModules: [
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
    });

    await testAdmin.save();
    console.log('✅ Test admin created successfully');
    console.log('Email: admin@test.com');
    console.log('Password: Admin123!');
    console.log('Admin ID: ADM24001');

  } catch (error) {
    console.error('❌ Error creating test admin:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

createTestAdmin();
