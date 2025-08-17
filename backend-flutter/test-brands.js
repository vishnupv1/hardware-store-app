const mongoose = require('mongoose');
const Brand = require('./src/models/Brand');

// Test the Brand model
async function testBrandModel() {
  try {
    console.log('Testing Brand model...');
    
    // Test creating a brand
    const testBrand = new Brand({
      name: 'Test Brand',
      description: 'A test brand for validation',
      isActive: true,
      clientId: new mongoose.Types.ObjectId(),
      createdBy: new mongoose.Types.ObjectId(),
    });
    
    console.log('Brand model created successfully');
    console.log('Brand schema:', testBrand.schema.obj);
    
    // Test validation
    const validationError = testBrand.validateSync();
    if (validationError) {
      console.error('Validation errors:', validationError.errors);
    } else {
      console.log('Brand model validation passed');
    }
    
  } catch (error) {
    console.error('Error testing Brand model:', error);
  }
}

testBrandModel();
