const mongoose = require('mongoose');
const Admin = require('./src/models/Admin');
require('dotenv').config();

async function checkAdmin() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find admin by email
    const admin = await Admin.findOne({ email: 'admin@test.com' });
    
    if (admin) {
      console.log('✅ Admin found:');
      console.log('Email:', admin.email);
      console.log('Admin ID:', admin.adminId);
      console.log('First Name:', admin.firstName);
      console.log('Last Name:', admin.lastName);
      console.log('Is Active:', admin.isActive);
      console.log('Is Locked:', admin.isLocked);
      console.log('Admin Level:', admin.adminLevel);
      console.log('Permissions count:', admin.permissions.length);
    } else {
      console.log('❌ Admin not found');
      
      // List all admins
      const allAdmins = await Admin.find({});
      console.log('All admins in database:');
      allAdmins.forEach(admin => {
        console.log(`- ${admin.email} (${admin.adminId})`);
      });
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

checkAdmin();
