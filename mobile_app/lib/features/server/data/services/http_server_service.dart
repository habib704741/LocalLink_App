// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:mobile_app/features/device/data/services/device_info_service.dart';
import 'package:mobile_app/features/files/data/services/file_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
// ignore: unused_import
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/features/media/data/services/media_service.dart';
import 'package:mobile_app/features/contacts/data/services/contacts_service.dart';
import 'package:shelf_static/shelf_static.dart';

class HttpServerService {
  HttpServer? _server;
  bool _isRunning = false;
  String? _staticPath;

  bool get isRunning => _isRunning;

  Future<void> start({required String ipAddress, required int port}) async {
    if (_isRunning) throw Exception('Server is already running');

    try {
      _staticPath = await _extractWebAssets();
      print('📂 Web content ready at: $_staticPath');

      final staticHandler = createStaticHandler(
        _staticPath!,
        defaultDocument: 'index.html',
        listDirectories: false,
      );

      final apiRouter = _createApiRouter();

      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler((Request request) async {
            if (request.method == 'OPTIONS') {
              return Response.ok('', headers: _corsHeaders());
            }

            if (request.url.path.contains('flutter_bootstrap.js')) {
              final file = File('$_staticPath/flutter_bootstrap.js');
              if (await file.exists()) {
                return Response.ok(
                  await file.readAsBytes(),
                  headers: {'Content-Type': 'application/javascript'},
                );
              }
            }
            if (request.url.path.contains('main.dart.js')) {
              final file = File('$_staticPath/main.dart.js');
              if (await file.exists()) {
                return Response.ok(
                  await file.readAsBytes(),
                  headers: {'Content-Type': 'application/javascript'},
                );
              }
            }

            if (request.url.path.endsWith('.map')) {
              return Response.ok(
                '{}',
                headers: {'Content-Type': 'application/json'},
              );
            }

            final apiResponse = await apiRouter.call(request);
            if (apiResponse.statusCode != 404) {
              return apiResponse;
            }

            return staticHandler(request);
          });

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      _isRunning = true;
      print('✅ Server started on http://$ipAddress:$port');
    } catch (e) {
      print('❌ Error starting server: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
  }

  Future<String> _extractWebAssets() async {
    final appDir = await getApplicationDocumentsDirectory();
    final webDir = Directory('${appDir.path}/web_hosting');

    if (await webDir.exists()) await webDir.delete(recursive: true);
    await webDir.create(recursive: true);

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assetList = manifest.listAssets();
    final webAssets = assetList
        .where((k) => k.startsWith('assets/web/'))
        .toList();

    int extractedCount = 0;
    for (final assetKey in webAssets) {
      String relativePath = assetKey.replaceFirst('assets/web/', '');
      if (relativePath.startsWith('/'))
        relativePath = relativePath.substring(1);
      if (relativePath.isEmpty) continue;

      try {
        final byteData = await rootBundle.load(assetKey);
        final file = File('${webDir.path}/$relativePath');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        extractedCount++;
      } catch (e) {
        print('⚠️ Error extracting $assetKey: $e');
      }
    }
    print('✅ Extracted $extractedCount files.');
    return webDir.path;
  }

  Router _createApiRouter() {
    final router = Router();

    // --- STATUS ---
    router.get(
      '/api/health',
      (_) => Response.ok(
        '{"status": "ok"}',
        headers: {'Content-Type': 'application/json'},
      ),
    );
    router.get(
      '/api/status',
      (_) => Response.ok(
        '{"status": "running"}',
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // --- DEVICE INFO ---
    router.get('/api/device', (Request request) async {
      try {
        final deviceInfo = await DeviceInfoService.getDeviceInfo();
        return Response.ok(
          jsonEncode(deviceInfo.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': '$e'}));
      }
    });

    // --- MEDIA LISTS ---
    router.get('/api/media/images', (Request request) async {
      try {
        final images = await MediaService.getAllImages();
        final jsonData = images.map((item) => item.toJson()).toList();
        return Response.ok(
          jsonEncode({'images': jsonData}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': '$e'}));
      }
    });

    router.get('/api/media/videos', (Request request) async {
      try {
        final videos = await MediaService.getAllVideos();
        final jsonData = videos.map((item) => item.toJson()).toList();
        return Response.ok(
          jsonEncode({'videos': jsonData}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': '$e'}));
      }
    });

    router.get('/api/media/audio', (Request request) async {
      try {
        final audio = await MediaService.getAllAudio();
        final jsonData = audio.map((item) => item.toJson()).toList();
        return Response.ok(
          jsonEncode({'audio': jsonData}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': '$e'}));
      }
    });

    // --- MEDIA STREAMING ---
    router.get('/api/media/file', (Request request) async {
      final path = request.url.queryParameters['path'];
      if (path == null) return Response.badRequest(body: 'Missing path');
      final file = File(path);
      if (!await file.exists()) return Response.notFound('File not found');
      return Response.ok(
        file.openRead(),
        headers: {'Content-Type': 'application/octet-stream'},
      );
    });

    // --- FILE MANAGEMENT ---
    router.get('/api/files/roots', (Request request) async {
      try {
        final roots = await FileService.getStorageRoots();
        final jsonData = roots.map((item) => item.toJson()).toList();
        return Response.ok(
          jsonEncode({'roots': jsonData}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': '$e'}));
      }
    });

    router.get('/api/files/list', (Request request) async {
      try {
        final path = request.url.queryParameters['path'];
        if (path == null) return Response.badRequest(body: 'Missing path');
        final files = await FileService.listFiles(path, showHidden: true);
        final jsonData = files.map((item) => item.toJson()).toList();
        return Response.ok(
          jsonEncode({'files': jsonData}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': '$e'}));
      }
    });

    router.get('/api/files/download', (Request request) async {
      final path = request.url.queryParameters['path'];
      if (path == null) return Response.badRequest(body: 'Missing path');
      final file = File(path);
      if (!await file.exists()) return Response.notFound('File not found');
      return Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Disposition':
              'attachment; filename="${path.split('/').last}"',
        },
      );
    });

    // --- UPLOAD ENDPOINT  ---
    router.post('/api/files/upload', (Request request) async {
      print('🔵 Upload request received');
      try {
        final contentType = request.headers['content-type'];
        if (contentType == null ||
            !contentType.contains('multipart/form-data')) {
          return Response.badRequest(
            body: 'Content-Type must be multipart/form-data',
          );
        }

        final path = request.url.queryParameters['path'];
        if (path == null) return Response.badRequest(body: 'Path required');

        final boundary = contentType.split('boundary=').last;
        final transformer = MimeMultipartTransformer(boundary);

        await for (final part in transformer.bind(request.read())) {
          final contentDisposition = part.headers['content-disposition'];
          if (contentDisposition != null &&
              contentDisposition.contains('filename=')) {
            final filenameMatch = RegExp(
              r'filename="([^"]+)"',
            ).firstMatch(contentDisposition);
            if (filenameMatch != null) {
              final filename = filenameMatch.group(1)!;
              final file = File('$path/$filename');

              final sink = file.openWrite();
              await sink.addStream(part);
              await sink.close();

              print('✅ Uploaded: $filename to $path');
            }
          }
        }
        return Response.ok(
          '{"success": true}',
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        print('❌ Upload failed: $e');
        return Response.internalServerError(body: 'Upload failed: $e');
      }
    });

    // --- CONTACTS ---
    router.get('/api/contacts', (Request request) async {
      try {
        final contacts = await ContactsService.getAllContacts();
        final jsonData = contacts.map((item) => item.toJson()).toList();
        return Response.ok(
          jsonEncode({'contacts': jsonData}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': '$e'}));
      }
    });

    return router;
  }

  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        final response = await handler(request);
        return response.change(headers: _corsHeaders());
      };
    };
  }

  Map<String, String> _corsHeaders() => {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}
