import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:locallink_host/contact_service.dart';
import 'package:locallink_host/sms_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'system_service.dart';
import 'file_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mime/mime.dart';

class LocalLinkServer {
  dynamic _server;
  final SystemService _systemService = SystemService();
  final FileService _fileService = FileService();
  final ContactService _contactService = ContactService();
  final SmsService _smsService = SmsService();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };

  Future<void> start() async {
    final router = Router();

    router.get('/api/system', (Request request) async {
      try {
        final data = await _systemService.getSystemData();
        return Response.ok(jsonEncode(data), headers: _headers);
      } catch (e) {
        return Response.internalServerError(
          body: 'Error: $e',
          headers: _headers,
        );
      }
    });

    router.get('/api/files', (Request request) {
      final String targetPath =
          request.url.queryParameters['path'] ?? _fileService.rootPath;
      try {
        final files = _fileService.getFiles(targetPath);
        return Response.ok(jsonEncode(files), headers: _headers);
      } catch (e) {
        return Response.internalServerError(
          body: 'Error: $e',
          headers: _headers,
        );
      }
    });

    router.get('/api/download', (Request request) {
      final String? targetPath = request.url.queryParameters['path'];
      if (targetPath == null) return Response.badRequest(body: 'Missing path');

      final file = File(targetPath);
      if (!file.existsSync()) return Response.notFound('File not found');

      final mimeType = lookupMimeType(targetPath) ?? 'application/octet-stream';

      String disposition = 'inline';

      if (mimeType == 'application/octet-stream') {
        disposition = 'attachment; filename="${targetPath.split('/').last}"';
      }

      return Response.ok(
        file.openRead(),
        headers: {
          ..._headers,
          'Content-Type': mimeType,
          'Content-Disposition': disposition,
        },
      );
    });

    router.get('/api/echo', (Request request) {
      return Response.ok('{"message": "Hello"}', headers: _headers);
    });

    router.get('/api/contacts', (Request request) async {
      try {
        final contacts = await _contactService.getContacts();
        return Response.ok(jsonEncode(contacts), headers: _headers);
      } catch (e) {
        return Response.internalServerError(
          body: 'Error: $e',
          headers: _headers,
        );
      }
    });

    router.get('/api/sms', (Request request) async {
      try {
        final messages = await _smsService.getMessages();
        return Response.ok(jsonEncode(messages), headers: _headers);
      } catch (e) {
        return Response.internalServerError(
          body: 'Error: $e',
          headers: _headers,
        );
      }
    });

    router.all('/<path|.*>', (Request request) {
      return _serveAsset(request.url.path);
    });

    try {
      _server = await shelf_io.serve(router, '0.0.0.0', 8080);
      print('Server running on port 8080');
    } catch (e) {
      print("Error starting server: $e");
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    print('Server stopped');
  }

  Future<Response> _serveAsset(String path) async {
    try {
      String assetPath = path;
      if (assetPath == '/' || assetPath.isEmpty) {
        assetPath = 'index.html';
      }

      if (assetPath.startsWith('/')) {
        assetPath = assetPath.substring(1);
      }

      final fullPath = 'assets/web/$assetPath';
      final content = await rootBundle.load(fullPath);

      String contentType = 'text/plain';
      if (assetPath.endsWith('.html')) {
        contentType = 'text/html';
      } else if (assetPath.endsWith('.js')) {
        contentType = 'application/javascript';
      } else if (assetPath.endsWith('.css')) {
        contentType = 'text/css';
      } else if (assetPath.endsWith('.png')) {
        contentType = 'image/png';
      } else if (assetPath.endsWith('.json')) {
        contentType = 'application/json';
      } else if (assetPath.endsWith('.ttf')) {
        contentType = 'font/ttf';
      }

      return Response.ok(
        content.buffer.asUint8List(),
        headers: {'content-type': contentType},
      );
    } catch (e) {
      print("Asset not found: $path");
      return Response.notFound('File not found in app assets');
    }
  }
}
