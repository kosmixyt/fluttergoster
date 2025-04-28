import 'package:http/http.dart';

// Use conditional imports to handle platform differences
import 'web_client.dart' if (dart.library.io) 'non_web_client.dart';

/// Creates an HTTP client appropriate for the current platform
Client createHttpClient() {
  return getPlatformClient();
}
