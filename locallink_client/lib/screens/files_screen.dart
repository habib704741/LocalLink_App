import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/file_item.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'video_player_screen.dart';

class FilesScreen extends StatefulWidget {
  final LocalLinkRepository repository;

  const FilesScreen({super.key, required this.repository});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final List<String> _pathHistory = [];
  String? _currentPath;
  bool _isVideo(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  Future<List<FileItem>>? _filesFuture;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    setState(() {
      _filesFuture = widget.repository.getFiles(_currentPath);
    });
  }

  void _navigateToFolder(String path) {
    _pathHistory.add(_currentPath ?? 'Root');
    _currentPath = path;
    _loadFiles();
  }

  void _navigateBack() {
    if (_pathHistory.isNotEmpty) {
      setState(() {
        String previous = _pathHistory.removeLast();
        _currentPath = previous == 'Root' ? null : previous;
      });
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPath == null
              ? "Internal Storage"
              : _currentPath!.split('/').last,
        ),
        leading: _pathHistory.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBack,
              )
            : const BackButton(),
      ),
      body: FutureBuilder<List<FileItem>>(
        future: _filesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Empty Folder"));
          }

          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: Icon(
                  file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  color: file.isDirectory ? Colors.amber : Colors.blueGrey,
                ),
                title: Text(file.name),
                subtitle: file.isDirectory
                    ? null
                    : Text(_formatSize(file.size)),
                onTap: () {
                  if (file.isDirectory) {
                    _navigateToFolder(file.path);
                  } else if (_isVideo(file.name)) {
                    String relativeUrl =
                        "/api/download?path=${Uri.encodeComponent(file.path)}";

                    String url = "${html.window.location.origin}$relativeUrl";

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          videoUrl: url,
                          fileName: file.name,
                        ),
                      ),
                    );
                  } else {
                    _downloadFile(file);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    return "${(bytes / 1024).toStringAsFixed(1)} KB";
  }

  void _downloadFile(FileItem file) {
    final String downloadUrl =
        "/api/download?path=${Uri.encodeComponent(file.path)}";
    html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
    anchor.download = file.name;
    anchor.click();
  }
}
