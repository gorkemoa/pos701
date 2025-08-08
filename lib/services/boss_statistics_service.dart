import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos701/models/boss_statistics_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';

class BossStatisticsService {
  static const String _baseUrl = AppConstants.baseUrl;
  final _logger = AppLogger();

  Future<BossStatisticsResponse> getBossStatistics({
    required String userToken,
    required int compID,
    required String startDate,
    required String endDate,
    String order = '',
  }) async {
    _logger.i('🔄 Boss Statistics API çağrısı başlatılıyor...');
    _logger.d('📡 URL: $_baseUrl/service/user/account/bossStatistics');
    _logger.d('📋 Request Body: {userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order}');
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/service/user/account/bossStatistics'),
        headers: {
          'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode({
          'userToken': userToken,
          'compID': compID,
          'startDate': startDate,
          'endDate': endDate,
          'order': order,
        }),
      );

      _logger.d('📥 Response Status Code: ${response.statusCode}');
      _logger.d('📥 Response Body: ${response.body}');
      
      if (response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.i('✅ Boss Statistics API çağrısı başarılı');
        return BossStatisticsResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 403) {
        // Gone - Oturum süresi dolmuş
        _logger.e('❌ Oturum süresi dolmuş (403)');
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      } else {
        _logger.e('❌ Sunucu hatası: ${response.statusCode}');
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Boss Statistics API hatası: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<BossStatisticsDetailResponse> getBossStatisticsDetail({
    required String userToken,
    required int compID,
    required String startDate,
    required String endDate,
    required String order,
    required String filterKey,
    required String detailEndpoint,
  }) async {
    _logger.i('🔄 Boss Statistics Detail API çağrısı başlatılıyor...');
    _logger.d('📡 URL: $_baseUrl/service/user/account/statistics/$detailEndpoint');
    _logger.d('📋 Request Body: {userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order, filterKey: $filterKey}');
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/service/user/account/statistics/$detailEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode({
          'userToken': userToken,
          'compID': compID,
          'startDate': startDate,
          'endDate': endDate,
          'order': order,
          'filterKey': filterKey,
        }),
      );

      _logger.d('📥 Response Status Code: ${response.statusCode}');
      _logger.d('📥 Response Body: ${response.body}');
      
      if (response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.i('✅ Boss Statistics Detail API çağrısı başarılı');
        return BossStatisticsDetailResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 403) {
        // Forbidden - Oturum süresi dolmuş
        _logger.e('❌ Oturum süresi dolmuş (403)');
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      } else {
        _logger.e('❌ Sunucu hatası: ${response.statusCode}');
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Boss Statistics Detail API hatası: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<BossStatisticsOrderResponse> getBossStatisticsOrderDetail({
    required String userToken,
    required int compID,
    required String startDate,
    required String endDate,
    required String order,
    required String filterKey,
    required String detailEndpoint,
  }) async {
    _logger.i('🔄 Boss Statistics Order Detail API çağrısı başlatılıyor...');
    _logger.d('📡 URL: $_baseUrl/service/user/account/statistics/$detailEndpoint');
    _logger.d('📋 Request Body: {userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order, filterKey: $filterKey}');
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/service/user/account/statistics/$detailEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode({
          'userToken': userToken,
          'compID': compID,
          'startDate': startDate,
          'endDate': endDate,
          'order': order,
          'filterKey': filterKey,
        }),
      );

      _logger.d('📥 Response Status Code: ${response.statusCode}');
      _logger.d('📥 Response Body: ${response.body}');
      
      if (response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.i('✅ Boss Statistics Order Detail API çağrısı başarılı');
        return BossStatisticsOrderResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 403) {
        // Forbidden - Oturum süresi dolmuş
        _logger.e('❌ Oturum süresi dolmuş (403)');
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      } else {
        _logger.e('❌ Sunucu hatası: ${response.statusCode}');
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Boss Statistics Order Detail API hatası: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<BossStatisticsCashOrderResponse> getBossStatisticsCashOrderDetail({
    required String userToken,
    required int compID,
    required String startDate,
    required String endDate,
    required String order,
    required String filterKey,
    required String detailEndpoint,
  }) async {
    _logger.i('🔄 Boss Statistics Cash Order Detail API çağrısı başlatılıyor...');
    _logger.d('📡 URL: $_baseUrl/service/user/account/statistics/$detailEndpoint');
    _logger.d('📋 Request Body: {userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order, filterKey: $filterKey}');
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/service/user/account/statistics/$detailEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode({
          'userToken': userToken,
          'compID': compID,
          'startDate': startDate,
          'endDate': endDate,
          'order': order,
          'filterKey': filterKey,
        }),
      );

      _logger.d('📥 Response Status Code: ${response.statusCode}');
      _logger.d('📥 Response Body: ${response.body}');
      
      if (response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.i('✅ Boss Statistics Cash Order Detail API çağrısı başarılı');
        return BossStatisticsCashOrderResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 403) {
        // Forbidden - Oturum süresi dolmuş
        _logger.e('❌ Oturum süresi dolmuş (403)');
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      } else {
        _logger.e('❌ Sunucu hatası: ${response.statusCode}');
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Boss Statistics Cash Order Detail API hatası: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<BossStatisticsProductResponse> getBossStatisticsProductDetail({
    required String userToken,
    required int compID,
    required String startDate,
    required String endDate,
    required String order,
    required String filterKey,
    required String detailEndpoint,
  }) async {
    _logger.i('🔄 Boss Statistics Product Detail API çağrısı başlatılıyor...');
    _logger.d('📡 URL: $_baseUrl/service/user/account/statistics/$detailEndpoint');
    _logger.d('📋 Request Body: {userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order, filterKey: $filterKey}');
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/service/user/account/statistics/$detailEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode({
          'userToken': userToken,
          'compID': compID,
          'startDate': startDate,
          'endDate': endDate,
          'order': order,
          'filterKey': filterKey,
        }),
      );

      _logger.d('📥 Response Status Code: ${response.statusCode}');
      _logger.d('📥 Response Body: ${response.body}');
      
      if (response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.i('✅ Boss Statistics Product Detail API çağrısı başarılı');
        return BossStatisticsProductResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 403) {
        // Forbidden - Oturum süresi dolmuş
        _logger.e('❌ Oturum süresi dolmuş (403)');
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      } else {
        _logger.e('❌ Sunucu hatası: ${response.statusCode}');
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Boss Statistics Product Detail API hatası: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }
} 