import 'dart:convert';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/models/login_model.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/services/api_service.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<ApiResponseModel<UserModel>> login(LoginModel loginModel) async {
    try {
      final response = await _apiService.post(AppConstants.loginEndpoint, loginModel.toJson());
      
      final responseData = jsonDecode(response.data);
      final apiResponse = ApiResponseModel<UserModel>.fromJson(
        responseData,
        (data) => UserModel.fromJson(data),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        await _apiService.saveToken(apiResponse.data!.token);
        await _apiService.saveUserId(apiResponse.data!.userID);
        
        if (loginModel.rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.userNameKey, loginModel.userName);
        }
      }
      
      return apiResponse;
    } catch (e) {
      return ApiResponseModel<UserModel>(
        error: true,
        success: false,
        errorCode: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null;
  }

  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userNameKey);
  }

  Future<void> clearSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userNameKey);
  }
} 