import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:fluttergoster/models/data_models.dart';
import 'package:fluttergoster/models/torrent_result.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'dart:async';

// Remove the problematic import and use our platform-specific clients
import 'http_client_provider.dart';

class ApiService {
  // URL de base de l'API
  final String baseUrl;

  // En-têtes par défaut pour les requêtes
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final Map<String, String> _cookies = {};

  ApiService({required this.baseUrl});

  http.Client _getClient() {
    return createHttpClient();
  }

  /// Authentifie l'utilisateur et stocke les cookies pour les futures requêtes.
  Future<bool> authenticate(String username) async {
    final url = Uri.parse('$baseUrl/login?uuid=$username');
    final client = _getClient();
    final response = await client.get(
      url,
      headers: _headers..addAll({'User-Agent': 'FlutterApp'}),
    );
    if (response.statusCode == 200) {
      String? rawCookie = response.headers['set-cookie'];
      _updateCookies(rawCookie ?? '');
      return true;
    }
    return false;
  }

  /// Ajoute les cookies stockés dans les headers pour les futures requêtes.
  Map<String, String> _addCookiesToHeaders([Map<String, String>? headers]) {
    final newHeaders = {..._headers, if (headers != null) ...headers};
    if (_cookies.isNotEmpty) {
      String cookie = _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      newHeaders['cookie'] = cookie;
    }
    // Ajout d'un User-Agent pour éviter certains blocages serveur
    newHeaders['User-Agent'] = 'FlutterApp';
    return newHeaders;
  }

  /// Public method to get headers with cookies
  Map<String, String> getHeadersWithCookies([
    Map<String, String>? additionalHeaders,
  ]) {
    return _addCookiesToHeaders(additionalHeaders);
  }

  /// Met à jour le stockage des cookies à partir du header 'set-cookie'.
  void _updateCookies(String rawCookie) {
    var cookies = rawCookie.split(',');
    for (var cookie in cookies) {
      var cookieParts = cookie.split(';');
      for (var part in cookieParts) {
        var keyValue = part.split('=');
        if (keyValue.length == 2) {
          var key = keyValue[0].trim();
          var value = keyValue[1].trim();
          _cookies[key] = value;
        }
      }
    }
  }

