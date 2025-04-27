import 'package:http/http.dart';

/// Returns a standard client for non-web platforms
Client getPlatformClient() {
  return Client();
}
