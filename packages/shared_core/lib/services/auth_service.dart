import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

UserModel? currentUserModel;

class AuthService {
  static final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();
  
  static final UserModel _mockUser = UserModel(
    uid: 'mock_uid_123',
    name: 'Mock User',
    email: 'mock@email.com',
    role: UserRole.student,
  );

  static Stream<UserModel?> get authStateChanges => _authStateController.stream;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('mock_logged_in') ?? false;
    
    if (isLoggedIn) {
      currentUserModel = _mockUser;
      _authStateController.add(currentUserModel);
    } else {
      currentUserModel = null;
      _authStateController.add(null);
    }
  }

  static Future<UserModel?> getUserModel(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return currentUserModel ?? _mockUser;
  }

  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    currentUserModel = UserModel(
      uid: 'mock_uid_123',
      name: email.split('@')[0],
      email: email,
      role: UserRole.student,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mock_logged_in', true);
    
    _authStateController.add(currentUserModel);
    return currentUserModel;
  }

  static Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    currentUserModel = UserModel(
      uid: 'mock_uid_new',
      name: name,
      email: email,
      role: role,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mock_logged_in', true);
    
    _authStateController.add(currentUserModel);
    return currentUserModel!;
  }

  static Future<void> signOut() async {
    currentUserModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mock_logged_in', false);
    _authStateController.add(null);
  }

  static Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  static Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [_mockUser];
  }

  static Future<void> updateProfile({
    required String uid,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (currentUserModel != null) {
      currentUserModel = UserModel(
        uid: currentUserModel!.uid,
        name: name,
        email: currentUserModel!.email,
        role: currentUserModel!.role,
      );
      _authStateController.add(currentUserModel);
    }
  }

  static Future<void> updateRole({
    required String uid,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static Future<void> deleteUser(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
