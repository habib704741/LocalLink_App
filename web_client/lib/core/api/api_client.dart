import 'dart:developer';

import 'package:dio/dio.dart';

class ApiClient {
  late Dio _dio;
  String? _baseUrl;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get baseUrl => _baseUrl;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptor for logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          log('📤 REQUEST: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            '📥 RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          log('❌ ERROR: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Connect to server
  Future<bool> connect(String ipAddress, int port) async {
    try {
      _baseUrl = 'http://$ipAddress:$port';
      _dio.options.baseUrl = _baseUrl!;

      final response = await _dio.get('/api/health');

      if (response.statusCode == 200) {
        _isConnected = true;
        log('✅ Connected to server at $_baseUrl');
        return true;
      }

      return false;
    } catch (e) {
      log('❌ Connection failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Disconnect from server
  void disconnect() {
    _isConnected = false;
    _baseUrl = null;
    log('🔌 Disconnected from server');
  }

  /// Check server status
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await _dio.get('/api/status');
      return response.data;
    } catch (e) {
      log('Error getting status: $e');
      return null;
    }
  }

  /// Get device information
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final response = await _dio.get('/api/device');
      return response.data;
    } catch (e) {
      log('Error getting device info: $e');
      return null;
    }
  }

  /// Generic GET request
  Future<Response?> get(String path) async {
    try {
      return await _dio.get(path);
    } catch (e) {
      log('GET error: $e');
      return null;
    }
  }

  /// Generic POST request
  Future<Response?> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      log('POST error: $e');
      return null;
    }
  }

  /// Generic PUT request
  Future<Response?> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      log('PUT error: $e');
      return null;
    }
  }

  /// Generic DELETE request
  Future<Response?> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      log('DELETE error: $e');
      return null;
    }
  }

  /// Get storage roots
  Future<List<dynamic>?> getStorageRoots() async {
    try {
      final response = await _dio.get('/api/files/roots');
      return response.data['roots'];
    } catch (e) {
      log('Error getting storage roots: $e');
      return null;
    }
  }

  /// List files in directory
  Future<Map<String, dynamic>?> listFiles(
    String path, {
    bool showHidden = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/files/list',
        queryParameters: {'path': path, 'showHidden': showHidden.toString()},
      );
      return response.data;
    } catch (e) {
      log('Error listing files: $e');
      return null;
    }
  }

  /// Download file
  Future<bool> downloadFile(String path, String fileName) async {
    try {
      final response = await _dio.get(
        '/api/files/download',
        queryParameters: {'path': path},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        return true;
      }

      return false;
    } catch (e) {
      log('Error downloading file: $e');
      return false;
    }
  }

  /// Get download URL for a file
  String getDownloadUrl(String path) {
    if (_baseUrl == null) return '';
    return '$_baseUrl/api/files/download?path=${Uri.encodeComponent(path)}';
  }

  /// Upload file to phone
  Future<Map<String, dynamic>?> uploadFile(
    String destinationPath,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      // Create form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post(
        '/api/files/upload',
        data: formData,
        queryParameters: {'path': destinationPath},
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      log('Error uploading file: $e');
      return null;
    }
  }

  /// Get all images
  Future<List<dynamic>?> getAllImages() async {
    try {
      final response = await _dio.get('/api/media/images');
      return response.data['images'];
    } catch (e) {
      log('Error getting images: $e');
      return null;
    }
  }

  /// Get all videos
  Future<List<dynamic>?> getAllVideos() async {
    try {
      final response = await _dio.get('/api/media/videos');
      return response.data['videos'];
    } catch (e) {
      log('Error getting videos: $e');
      return null;
    }
  }

  /// Get all audio
  Future<List<dynamic>?> getAllAudio() async {
    try {
      final response = await _dio.get('/api/media/audio');
      return response.data['audio'];
    } catch (e) {
      log('Error getting audio: $e');
      return null;
    }
  }

  /// Get all contacts
  Future<List<dynamic>?> getAllContacts() async {
    try {
      final response = await _dio.get('/api/contacts');
      return response.data['contacts'];
    } catch (e) {
      print('Error getting contacts: $e');
      return null;
    }
  }

  /// Get media file URL
  String getMediaFileUrl(String path) {
    if (_baseUrl == null) return '';
    return '$_baseUrl/api/media/file?path=${Uri.encodeComponent(path)}';
  }
}
