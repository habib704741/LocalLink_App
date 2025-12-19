import 'dart:io';

class FileService {
  String get rootPath => '/storage/emulated/0';

  List<Map<String, dynamic>> getFiles(String path) {
    try {
      final dir = Directory(path);
      final List<FileSystemEntity> entities = dir.listSync();

      return entities.map((entity) {
        final name = entity.path.split('/').last;
        final isDirectory = entity is Directory;

        return {
          'name': name,
          'path': entity.path,
          'isDirectory': isDirectory,
          'size': isDirectory ? 0 : (entity as File).lengthSync(),
        };
      }).toList();
    } catch (e) {
      print("Error reading directory: $e");
      return [];
    }
  }
}
