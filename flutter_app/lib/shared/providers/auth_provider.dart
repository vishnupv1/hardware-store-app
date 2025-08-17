import 'package:flutter/foundation.dart';
import '../../core/models/user.dart';
import '../../core/models/client.dart';
import '../../core/services/api_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  dynamic _user; // Can be either User or Client
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  dynamic get user => _user; // Can be either User or Client
  User? get userAsUser => _user is User ? _user as User : null;
  Client? get userAsClient => _user is Client ? _user as Client : null;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setStatus(AuthStatus.loading);
    
    try {
      final isAuthenticated = await apiService.isAuthenticated();
      
      if (isAuthenticated) {
        await _loadCurrentUser();
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.error, errorMessage: 'Failed to initialize authentication');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await apiService.getCurrentUser();
      
      if (response['success']) {
        final userData = response['data']['user'];
        // Determine if it's a user or client based on the data structure
        if (userData['companyName'] != null) {
          _user = Client.fromJson(userData);
        } else {
          _user = User.fromJson(userData);
        }
        _setStatus(AuthStatus.authenticated);
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }

  Future<bool> loginUser(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await apiService.loginUser(email, password);
      
      if (response['success']) {
        _user = User.fromJson(response['data']['user']);
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginClient(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await apiService.loginClient(email, password);
      
      if (response['success']) {
        _user = Client.fromJson(response['data']['client']);
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginVendor(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await apiService.loginVendor(email, password);
      
      if (response['success']) {
        _user = User.fromJson(response['data']['user']);
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await apiService.registerUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      if (response['success']) {
        _user = User.fromJson(response['data']['user']);
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerClient({
    required String email,
    required String password,
    required String companyName,
    required Map<String, String> contactPerson,
    Map<String, dynamic>? address,
    Map<String, dynamic>? businessInfo,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await apiService.registerClient(
        email: email,
        password: password,
        companyName: companyName,
        contactPerson: contactPerson,
        address: address,
        businessInfo: businessInfo,
      );
      
      if (response['success']) {
        _user = Client.fromJson(response['data']['client']);
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await apiService.logout();
    } catch (e) {
      // Even if logout fails on server, clear local state
    } finally {
      _user = null;
      _setStatus(AuthStatus.unauthenticated);
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatar,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await apiService.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        avatar: avatar,
      );
      
      if (response['success']) {
        // Update the local user object with new data
        _user = User.fromJson(response['data']['user']);
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response['message'] ?? 'Profile update failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setStatus(AuthStatus status, {String? errorMessage}) {
    _status = status;
    if (errorMessage != null) {
      _errorMessage = errorMessage;
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetError() {
    _clearError();
    if (_status == AuthStatus.error) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }
}
