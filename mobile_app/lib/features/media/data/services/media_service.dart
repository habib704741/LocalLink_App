import 'dart:io';
import 'package:mobile_app/features/files/domain/models/file_item.dart';
import 'package:mobile_app/features/files/data/services/file_service.dart';

class MediaService {
  /// Get all images from device
  static Future<List<FileItem>> getAllImages() async {
    final images = <FileItem>[];

    final folders = [
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Screenshots',
    ];

    for (final folder in folders) {
      try {
        final dir = Directory(folder);
        if (await dir.exists()) {
          final files = await FileService.listFiles(folder);
          images.addAll(files.where((f) => f.isImage));

          // check subdirectories
          final subDirs = files.where((f) => f.isDirectory);
          for (final subDir in subDirs) {
            try {
              final subFiles = await FileService.listFiles(subDir.path);
              images.addAll(subFiles.where((f) => f.isImage));
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        print('Error scanning folder $folder: $e');
        continue;
      }
    }

    // Sort by date (newest first)
    images.sort((a, b) {
      if (a.lastModified == null || b.lastModified == null) return 0;
      return b.lastModified!.compareTo(a.lastModified!);
    });

    return images;
  }

  /// Get all videos from device
  static Future<List<FileItem>> getAllVideos() async {
    final videos = <FileItem>[];

    final folders = [
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Video',
    ];

    for (final folder in folders) {
      try {
        final dir = Directory(folder);
        if (await dir.exists()) {
          final files = await FileService.listFiles(folder);
          videos.addAll(files.where((f) => f.isVideo));

          // Also check subdirectories
          final subDirs = files.where((f) => f.isDirectory);
          for (final subDir in subDirs) {
            try {
              final subFiles = await FileService.listFiles(subDir.path);
              videos.addAll(subFiles.where((f) => f.isVideo));
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        print('Error scanning folder $folder: $e');
        continue;
      }
    }

    // Sort by date (newest first)
    videos.sort((a, b) {
      if (a.lastModified == null || b.lastModified == null) return 0;
      return b.lastModified!.compareTo(a.lastModified!);
    });

    return videos;
  }

  /// Get all audio files from device
  static Future<List<FileItem>> getAllAudio() async {
    final audioFiles = <FileItem>[];

    final folders = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Podcasts',
      '/storage/emulated/0/Audiobooks',
    ];

    for (final folder in folders) {
      try {
        final dir = Directory(folder);
        if (await dir.exists()) {
          final files = await FileService.listFiles(folder);
          audioFiles.addAll(files.where((f) => f.isAudio));

          // Also check subdirectories
          final subDirs = files.where((f) => f.isDirectory);
          for (final subDir in subDirs) {
            try {
              final subFiles = await FileService.listFiles(subDir.path);
              audioFiles.addAll(subFiles.where((f) => f.isAudio));
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        print('Error scanning folder $folder: $e');
        continue;
      }
    }

    // Sort by date (newest first)
    audioFiles.sort((a, b) {
      if (a.lastModified == null || b.lastModified == null) return 0;
      return b.lastModified!.compareTo(a.lastModified!);
    });

    return audioFiles;
  }

  static String getThumbnailPath(String imagePath) {
    return imagePath;
  }
}
