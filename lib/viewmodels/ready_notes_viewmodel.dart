import 'package:flutter/material.dart';
import 'package:pos701/models/ready_note_model.dart';
import 'package:pos701/services/ready_notes_service.dart';
import 'package:pos701/utils/app_logger.dart';

class ReadyNotesViewModel extends ChangeNotifier {
  final ReadyNotesService _readyNotesService;
  final AppLogger _logger = AppLogger();
  
  List<ReadyNote> _readyNotes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  
  ReadyNotesViewModel(this._readyNotesService) {
    _logger.i('ReadyNotesViewModel başlatıldı');
  }
  
  List<ReadyNote> get readyNotes => _readyNotes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasReadyNotes => _readyNotes.isNotEmpty;
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  // Güvenli bildirim gönderme metodu
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    } else {
      _logger.w('ReadyNotesViewModel dispose edilmiş durumda, bildirim gönderilemiyor');
    }
  }
  
  Future<bool> loadReadyNotes(String userToken, int compID) async {
    _logger.i('Hazır notlar yükleniyor. CompID: $compID');
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
    
    try {
      final response = await _readyNotesService.getReadyNotes(
        userToken: userToken,
        compID: compID,
      );
      
      if (response.success && response.data != null) {
        _readyNotes = response.data!.notes;
        _errorMessage = null;
        _logger.i('${_readyNotes.length} adet hazır not yüklendi');
      } else {
        _readyNotes = [];
        _errorMessage = _getErrorMessage(response.errorCode);
        _logger.e('Hazır notlar yüklenemedi. Hata: ${response.errorCode}');
      }
    } catch (e) {
      _readyNotes = [];
      _errorMessage = 'Hazır notlar yüklenirken beklenmeyen bir hata oluştu';
      _logger.e('ReadyNotesViewModel loadReadyNotes hatası: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
    
    return _readyNotes.isNotEmpty;
  }
  
  String _getErrorMessage(String? errorCode) {
    switch (errorCode) {
      case 'NO_INTERNET':
        return 'İnternet bağlantısı yok';
      case 'UNAUTHORIZED':
        return 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.';
      case 'FORBIDDEN':
        return 'Bu işlem için yetkiniz yok';
      case 'REQUEST_FAILED':
        return 'Sunucu hatası oluştu';
      case 'EXCEPTION':
        return 'Bağlantı hatası oluştu';
      default:
        return 'Hazır notlar yüklenemedi';
    }
  }
  
  // Hazır notu metin olarak döndür
  String getNoteText(int noteID) {
    try {
      return _readyNotes.firstWhere((note) => note.noteID == noteID).note;
    } catch (e) {
      return '';
    }
  }
  
  // Hazır notları temizle
  void clearNotes() {
    _readyNotes.clear();
    _errorMessage = null;
    _safeNotifyListeners();
  }
}
