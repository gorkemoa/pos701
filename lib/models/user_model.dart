import 'package:pos701/utils/app_logger.dart';


class UserModel {
  final int userID;
  final int? compID;
  final String token;
  final String? username;
  final String? userFirstname;
  final String? userLastname;
  final String? userFullname;
  final String? userEmail;
  final String? userBirthday;
  final dynamic userPermissions;
  final String? userPhone;
  final String? userRank;
  final String? userStatus;
  final String? userGender;
  final String? serverDate;
  final String? serverTime;
  final String? userToken;
  final String? platform;
  final String? version;
  final CompanyInfo? company;

  UserModel({
    required this.userID,
    required this.token,
    this.compID,
    this.username,
    this.userFirstname,
    this.userLastname,
    this.userFullname,
    this.userEmail,
    this.userBirthday,
    this.userPermissions,
    this.userPhone,
    this.userRank,
    this.userStatus,
    this.userGender,
    this.serverDate,
    this.serverTime,
    this.userToken,
    this.platform,
    this.version,
    this.company,
  });

  factory UserModel.fromLoginJson(Map<String, dynamic> json) {
    final logger = AppLogger();
    logger.d('UserModel.fromLoginJson çağrıldı, json: $json');
    
    // userID değerini almaya çalış
    int userId;
    if (json.containsKey('userID')) {
      final userIdValue = json['userID'];
      if (userIdValue is int) {
        userId = userIdValue;
      } else if (userIdValue is String) {
        userId = int.parse(userIdValue);
      } else {
        logger.e('userID formatı geçersiz: ${userIdValue.runtimeType}');
        userId = 0; // Varsayılan değer
      }
    } else {
      logger.e('userID bulunamadı');
      userId = 0; // Varsayılan değer
    }
    
    // token değerini almaya çalış
    String tokenValue;
    if (json.containsKey('token')) {
      final tokenRaw = json['token'];
      if (tokenRaw is String) {
        tokenValue = tokenRaw;
      } else {
        logger.e('token formatı geçersiz: ${tokenRaw.runtimeType}');
        tokenValue = ''; // Varsayılan değer
      }
    } else if (json.containsKey('userToken')) {
      final tokenRaw = json['userToken'];
      if (tokenRaw is String) {
        tokenValue = tokenRaw;
      } else {
        logger.e('userToken formatı geçersiz: ${tokenRaw.runtimeType}');
        tokenValue = ''; // Varsayılan değer
      }
    } else {
      logger.e('token veya userToken bulunamadı');
      tokenValue = ''; // Varsayılan değer
    }
    
    logger.i('UserModel oluşturuldu: ID=$userId, Token=$tokenValue');
    
    return UserModel(
      userID: userId,
      token: tokenValue,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final logger = AppLogger();
    logger.d('UserModel.fromJson çağrıldı');
    
    if (json.containsKey('userID') && (json.containsKey('token') || json.containsKey('userToken'))) {
      logger.d('Login yanıtı formatında veri algılandı, fromLoginJson kullanılıyor');
      return UserModel.fromLoginJson(json);
    }
    
    Map<String, dynamic> userData;
    if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      userData = json['user'] as Map<String, dynamic>;
      logger.d('User verisi bulundu: $userData');
    } else {
      // API direkt user bilgilerini döndürmüş olabilir
      userData = json;
      logger.d('User verisi direkt gönderilmiş olabilir: $userData');
    }
    
    // userID alınması
    int userId = 0;
    if (userData.containsKey('userID')) {
      final userIdValue = userData['userID'];
      if (userIdValue is int) {
        userId = userIdValue;
      } else if (userIdValue is String) {
        userId = int.tryParse(userIdValue) ?? 0;
      }
    }
    
    // Diğer alanların alınması
    final compId = userData['compID'] is int ? userData['compID'] as int : null;
    
    // Token bilgisi
    String tokenValue = '';
    if (userData.containsKey('token')) {
      tokenValue = userData['token']?.toString() ?? '';
    } else if (userData.containsKey('userToken')) {
      tokenValue = userData['userToken']?.toString() ?? '';
    }
    
    // Şirket bilgisi
    CompanyInfo? companyInfo;
    if (userData.containsKey('company') && userData['company'] is Map<String, dynamic>) {
      companyInfo = CompanyInfo.fromJson(userData['company'] as Map<String, dynamic>);
    }
    
    return UserModel(
      userID: userId,
      compID: compId,
      token: tokenValue,
      username: userData['username']?.toString(),
      userFirstname: userData['userFirstname']?.toString(),
      userLastname: userData['userLastname']?.toString(),
      userFullname: userData['userFullname']?.toString(),
      userEmail: userData['userEmail']?.toString(),
      userBirthday: userData['userBirthday']?.toString(),
      userPermissions: userData['userPermissions'],
      userPhone: userData['userPhone']?.toString(),
      userRank: userData['userRank']?.toString(),
      userStatus: userData['userStatus']?.toString(),
      userGender: userData['userGender']?.toString(),
      serverDate: userData['serverDate']?.toString(),
      serverTime: userData['serverTime']?.toString(),
      userToken: userData['userToken']?.toString(),
      platform: userData['platform']?.toString(),
      version: userData['version']?.toString(),
      company: companyInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'token': token,
      'compID': compID,
      'username': username,
      'userFirstname': userFirstname,
      'userLastname': userLastname,
      'userFullname': userFullname,
      'userEmail': userEmail,
      'userBirthday': userBirthday,
      'userPermissions': userPermissions,
      'userPhone': userPhone,
      'userRank': userRank,
      'userStatus': userStatus,
      'userGender': userGender,
      'userToken': userToken,
      'serverDate': serverDate,
      'serverTime': serverTime,
      'platform': platform,
      'version': version,
      'company': company?.toJson(),
    };
  }
} 
class PaymentType {
  final int typeID;
  final String typeName;
  final String typeColor;
  final String typeImg;

  PaymentType({
    required this.typeID,
    required this.typeName,
    required this.typeColor,
    required this.typeImg,
  });

  factory PaymentType.fromJson(Map<String, dynamic> json) {
    return PaymentType(
      typeID: json['typeID'] ?? 0,
      typeName: json['typeName'] ?? '',
      typeColor: json['typeColor'] ?? '#000000',
      typeImg: json['typeImg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'typeID': typeID,
      'typeName': typeName,
      'typeColor': typeColor,
      'typeImg': typeImg,
    };
  }
}

class CompanyInfo {
  final int compID;
  final String compName;
  final bool compKuverWaiter;
  final List<PaymentType> compPayTypes;

  CompanyInfo({
    required this.compID,
    required this.compName,
    required this.compKuverWaiter,
    required this.compPayTypes,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    List<PaymentType> payTypes = [];
    if (json.containsKey('compPayTypes') && json['compPayTypes'] is List) {
      payTypes = (json['compPayTypes'] as List)
          .map((payType) => PaymentType.fromJson(payType))
          .toList();
    }

    return CompanyInfo(
      compID: json['compID'],
      compName: json['compName'],
      compKuverWaiter: json['compKuverWaiter'],
      compPayTypes: payTypes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compID': compID,
      'compName': compName,
      'compKuverWaiter': compKuverWaiter,
      'compPayTypes': compPayTypes.map((payType) => payType.toJson()).toList(),
    };
  }
}
