import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UpdateBannerService {
  final Dio _dio;
  final String _baseUrl;
  final String _githubToken;
  final Map<String, String> _headers;

  UpdateBannerService({Dio? dio})
      : _baseUrl = dotenv.env['GITHUB_API_BASE'] ??'',
        _githubToken = dotenv.env['GITHUB_TOKEN'] ?? '',
        _dio = dio ?? Dio(),
        _headers = {
          'Authorization': 'token ${dotenv.env['GITHUB_TOKEN'] ?? ''}',
          'Accept': 'application/vnd.github.v3+json',
        } {
    // Set default headers for Dio instance
    _dio.options.headers.addAll(_headers);
  }

  Future<List<Map<String, dynamic>>> listBuildFiles(String flavor) async {
    final res = await _dio.get<List>(
      '$_baseUrl/contents/builds/$flavor',
      queryParameters: {'ref': flavor},
    );
    return res.data!.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> fetchFileDetails(
      String flavor, String filename) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/contents/builds/$flavor/$filename',
      queryParameters: {'ref': flavor},
    );
    return res.data!;
  }

  String decodeBase64(String base64Content) {
    final cleanedBase64 = base64Content.replaceAll(RegExp(r'\s+'), '');
    return utf8.decode(base64.decode(cleanedBase64));
  }
}
