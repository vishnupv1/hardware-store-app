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
          // Add auth token to requests
          final token = await _getAuthToken();
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) {
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
    final token = prefs.getString(authTokenKey);
    return token;
  }
  
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(authTokenKey, token);
  }
  
  Future<void> _clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokenKey);
  }
  
  Future<bool> isAuthenticated() async {
    final token = await _getAuthToken();
    return token != null;
  }
  
  Future<String?> getCurrentToken() async {
    final token = await _getAuthToken();
    return token;
  }
  
  // Auth endpoints
  Future<Map<String, dynamic>> loginAdmin(String email, String password) async {
    try {
      final response = await _dio.post('/auth/admin/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['success']) {
        await _saveAuthToken(response.data['data']['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> loginEmployee(String email, String password) async {
    try {
      final response = await _dio.post('/auth/employee/login', data: {
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
  
  Future<Map<String, dynamic>> loginVendor(String email, String password) async {
    try {
      final response = await _dio.post('/vendor/login', data: {
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

  Future<Map<String, dynamic>> updateEmployeeProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatar,
  }) async {
    try {
      final response = await _dio.put('/employees/profile', data: {
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
  
  Map<String, dynamic> _handleDioError(DioException error) {
    if (error.response != null) {
      // Try to extract the actual error message from the response
      String errorMessage = 'An error occurred';
      
      if (error.response?.data is Map<String, dynamic>) {
        final responseData = error.response!.data as Map<String, dynamic>;
        
        // Try different possible error message fields
        if (responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData['msg'] != null) {
          errorMessage = responseData['msg'].toString();
        } else if (responseData['detail'] != null) {
          errorMessage = responseData['detail'].toString();
        }
      } else if (error.response?.data is String) {
        errorMessage = error.response!.data.toString();
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'statusCode': error.response?.statusCode,
        'errorType': 'response_error',
        'errorDetails': error.message,
        'responseData': error.response?.data,
      };
    } else {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'statusCode': 0,
        'errorType': 'network_error',
        'errorDetails': error.message,
        'errorCode': error.type.toString(),
      };
    }
  }

  // Test network connectivity
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/health');
      return true;
    } on DioException catch (e) {
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

  // Brand endpoints
  Future<Map<String, dynamic>> getBrands({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null) queryParams['search'] = search;
      if (isActive != null) queryParams['isActive'] = isActive;


      final response = await _dio.get('/brands', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getBrand(String id) async {
    try {
      final response = await _dio.get('/brands/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createBrand({
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await _dio.post('/brands', data: {
        'name': name,
        if (description != null) 'description': description,
        'isActive': isActive,
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateBrand(String id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (isActive != null) data['isActive'] = isActive;

      final response = await _dio.put('/brands/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteBrand(String id) async {
    try {
      final response = await _dio.delete('/brands/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getBrandStats() async {
    try {
      final response = await _dio.get('/brands/stats/summary');
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

  // Dashboard endpoints
  Future<Map<String, dynamic>> getDashboardStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get('/dashboard/stats', queryParameters: queryParams);
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

  // Category endpoints
  Future<Map<String, dynamic>> getCategories({
    int? page,
    int? limit,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null) queryParams['search'] = search;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _dio.get('/categories', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCategory(String id) async {
    try {
      final response = await _dio.get('/categories/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await _dio.post('/categories', data: categoryData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> categoryData) async {
    try {
      final response = await _dio.put('/categories/$id', data: categoryData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteCategory(String id) async {
    try {
      final response = await _dio.delete('/categories/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCategoriesForDropdown() async {
    try {
      final response = await _dio.get('/categories', queryParameters: {
        'forDropdown': 'true',
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getBrandsForDropdown() async {
    try {
      final response = await _dio.get('/brands', queryParameters: {
        'forDropdown': 'true',
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Supplier endpoints
  Future<Map<String, dynamic>> getSuppliers({
    int? page,
    int? limit,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null) queryParams['search'] = search;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _dio.get('/suppliers', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSupplier(String id) async {
    try {
      final response = await _dio.get('/suppliers/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> supplierData) async {
    try {
      final response = await _dio.post('/suppliers', data: supplierData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateSupplier(String id, Map<String, dynamic> supplierData) async {
    try {
      final response = await _dio.put('/suppliers/$id', data: supplierData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteSupplier(String id) async {
    try {
      final response = await _dio.delete('/suppliers/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSuppliersForDropdown() async {
    try {
      final response = await _dio.get('/suppliers', queryParameters: {
        'forDropdown': 'true',
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCustomersForDropdown() async {
    try {
      final response = await _dio.get('/customers', queryParameters: {
        'forDropdown': 'true',
      });
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Employee endpoints
  Future<Map<String, dynamic>> getEmployees({
    int page = 1,
    int limit = 20,
    String? search,
    String? department,
    String? role,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (department != null) queryParams['department'] = department;
      if (role != null) queryParams['role'] = role;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _dio.get('/employees', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getEmployee(String id) async {
    try {
      final response = await _dio.get('/employees/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> employeeData) async {
    try {
      final response = await _dio.post('/employees', data: employeeData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateEmployee(String id, Map<String, dynamic> employeeData) async {
    try {
      final response = await _dio.put('/employees/$id', data: employeeData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteEmployee(String id) async {
    try {
      final response = await _dio.delete('/employees/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getEmployeeStats() async {
    try {
      final response = await _dio.get('/employees/stats/summary');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> registerEmployee({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String employeeId,
    required String department,
    required String position,
    String? phoneNumber,
    String? role,
    double? salary,
  }) async {
    try {
      final response = await _dio.post('/auth/employee/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'employeeId': employeeId,
        'department': department,
        'position': position,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (role != null) 'role': role,
        if (salary != null) 'salary': salary,
      });
      
      if (response.data['success']) {
        await _saveAuthToken(response.data['data']['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Admin endpoints
  Future<Map<String, dynamic>> getAdmins({
    int page = 1,
    int limit = 20,
    String? search,
    String? department,
    String? adminLevel,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (department != null) queryParams['department'] = department;
      if (adminLevel != null) queryParams['adminLevel'] = adminLevel;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _dio.get('/admins', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getAdmin(String id) async {
    try {
      final response = await _dio.get('/admins/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createAdmin(Map<String, dynamic> adminData) async {
    try {
      final response = await _dio.post('/admins', data: adminData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateAdmin(String id, Map<String, dynamic> adminData) async {
    try {
      final response = await _dio.put('/admins/$id', data: adminData);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteAdmin(String id) async {
    try {
      final response = await _dio.delete('/admins/$id');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _dio.get('/admins/stats/summary');
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> registerAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String adminId,
    required String department,
    required String position,
    String? phoneNumber,
    String? adminLevel,
    String? accessLevel,
    double? salary,
  }) async {
    try {
      final response = await _dio.post('/auth/admin/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'adminId': adminId,
        'department': department,
        'position': position,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (adminLevel != null) 'adminLevel': adminLevel,
        if (accessLevel != null) 'accessLevel': accessLevel,
        if (salary != null) 'salary': salary,
      });
      
      if (response.data['success']) {
        await _saveAuthToken(response.data['data']['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
}

// Singleton instance
final apiService = ApiService();
