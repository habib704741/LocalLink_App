import 'dart:io';

enum FileType {
  file,
  directory,
  image,
  video,
  audio,
  document,
  archive,
  unknown,
}

class FileItem {
  final String name;
  final String path;
  final FileType type;
  final int size;
  final DateTime? lastModified;
  final bool isHidden;
  final String? mimeType;
  final String? extension;

  FileItem({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.lastModified,
    required this.isHidden,
    this.mimeType,
    this.extension,
  });

  factory FileItem.fromFileSystemEntity(FileSystemEntity entity) {
    final stat = entity.statSync();
    final name = entity.path.split('/').last;
    final isDirectory = entity is Directory;
    final isHidden = name.startsWith('.');

    String? extension;
    FileType type = FileType.unknown;

    if (!isDirectory) {
      final parts = name.split('.');
      if (parts.length > 1) {
        extension = parts.last.toLowerCase();
        type = _getFileTypeFromExtension(extension);
      } else {
        type = FileType.file;
      }
    } else {
      type = FileType.directory;
    }

    return FileItem(
      name: name,
      path: entity.path,
      type: type,
      size: stat.size,
      lastModified: stat.modified,
      isHidden: isHidden,
      extension: extension,
    );
  }

  static FileType _getFileTypeFromExtension(String extension) {
    final ext = extension.toLowerCase();

    // Images
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
      'heif',
      'svg',
      'ico',
    ].contains(ext)) {
      return FileType.image;
    }

    // Videos
    if ([
      'mp4',
      'avi',
      'mkv',
      'mov',
      'wmv',
      'flv',
      '3gp',
      'webm',
      'm4v',
      'mpeg',
      'mpg',
    ].contains(ext)) {
      return FileType.video;
    }

    // Audio
    if ([
      'mp3',
      'wav',
      'flac',
      'aac',
      'ogg',
      'm4a',
      'wma',
      'opus',
      'aiff',
    ].contains(ext)) {
      return FileType.audio;
    }

    // Documents
    if ([
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'odt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'csv',
      'md',
      'log',
      'xml',
      'json',
      'html',
      'htm',
      'epub',
      'mobi',
    ].contains(ext)) {
      return FileType.document;
    }

    // Archives
    if ([
      'zip',
      'rar',
      '7z',
      'tar',
      'gz',
      'bz2',
      'xz',
      'iso',
      'apk',
    ].contains(ext)) {
      return FileType.archive;
    }

    return FileType.file;
  }

  String get sizeFormatted => _formatBytes(size);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get typeIcon {
    switch (type) {
      case FileType.directory:
        return '📁';
      case FileType.image:
        return '🖼️';
      case FileType.video:
        return '🎥';
      case FileType.audio:
        return '🎵';
      case FileType.document:
        return '📄';
      case FileType.archive:
        return '📦';
      case FileType.file:
      case FileType.unknown:
      // ignore: unreachable_switch_default
      default:
        return '📄';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type.toString().split('.').last,
      'size': size,
      'sizeFormatted': sizeFormatted,
      'lastModified': lastModified?.toIso8601String(),
      'isHidden': isHidden,
      'mimeType': mimeType,
      'extension': extension,
      'isDirectory': type == FileType.directory,
    };
  }

  bool get isDirectory => type == FileType.directory;
  bool get isImage => type == FileType.image;
  bool get isVideo => type == FileType.video;
  bool get isAudio => type == FileType.audio;
  bool get isDocument => type == FileType.document;
}
