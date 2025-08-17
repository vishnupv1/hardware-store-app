const axios = require('axios');

async function testAdminLogin() {
  try {
    console.log('🧪 Testing admin login...');
    
    const response = await axios.post('http://localhost:3001/api/auth/admin/login', {
      email: 'admin@email.com',
      password: 'Vis@123456'
    });

    console.log('✅ Login successful!');
    console.log('Token:', response.data.data.token);
    console.log('Admin:', response.data.data.admin);
    
    // Test accessing customers API with the token
    console.log('\n🧪 Testing customers API with token...');
    
    const customersResponse = await axios.get('http://localhost:3001/api/customers?page=1&limit=20', {
      headers: {
        'Authorization': `Bearer ${response.data.data.token}`
      }
    });

    console.log('✅ Customers API successful!');
    console.log('Response:', customersResponse.data);

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testAdminLogin();
