import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static Future<bool> hasNetwork() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<bool> hasInternet() async {
    try {
      final response = await InternetAddress.lookup('google.com');
      return response.isNotEmpty && response[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Stream<List<ConnectivityResult>> get connectivityStream =>
      Connectivity().onConnectivityChanged;
}
