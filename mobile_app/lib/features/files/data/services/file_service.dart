// ignore_for_file: avoid_print

import 'dart:io';
import 'package:mobile_app/features/files/domain/models/file_item.dart';

class FileService {
  /// Get list of storage roots
  static Future<List<FileItem>> getStorageRoots() async {
    final items = <FileItem>[];

    try {
      // Internal Storage
      final internalStoragePath = '/storage/emulated/0';
      final internalDir = Directory(internalStoragePath);
      if (await internalDir.exists()) {
        items.add(
          FileItem(
            name: 'Internal Storage',
            path: internalStoragePath,
            type: FileType.directory,
            size: 0,
            isHidden: false,
          ),
        );
      }

      // Download folder
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        items.add(
          FileItem(
            name: 'Downloads',
            path: downloadDir.path,
            type: FileType.directory,
            size: 0,
            isHidden: false,
          ),
        );
      }

      // DCIM folder
      final dcimDir = Directory('/storage/emulated/0/DCIM');
      if (await dcimDir.exists()) {
        items.add(
          FileItem(
            name: 'Camera',
            path: dcimDir.path,
            type: FileType.directory,
            size: 0,
            isHidden: false,
          ),
        );
      }

      // Pictures folder
      final picturesDir = Directory('/storage/emulated/0/Pictures');
      if (await picturesDir.exists()) {
        items.add(
          FileItem(
            name: 'Pictures',
            path: picturesDir.path,
            type: FileType.directory,
            size: 0,
            isHidden: false,
          ),
        );
      }

      // Documents folder
      final documentsDir = Directory('/storage/emulated/0/Documents');
      if (await documentsDir.exists()) {
        items.add(
          FileItem(
            name: 'Documents',
            path: documentsDir.path,
            type: FileType.directory,
            size: 0,
            isHidden: false,
          ),
        );
      }

      // Music folder
      final musicDir = Directory('/storage/emulated/0/Music');
      if (await musicDir.exists()) {
        items.add(
          FileItem(
            name: 'Music',
            path: musicDir.path,
            type: FileType.directory,
            size: 0,
            isHidden: false,
          ),
        );
      }

      // Movies folder
      final moviesDir = Directory('/storage/emulated/0/Movies');
      if (await moviesDir.exists()) {
        items.add(
          FileItem(
            name: 'Movies',
            path: moviesDir.path,
            type: FileType.directory,
            size: 0,
            isHidden: false,
          ),
        );
      }
    } catch (e) {
      print('Error getting storage roots: $e');
    }

    return items;
  }

  /// List files in a directory
  static Future<List<FileItem>> listFiles(
    String path, {
    bool showHidden = false,
  }) async {
    try {
      final directory = Directory(path);

      if (!await directory.exists()) {
        throw Exception('Directory does not exist: $path');
      }

      final entities = await directory.list().toList();
      final items = <FileItem>[];

      for (final entity in entities) {
        try {
          final item = FileItem.fromFileSystemEntity(entity);

          // Filter hidden files if needed
          if (!showHidden && item.isHidden) {
            continue;
          }

          items.add(item);
        } catch (e) {
          print('Error processing file: ${entity.path}, Error: $e');
          continue;
        }
      }

      // Sort: directories first, then by name
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return items;
    } catch (e) {
      print('Error listing files: $e');
      rethrow;
    }
  }

  /// Get file info
  static Future<FileItem?> getFileInfo(String path) async {
    try {
      final entity = File(path);
      if (!await entity.exists()) {
        final dirEntity = Directory(path);
        if (await dirEntity.exists()) {
          return FileItem.fromFileSystemEntity(dirEntity);
        }
        return null;
      }
      return FileItem.fromFileSystemEntity(entity);
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  /// Check if path exists
  static Future<bool> exists(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) return true;

      final directory = Directory(path);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }

  /// Create directory
  static Future<bool> createDirectory(String path) async {
    try {
      final directory = Directory(path);
      await directory.create(recursive: true);
      return true;
    } catch (e) {
      print('Error creating directory: $e');
      return false;
    }
  }

  /// Delete file or directory
  static Future<bool> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }

      final directory = Directory(path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting: $e');
      return false;
    }
  }

  static Future<bool> rename(String oldPath, String newName) async {
    try {
      final file = File(oldPath);
      if (await file.exists()) {
        final directory = file.parent.path;
        final newPath = '$directory/$newName';
        await file.rename(newPath);
        return true;
      }

      final dir = Directory(oldPath);
      if (await dir.exists()) {
        final parent = dir.parent.path;
        final newPath = '$parent/$newName';
        await dir.rename(newPath);
        return true;
      }

      return false;
    } catch (e) {
      print('Error renaming: $e');
      return false;
    }
  }

  /// Get parent directory path
  static String? getParentPath(String path) {
    try {
      final file = File(path);
      return file.parent.path;
    } catch (e) {
      return null;
    }
  }

  /// Search files
  static Future<List<FileItem>> searchFiles(
    String query,
    String rootPath,
  ) async {
    final results = <FileItem>[];

    try {
      await _searchRecursive(Directory(rootPath), query.toLowerCase(), results);
    } catch (e) {
      print('Error searching files: $e');
    }

    return results;
  }

  static Future<void> _searchRecursive(
    Directory directory,
    String query,
    List<FileItem> results,
  ) async {
    try {
      final entities = await directory.list().toList();

      for (final entity in entities) {
        try {
          final name = entity.path.split('/').last;

          if (name.toLowerCase().contains(query)) {
            final item = FileItem.fromFileSystemEntity(entity);
            results.add(item);
          }

          // Recursively search subdirectories
          if (entity is Directory &&
              !name.startsWith('.') &&
              results.length < 100) {
            await _searchRecursive(entity, query, results);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Skip directories we can't access
    }
  }
}
