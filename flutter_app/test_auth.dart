import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Test token storage and retrieval
  final prefs = await SharedPreferences.getInstance();
  
  // Test token
  const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test';
  
  // Save token
  await prefs.setString('auth_token', testToken);
  print('✅ Token saved: $testToken');
  
  // Retrieve token
  final retrievedToken = prefs.getString('auth_token');
  print('🔑 Token retrieved: $retrievedToken');
  
  // Check if they match
  if (testToken == retrievedToken) {
    print('✅ Token storage and retrieval working correctly');
  } else {
    print('❌ Token mismatch');
  }
}