  /// Récupère les éléments pour la page de navigation (browse)
  Future<List<SkinnyRender>> getBrowseItems(
    String mediaType, {
    int offset = 0,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$baseUrl/browse?type=$mediaType&offset=$offset&limit=$limit',
    );
    final client = _getClient();

    var res = await client.get(url, headers: _addCookiesToHeaders());

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      final List<dynamic> items = data['elements'] ?? [];
      log('Items: $items');
      log('Response: ${res.statusCode} ${res.body}');
      return items.map((item) => SkinnyRender.fromJson(item)).toList();
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load browse items');
    }
  }

  Future<ApiHome> getHome() async {
    final url = Uri.parse('$baseUrl/home');
    final client = _getClient();

    var res = await client.get(url, headers: _addCookiesToHeaders());
    log('Response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      return ApiHome.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load home data');
    }
  }

  /// Récupère une image en utilisant les cookies pour l'authentification
  Future<Uint8List> getImage(String url) async {
    final client = _getClient();
    final response = await client.get(
      Uri.parse(url),
      headers: _addCookiesToHeaders(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load image');
    }
  }

  /// Récupère les détails d'un film
  Future<MovieItem> getMovieDetails(String movieId) async {
    final url = Uri.parse('$baseUrl/render?id=$movieId&type=movie');
    final client = _getClient();

    var res = await client.get(url, headers: _addCookiesToHeaders());

    if (res.statusCode == 200) {
      return MovieItem.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  /// Récupère les détails d'une série
  Future<TVItem> getTVDetails(String tvId) async {
    final url = Uri.parse('$baseUrl/render?id=$tvId&type=tv');
    final client = _getClient();

    var res = await client.get(url, headers: _addCookiesToHeaders());

    if (res.statusCode == 200) {
      return TVItem.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load TV details');
    }
  }

  /// Récupère les options de conversion pour un fichier
  Future<Map<String, dynamic>> getConvertOptions(String fileId) async {
    final url = Uri.parse('$baseUrl/transcode/options?file_id=$fileId');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get convert options');
    }
  }

  Future<void> torrentAction(
    String action,
    String torrentId, [
    bool deleteFiles = false,
  ]) async {
    String url = '$baseUrl/torrents/action?id=$torrentId&action=$action';

    // Add deleteFiles parameter for delete action
    if (action == 'delete') {
      url += '&deleteFiles=${deleteFiles ? 'true' : 'false'}';
    }

    final client = _getClient();
    final response = await client.get(
      Uri.parse(url),
      headers: _addCookiesToHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to perform torrent action: ${response.body}');
    }
  }

  /// Récupère les stockages disponibles
  Future<List<dynamic>> getStorages() async {
    final url = Uri.parse('$baseUrl/torrents/storage');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get storages');
    }
  }

  /// Arrête la transcoding d'un fichier
  Future<Map<String, dynamic>> stopTranscode(String uuid) async {
    final url = Uri.parse('$baseUrl/transcode/stop/$uuid');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to stop transcode');
    }
  }

  /// Lance la conversion d'un fichier
  Future<Map<String, dynamic>> postConvert(
    int fileId,
    int qualityRes,
    int audioTrackIndex,
    String path,
  ) async {
    final url = Uri.parse('$baseUrl/transcode/convert');
    final client = _getClient();

    final body = jsonEncode({
      'file_id': fileId,
      'quality_res': qualityRes,
      'audio_track_index': audioTrackIndex,
      'path': path,
    });

    var response = await client.post(
      url,
      headers: _addCookiesToHeaders(),
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start conversion');
    }
  }

  /// Récupère les torrents disponibles pour un item (film ou série)
  Future<List<AvailableTorrent>> fetchAvailableTorrents(
    String itemId,
    String itemType,
    String? seasonId,
  ) async {
    String complement = '';
    if (itemType == 'tv' && seasonId != null) {
      complement = '&season=$seasonId';
    }

    final url = Uri.parse(
      '$baseUrl/torrents/available?type=$itemType&id=$itemId$complement',
    );
    final client = _getClient();

    final response = await client.get(url, headers: _addCookiesToHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('error')) {
        throw Exception(data['error']);
      }

      if (data is List) {
        return data.map((item) => AvailableTorrent.fromJson(item)).toList();
      } else {
        return [];
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized');
    } else {
      String errorMsg =
          'Failed to load torrents: HTTP error ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          errorMsg = errorData['error'];
        }
      } catch (e) {
        // Ignore JSON parsing errors for error responses
      }
      throw Exception(errorMsg);
    }
  }

  /// Recherche de médias
  Future<List<SkinnyRender>> searchMedia(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      '$baseUrl/search?query=${Uri.encodeComponent(query)}',
    );
    final client = _getClient();

    var res = await client.get(url, headers: _addCookiesToHeaders());

    if (res.statusCode == 200) {
      final dynamic jsonData = jsonDecode(res.body);
      final List<dynamic> items;

      if (jsonData is List) {
        // Response is a direct array
        items = jsonData;
      } else {
        throw Exception('Invalid response format: expected a list');
      }
      return items.map((item) => SkinnyRender.fromJson(item)).toList();
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to search media items');
    }
  }

  /// Déplacer une série
  Future<Map<String, dynamic>> moveSerie(
    String sourceId,
    String targetId,
  ) async {
    final url = Uri.parse('$baseUrl/metadata/serie/move');
    final client = _getClient();

    var request = http.MultipartRequest('POST', url);
    request.fields['source_id'] = sourceId;
    request.fields['target_id'] = targetId;

    request.headers.addAll(_addCookiesToHeaders());

    var streamedResponse = await client.send(request);
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to move serie');
    }
  }

  /// Déplacer un fichier
  Future<Map<String, dynamic>> moveFile(
    String sourceId,
    String to,
    String toType,
    int? seasonId,
    int? episodeId,
  ) async {
    final url = Uri.parse('$baseUrl/metadata/update');
    final client = _getClient();

    var request = http.MultipartRequest('POST', url);
    request.fields['fileid'] = sourceId;
    request.fields['type'] = toType;
    request.fields['id'] = to;

    if (seasonId != null) {
      request.fields['season_id'] = seasonId.toString();
    }

    if (episodeId != null) {
      request.fields['episode_id'] = episodeId.toString();
    }

    request.headers.addAll(_addCookiesToHeaders());

    var streamedResponse = await client.send(request);
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to move file');
    }
  }

  /// Créer un partage pour un fichier
  Future<String> createShare(String fileId) async {
    final url = Uri.parse('$baseUrl/share/add?id=$fileId');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return "$baseUrl/share/get?id=${data['share']['id']}";
    } else {
      throw Exception('Failed to create share');
    }
  }

  /// Supprimer une requête de téléchargement
  Future<bool> deleteRequest(int requestId) async {
    final url = Uri.parse('$baseUrl/request/remove?id=$requestId');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete request');
    }
  }

  String getShareUrl(int shareId) {
    return '$baseUrl/share/get?id=$shareId';
  }

  /// Supprimer un partage
  Future<bool> deleteShare(int shareId) async {
    final url = Uri.parse('$baseUrl/share/remove?id=$shareId');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete share');
    }
  }

  /// Déconnexion utilisateur
  Future<bool> logout() async {
    final url = Uri.parse('$baseUrl/logout');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    return response.statusCode == 200;
  }

  /// Mise à jour du token utilisateur
  Future<void> updateToken(String token) async {
    final url = Uri.parse('$baseUrl/update');
    final client = _getClient();

    await client.get(url, headers: _addCookiesToHeaders());
  }

  /// Ajouter ou supprimer un élément de la liste de suivi
  Future<bool> modifyWatchlist(
    String action,
    String itemType,
    String itemUuid,
  ) async {
    final url = Uri.parse(
      '$baseUrl/watchlist?action=$action&type=$itemType&id=$itemUuid',
    );
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    return response.statusCode == 200;
  }

  /// Supprimer un élément de la liste "continuer à regarder"
  Future<Map<String, dynamic>> deleteContinue(
    String itemType,
    String itemId,
  ) async {
    final url = Uri.parse('$baseUrl/continue?type=$itemType&uuid=$itemId');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete continue');
    }
  }

  /// Supprimer un élément de la liste "continuer à regarder" avec notifications toast
  Future<bool> deleteContinueWithToast(String itemType, String itemId) async {
    try {
      final data = await deleteContinue(itemType, itemId);

      if (data.containsKey('error') && data['error'] != null) {
        // Handle error toast notification
        // You'll need to implement or use a toast package
        // For example: Fluttertoast.showToast(msg: data['error']);
        return false;
      } else {
        // Handle success toast notification
        // For example: Fluttertoast.showToast(msg: data['message'] ?? 'Item removed successfully');
        return true;
      }
    } catch (e) {
      // Handle exception toast notification
      // For example: Fluttertoast.showToast(msg: e.toString());
      return false;
    }
  }

  /// Ajouter un fournisseur IPTV
  Future<Map<String, dynamic>> addIptv(String url) async {
    final encodedUrl = Uri.encodeComponent(url);
    final requestUrl = Uri.parse('$baseUrl/iptv/add?url=$encodedUrl');
    final client = _getClient();

    var response = await client.get(
      requestUrl,
      headers: _addCookiesToHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add IPTV');
    }
  }

  /// Charger les fournisseurs IPTV
  Future<List<dynamic>> loadIptvs() async {
    final url = Uri.parse('$baseUrl/iptv/ordered');
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['iptvs'];
    } else {
      throw Exception('Failed to load IPTVs');
    }
  }

  /// Récupérer les chaînes IPTV
  Future<List<dynamic>> getIptvItems(
    String id,
    String group, {
    int offset = 0,
    int limit = 100,
  }) async {
    final url = Uri.parse(
      '$baseUrl/iptv?id=$id&offset=$offset&limit=$limit${group.isNotEmpty ? "&group=$group" : ""}',
    );
    final client = _getClient();

    var response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['channels'];
    } else {
      throw Exception('Failed to get IPTV items');
    }
  }

  /// Récupérer un drapeau de pays basé sur le nom
  String getCountryFlag(String name) {
    final flagMap = {
      'fre':
          'https://upload.wikimedia.org/wikipedia/en/thumb/c/c3/Flag_of_France.svg/1920px-Flag_of_France.svg.png',
      'eng':
          'https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/1920px-Flag_of_the_United_States.svg.png',
      'ger':
          'https://upload.wikimedia.org/wikipedia/en/thumb/b/ba/Flag_of_Germany.svg/1920px-Flag_of_Germany.svg.png',
      'ita':
          'https://upload.wikimedia.org/wikipedia/en/thumb/0/03/Flag_of_Italy.svg/1920px-Flag_of_Italy.svg.png',
      'es':
          'https://upload.wikimedia.org/wikipedia/en/thumb/9/9a/Flag_of_Spain.svg/1920px-Flag_of_Spain.svg.png',
    };

    final lowerName = name.toLowerCase();
    for (final key in flagMap.keys) {
      if (lowerName.contains(key)) {
        return flagMap[key]!;
      }
    }

    return 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Unknown_flag_-_European_version.png';
  }

  /// Récupère les données de transcodage via Server-Sent Events
  Future<TranscoderRes> getTranscodeData(
    String uri,
    Function(String) progressFn,
    Function(String) errorFn,
  ) async {
    final client = _getClient();
    final completer = Completer<TranscoderRes>();

    SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '$uri&disableTranscode=true',
      client: client,
      header: getHeadersWithCookies(),
    ).listen((event) {
      print("Event:" + (event.event ?? ""));
      if (event.event == "transcoder") {
        completer.complete(
          TranscoderRes.fromJson(jsonDecode(event.data ?? "")),
        );
      }
      if (event.event == "serverError") {
        errorFn(event.data ?? "");
      }
      if (event.event == "progress") {
        progressFn(event.data ?? "");
      }
    });
    print("Requested sse");

    return completer.future;
  }

  Future<Me> getMe() async {
    final url = Uri.parse('$baseUrl/me');
    final client = _getClient();
    var response = await client.get(url, headers: _addCookiesToHeaders());
    if (response.statusCode == 200) {
      return Me.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user data');
    }
  }

  Future<void> sendProgress(
    String fileId,
    int progress,
    String mediaId,
    String? episodeId,
    int total,
  ) async {
    var url =
        '$baseUrl/transcode/update?currentTime=$progress&fileId=$fileId&media_id=$mediaId&episode_id=${episodeId ?? 0}&total=$total';

    final requestUrl = Uri.parse(url);
    final client = _getClient();
    var response = await client.get(
      requestUrl,
      headers: _addCookiesToHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send progress');
    }
    print('Progress sent successfully');
  }

  /// Recherche des torrents avec une requête
  Future<List<TorrentResult>> searchTorrents(String query) async {
    final url = Uri.parse('$baseUrl/torrents/search?q=$query');
    final client = _getClient();

    final response = await client.get(url, headers: _addCookiesToHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((item) => TorrentResult.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search torrents: ${response.statusCode}');
    }
  }

  /// Ajouter un torrent à partir d'un lien
  Future<Map<String, dynamic>> addTorrent({
    required String torrentLink,
    required String mediaType,
    required String mediaUuid,
  }) async {
    final url = Uri.parse('$baseUrl/torrents/add');
    final client = _getClient();

    var request = http.MultipartRequest('POST', url);
    request.fields['addMethod'] = 'search';
    request.fields['torrentId'] = torrentLink;
    request.fields['mediaType'] = mediaType;
    request.fields['mediauuid'] = mediaUuid;

    request.headers.addAll(_addCookiesToHeaders());

    var streamedResponse = await client.send(request);
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add torrent: ${response.statusCode}');
    }
  }

  /// Envoie une requête de contenu pour un film/série
  Future<Map<String, dynamic>> sendContentRequest(
    String itemId,
    String itemType, {
    int? seasonId,
  }) async {
    String url = '$baseUrl/request/new?id=$itemId&type=$itemType';

    // Add season_id if we're requesting a TV show and seasonId is provided
    if (itemType == 'tv' && seasonId != null) {
      url += '&season_id=$seasonId';
    }

    final requestUrl = Uri.parse(url);
    final client = _getClient();

    var response = await client.post(
      requestUrl,
      headers: _addCookiesToHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send content request');
    }
  }
}
