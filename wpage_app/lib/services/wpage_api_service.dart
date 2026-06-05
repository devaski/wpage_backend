import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/page_model.dart';

class WPageApiException implements Exception {
  WPageApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class WPageApiService {
  WPageApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const _defaultTimeout = Duration(seconds: 30);
  static const _generateTimeout = Duration(seconds: 120);

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) {
    return _client
        .get(uri, headers: headers)
        .timeout(_defaultTimeout, onTimeout: _onTimeout);
  }

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _defaultTimeout,
  }) {
    return _client
        .post(uri, headers: headers, body: body)
        .timeout(timeout, onTimeout: _onTimeout);
  }

  Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client
        .put(uri, headers: headers, body: body)
        .timeout(_defaultTimeout, onTimeout: _onTimeout);
  }

  Never _onTimeout() {
    throw WPageApiException(
      'Request timed out. Check your internet connection and try again.',
    );
  }

  Future<GeneratePageResult> generateWPage({
    required String identity,
    required String title,
    required String description,
    required bool geoLocationEnabled,
    String? location,
    String? purpose,
  }) async {
    final body = <String, dynamic>{
      'identity': identity,
      'title': title,
      'description': description,
      'geoLocationEnabled': geoLocationEnabled,
    };
    if (geoLocationEnabled && location != null && location.isNotEmpty) {
      body['location'] = location;
    }
    if (purpose != null && purpose.isNotEmpty) {
      body['purpose'] = purpose;
    }

    final response = await _post(
      Uri.parse('$_baseUrl/generate-page'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
      timeout: _generateTimeout,
    );
    _throwIfError(response);
    return GeneratePageResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GeneratePageResult> generatePage({
    required String identity,
    required String alias,
    required String purpose,
    required String description,
  }) async {
    final response = await _post(
      Uri.parse('$_baseUrl/generate-page'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identity': identity,
        'alias': alias,
        'purpose': purpose,
        'description': description,
      }),
      timeout: _generateTimeout,
    );
    _throwIfError(response);
    return GeneratePageResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PageModel> getPage(String alias) async {
    final response = await _get(
      Uri.parse('$_baseUrl/page/$alias'),
      headers: {'Accept': 'application/json'},
    );
    _throwIfError(response);
    return PageModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<PageModel> updatePage(PageModel page) async {
    final response = await _put(
      Uri.parse('$_baseUrl/page/${page.alias}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(page.toJson()),
    );
    _throwIfError(response);
    return PageModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<String> fetchPreviewHtml(PageModel page) async {
    final response = await _post(
      Uri.parse('$_baseUrl/render/preview'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(page.toJson()),
    );
    _throwIfError(response);
    return response.body;
  }

  String renderUrl(String alias) => '$_baseUrl/render/$alias';

  Future<PublishResult> publishPage(String alias) async {
    final response = await _post(Uri.parse('$_baseUrl/page/$alias/publish'));
    _throwIfError(response);
    return PublishResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> getQrCodeUrl(String alias, {int size = 300}) async {
    final response = await _post(
      Uri.parse('$_baseUrl/page/$alias/qr'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'size': size}),
    );
    _throwIfError(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['qrCodeUrl'] as String;
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw WPageApiException(
        body['detail']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
      );
    } on WPageApiException {
      rethrow;
    } catch (_) {
      throw WPageApiException(
        'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }
}
