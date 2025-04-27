import 'package:http/http.dart';
import 'package:http/browser_client.dart';

/// Returns a browser client for web platforms
Client getPlatformClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
