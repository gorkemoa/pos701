class LoginModel {
  final String userName;
  final String userPassword;
  final bool rememberMe;

  LoginModel({
    required this.userName,
    required this.userPassword,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userPassword': userPassword,
    };
  }
} 