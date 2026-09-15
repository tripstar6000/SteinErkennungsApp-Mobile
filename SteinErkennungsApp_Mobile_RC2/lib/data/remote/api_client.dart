import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'API $path fehlgeschlagen (${response.statusCode}): ${response.body}',
      );
    }
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _client.get(_uri(path)).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'API $path fehlgeschlagen (${response.statusCode}): ${response.body}',
      );
    }
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }
}
