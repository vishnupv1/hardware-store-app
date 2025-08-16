import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  static String get baseUrl {
    // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
    String url;
    if (Platform.isAndroid) {
      url = 'http://10.0.2.2:3001/api';
    } else {
      url = 'http://localhost:3001/api';
    }
    print('🔗 Base URL: $url');
    return url;
  }
  static const String authTokenKey = 'auth_token';
  
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('🌐 Making request to: ${options.baseUrl}${options.path}');
          print('📤 Request data: ${options.data}');
          print('📤 Request headers: ${options.headers}');
          
          // Add auth token to requests
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Response received: ${response.statusCode}');
          print('📥 Response data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Error occurred: ${error.message}');
          print('❌ Error type: ${error.type}');
          print('❌ Error response: ${error.response?.data}');
          
          // Handle common errors
          if (error.response?.statusCode == 401) {
            // Token expired or invalid
            _clearAuthToken();
          }
          handler.next(error);
        },
      ),
    );
  }
  
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(authTokenKey);
  }
  
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(authTokenKey, token);
  }
  
  Future<void> _clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokenKey);
  }
  
  // Auth endpoints
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await _dio.post('/auth/user/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['success']) {
        await _saveAuthToken(response.data['data']['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> loginClient(String email, String password) async {
    try {
      final response = await _dio.post('/auth/client/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['success']) {
        await _saveAuthToken(response.data['data']['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post('/auth/user/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      });
      
      if (response.data['success']) {
        await _saveAuthToken(response.data['data']['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> registerClient({
    required String email,
    required String password,
    required String companyName,
    required Map<String, String> contactPerson,
    Map<String, dynamic>? address,
    Map<String, dynamic>? businessInfo,
  }) async {
    try {
      final response = await _dio.post('/auth/client/register', data: {
        'email': email,
        'password': password,
        'companyName': companyName,
        'contactPerson': contactPerson,
        if (address != null) 'address': address,
        if (businessInfo != null) 'businessInfo': businessInfo,
      });
      
      if (response.data['success']) {
        await _saveAuthToken(response.data['data']['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatar,
  }) async {
    try {
      final response = await _dio.put('/user/profile', data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (avatar != null) 'avatar': avatar,
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _dio.post('/auth/logout');
      await _clearAuthToken();
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  Future<bool> isAuthenticated() async {
    final token = await _getAuthToken();
    return token != null;
  }
  
  Map<String, dynamic> _handleDioError(DioException error) {
    if (error.response != null) {
      return {
        'success': false,
        'message': error.response?.data['message'] ?? 'An error occurred',
        'statusCode': error.response?.statusCode,
      };
    } else {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'statusCode': 0,
      };
    }
  }

  // Test network connectivity
  Future<bool> testConnection() async {
    try {
      print('🔗 Testing connection to: ${baseUrl}');
      final response = await _dio.get('/auth/me');
      print('✅ Connection test successful: ${response.statusCode}');
      return true;
    } on DioException catch (e) {
      print('❌ Connection test failed: ${e.message}');
      print('❌ Error type: ${e.type}');
      return false;
    }
  }

  // Customer endpoints
  Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int limit = 20,
    String? search,
    String? customerType,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (customerType != null) queryParams['customerType'] = customerType;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _dio.get('/customers', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCustomer(String id) async {
    try {
      final response = await _dio.get('/customers/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await _dio.post('/customers', data: customerData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> customerData) async {
    try {
      final response = await _dio.put('/customers/$id', data: customerData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteCustomer(String id) async {
    try {
      final response = await _dio.delete('/customers/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final response = await _dio.get('/customers/stats/summary');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getLowCreditCustomers() async {
    try {
      final response = await _dio.get('/customers/low-credit');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Product endpoints
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? brand,
    bool? isActive,
    String? stockStatus,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      if (brand != null) queryParams['brand'] = brand;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (stockStatus != null) queryParams['stockStatus'] = stockStatus;

      final response = await _dio.get('/products', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    try {
      final response = await _dio.get('/products/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _dio.post('/products', data: productData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final response = await _dio.put('/products/$id', data: productData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final response = await _dio.delete('/products/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateProductStock(String id, {
    required int quantity,
    required String type,
    String? reason,
  }) async {
    try {
      final response = await _dio.post('/products/$id/stock', data: {
        'quantity': quantity,
        'type': type,
        if (reason != null) 'reason': reason,
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getProductStats() async {
    try {
      final response = await _dio.get('/products/stats/summary');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getLowStockProducts() async {
    try {
      final response = await _dio.get('/products/low-stock');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getProductCategories() async {
    try {
      final response = await _dio.get('/products/categories');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getProductBrands() async {
    try {
      final response = await _dio.get('/products/brands');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> addProductBrand(String brandName) async {
    try {
      final response = await _dio.post('/products/brands', data: {
        'name': brandName,
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Sale endpoints
  Future<Map<String, dynamic>> getSales({
    int page = 1,
    int limit = 20,
    String? customerId,
    String? paymentStatus,
    String? saleStatus,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (customerId != null) queryParams['customerId'] = customerId;
      if (paymentStatus != null) queryParams['paymentStatus'] = paymentStatus;
      if (saleStatus != null) queryParams['saleStatus'] = saleStatus;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get('/sales', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSale(String id) async {
    try {
      final response = await _dio.get('/sales/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> saleData) async {
    try {
      final response = await _dio.post('/sales', data: saleData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateSale(String id, Map<String, dynamic> saleData) async {
    try {
      final response = await _dio.put('/sales/$id', data: saleData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> cancelSale(String id) async {
    try {
      final response = await _dio.delete('/sales/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> returnSale(String id, {
    required List<Map<String, dynamic>> items,
    required double refundAmount,
    required String refundReason,
  }) async {
    try {
      final response = await _dio.post('/sales/$id/return', data: {
        'items': items,
        'refundAmount': refundAmount,
        'refundReason': refundReason,
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSalesStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get('/sales/stats/summary', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getPendingPayments() async {
    try {
      final response = await _dio.get('/sales/pending-payments');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCustomerSales(String customerId) async {
    try {
      final response = await _dio.get('/sales/customer/$customerId');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
}

// Singleton instance
final apiService = ApiService();
