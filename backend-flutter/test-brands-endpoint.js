const axios = require('axios');

async function testBrandsEndpoint() {
  try {
    console.log('Testing brands endpoint...');
    
    // Test the new /api/brands endpoint
    const response = await axios.get('http://localhost:3001/api/brands', {
      headers: {
        'Authorization': 'Bearer YOUR_TOKEN_HERE', // You'll need to replace this with a valid token
        'Content-Type': 'application/json'
      }
    });
    
    console.log('Response status:', response.status);
    console.log('Response data:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('Error testing brands endpoint:', error.response?.data || error.message);
  }
}

testBrandsEndpoint();
