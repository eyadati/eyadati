import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _checkInitialConnectivity();
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool previousStatus = _isOnline;
    if (results.contains(ConnectivityResult.none)) {
      _isOnline = false;
    } else {
      _isOnline = true;
    }

    if (previousStatus != _isOnline) {
      notifyListeners();
    }
  }
}
