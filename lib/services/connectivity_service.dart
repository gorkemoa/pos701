import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isOnline = true;
  bool _isChecking = false;
  Timer? _connectivityTimer;

  bool get isOnline => _isOnline;

  void startMonitoring() {
    _checkConnectivity();
    // Check every 5 seconds for faster updates
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
  }

  void stopMonitoring() {
    _connectivityTimer?.cancel();
  }

  Future<void> _checkConnectivity() async {
    // Prevent multiple simultaneous checks
    if (_isChecking) return;
    _isChecking = true;

    try {
      // Use Google's DNS for faster response
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 2));
      
      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (_isOnline != newStatus) {
        _isOnline = newStatus;
        notifyListeners();
      }
    } catch (e) {
      if (_isOnline != false) {
        _isOnline = false;
        notifyListeners();
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> checkConnectivityOnce() async {
    try {
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
