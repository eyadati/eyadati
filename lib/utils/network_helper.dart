import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkHelper {
  static Future<bool> checkInternetConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}
