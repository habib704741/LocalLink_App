import 'package:flutter/material.dart';
import '../file_service.dart';
import 'package:open_filex/open_filex.dart';

class DeviceFilesScreen extends StatefulWidget {
  const DeviceFilesScreen({super.key});

  @override
  State<DeviceFilesScreen> createState() => _DeviceFilesScreenState();
}

class _DeviceFilesScreenState extends State<DeviceFilesScreen> {
  final FileService _fileService = FileService();

  final List<String> _pathHistory = [];
  String? _currentPath;

  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    final path = _currentPath ?? _fileService.rootPath;

    setState(() {
      _files = _fileService.getFiles(path);
    });
  }

  void _navigateToFolder(String path) {
    _pathHistory.add(_currentPath ?? _fileService.rootPath);
    _currentPath = path;
    _loadFiles();
  }

  void _navigateBack() {
    if (_pathHistory.isNotEmpty) {
      setState(() {
        _currentPath = _pathHistory.removeLast();
        if (_currentPath == _fileService.rootPath) {
          _currentPath = null;
        }
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
      body: _files.isEmpty
          ? const Center(child: Text("Empty Folder"))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final bool isDir = file['isDirectory'];

                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.insert_drive_file,
                    color: isDir ? Colors.amber : Colors.blueGrey,
                  ),
                  title: Text(file['name']),
                  subtitle: isDir ? null : Text(_formatSize(file['size'])),
                  onTap: () {
                    if (isDir) {
                      _navigateToFolder(file['path']);
                    } else {
                      OpenFilex.open(file['path']);
                    }
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
}
