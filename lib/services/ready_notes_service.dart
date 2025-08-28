import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/ready_note_model.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:pos701/services/connectivity_service.dart';

class ReadyNotesService {
  final AppLogger _logger = AppLogger();

  Future<ApiResponseModel<ReadyNotesResponse>> getReadyNotes({
    required String userToken,
    required int compID,
  }) async {
    try {
      final String url = '${AppConstants.baseUrl}service/user/account/readyNotes/$compID';
      _logger.d('Hazır notlar API isteği: $url');
      
      final bool hasInternet = await ConnectivityService().hasInternetConnection();
      if (!hasInternet) {
        _logger.w('İnternet bağlantısı yok');
        return ApiResponseModel<ReadyNotesResponse>(
          error: true,
          success: false,
          errorCode: 'NO_INTERNET',
        );
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
          'User-Token': userToken,
        },
      );

      _logger.d('Hazır notlar yanıtı. Status: ${response.statusCode}');
      _logger.d('Yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        return ApiResponseModel.fromJson(
          jsonResponse,
          (json) => ReadyNotesResponse.fromJson(json),
        );
      } else if (response.statusCode == 401) {
        _logger.w('Yetkisiz erişim (401)');
        return ApiResponseModel<ReadyNotesResponse>(
          error: true,
          success: false,
          errorCode: 'UNAUTHORIZED',
        );
      } else if (response.statusCode == 403) {
        _logger.w('Yasak erişim (403)');
        return ApiResponseModel<ReadyNotesResponse>(
          error: true,
          success: false,
          errorCode: 'FORBIDDEN',
        );
      } else {
        _logger.e('Hazır notlar isteği başarısız. Status: ${response.statusCode}');
        return ApiResponseModel<ReadyNotesResponse>(
          error: true,
          success: false,
          errorCode: 'REQUEST_FAILED',
        );
      }
    } catch (e) {
      _logger.e('Hazır notlar servisi hatası: $e');
      return ApiResponseModel<ReadyNotesResponse>(
        error: true,
        success: false,
        errorCode: 'EXCEPTION',
      );
    }
  }
}
