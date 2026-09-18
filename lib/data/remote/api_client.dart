import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String baseUrl = AppConfig.apiBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) {
    if (!path.startsWith('/') || path.startsWith('//')) {
      throw ArgumentError.value(path, 'path', 'Relativer API-Pfad erwartet.');
    }
    final uri = Uri.parse('$_baseUrl$path');
    if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const ApiException('Die Backend-Adresse muss eine HTTPS-Adresse sein.');
    }
    return uri;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final code = response.statusCode;
    if (code < 200 || code >= 300) {
      throw ApiException(
        switch (code) {
          401 || 403 => 'Der Server hat den Zugriff abgelehnt.',
          404 => 'Der API-Endpunkt wurde nicht gefunden. Backend-Adresse prüfen.',
          413 => 'Die Bilder sind für den Server zu groß.',
          429 => 'Zu viele Anfragen. Bitte später erneut versuchen.',
          >= 500 => 'Der Erkennungsserver ist momentan gestört. Bitte später erneut versuchen.',
          _ => 'Die Anfrage konnte nicht verarbeitet werden (HTTP $code).',
        },
        statusCode: code,
      );
    }
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().contains('json')) {
      throw const ApiException(
        'Der Server liefert keine JSON-Daten. Die Backend-Adresse ist möglicherweise falsch.',
      );
    }
    try {
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      if (value is! Map<String, dynamic>) throw const FormatException();
      if (value['error'] != null) {
        throw const ApiException('Der Server konnte die Anfrage nicht abschließen.');
      }
      return value;
    } on FormatException {
      throw const ApiException('Die Serverantwort ist unvollständig oder ungültig.');
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: {'content-type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode(body),
    ).timeout(timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _client.get(
      _uri(path),
      headers: {'accept': 'application/json'},
    ).timeout(timeout);
    return _decode(response);
  }

  void close() => _client.close();
}
