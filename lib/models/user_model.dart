class UserModel {
  final int userID;
  final String token;

  UserModel({
    required this.userID,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userID: json['userID'] as int,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'token': token,
    };
  }
} 