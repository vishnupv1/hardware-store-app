const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

// Test the new brands endpoint
async function testNewBrandsEndpoint() {
  try {
    console.log('Testing new brands endpoint...');
    
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/flutterapp');
    console.log('Connected to database');
    
    // Import the Brand model
    const Brand = require('./src/models/Brand');
    
    // Test creating a brand
    const testBrand = new Brand({
      name: 'Test Brand',
      description: 'A test brand',
      isActive: true,
      clientId: new mongoose.Types.ObjectId(),
      createdBy: new mongoose.Types.ObjectId(),
    });
    
    console.log('Brand model created successfully');
    console.log('Brand name:', testBrand.name);
    console.log('Brand description:', testBrand.description);
    
    // Test validation
    const validationError = testBrand.validateSync();
    if (validationError) {
      console.error('Validation errors:', validationError.errors);
    } else {
      console.log('Brand model validation passed');
    }
    
    await mongoose.disconnect();
    console.log('Disconnected from database');
    
  } catch (error) {
    console.error('Error testing new brands endpoint:', error);
  }
}

testNewBrandsEndpoint();
