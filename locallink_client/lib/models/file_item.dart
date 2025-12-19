class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;

  FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
  });

  // Factory to convert JSON from the phone into a Dart object
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] ?? 'Unknown',
      path: json['path'] ?? '',
      isDirectory: json['isDirectory'] ?? false,
      size: json['size'] ?? 0,
    );
  }
}
