// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/files/data/services/file_service.dart';
import 'package:mobile_app/features/files/domain/models/file_item.dart';

class FileBrowserScreen extends StatefulWidget {
  final String? initialPath;

  const FileBrowserScreen({super.key, this.initialPath});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  List<FileItem> _files = [];
  // ignore: prefer_final_fields
  List<String> _pathHistory = [];
  String? _currentPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null) {
      _loadFiles(widget.initialPath!);
    } else {
      _loadRoots();
    }
  }

  Future<void> _loadRoots() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _pathHistory.clear();
      _currentPath = null;
    });

    try {
      final roots = await FileService.getStorageRoots();
      setState(() {
        _files = roots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load storage: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFiles(String path, {bool addToHistory = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await FileService.listFiles(path, showHidden: false);

      print('📁 Loading path: $path');
      print('📁 Files found: ${files.length}');
      for (final file in files) {
        print(
          '   - ${file.name} (${file.type}) [${file.extension ?? "no ext"}]',
        );
      }

      setState(() {
        _files = files;
        if (addToHistory && _currentPath != null && _currentPath != path) {
          _pathHistory.add(_currentPath!);
        }
        _currentPath = path;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading files: $e');
      setState(() {
        _error = 'Failed to load files: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToFolder(FileItem item) {
    if (item.isDirectory) {
      _loadFiles(item.path, addToHistory: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File: ${item.name} (${item.sizeFormatted})'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateBack() {
    if (_pathHistory.isEmpty) {
      _loadRoots();
    } else {
      final previousPath = _pathHistory.removeLast();
      _loadFiles(previousPath, addToHistory: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath == null ? 'Storage' : _getPathName()),
        leading: _currentPath != null || _pathHistory.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_currentPath != null) {
                _loadFiles(_currentPath!, addToHistory: false);
              } else {
                _loadRoots();
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 64),
            const SizedBox(height: 16),
            Text('Error', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentPath != null) {
                  _loadFiles(_currentPath!, addToHistory: false);
                } else {
                  _loadRoots();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Empty folder',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentPath != null) {
          await _loadFiles(_currentPath!, addToHistory: false);
        } else {
          await _loadRoots();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return _buildFileItem(file);
        },
      ),
    );
  }

  Widget _buildFileItem(FileItem file) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      child: ListTile(
        leading: _buildFileIcon(file),
        title: Text(
          file.name,
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: file.isDirectory
            ? const Text('Folder')
            : Text(
                '${file.sizeFormatted}${file.extension != null ? ' • ${file.extension!.toUpperCase()}' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white54),
              ),
        trailing: file.isDirectory
            ? const Icon(Icons.chevron_right, color: AppTheme.primaryGreen)
            : null,
        onTap: () => _navigateToFolder(file),
      ),
    );
  }

  Widget _buildFileIcon(FileItem file) {
    IconData icon;
    Color color;

    switch (file.type) {
      case FileType.directory:
        icon = Icons.folder;
        color = AppTheme.primaryGreen;
        break;
      case FileType.image:
        icon = Icons.image;
        color = Colors.purple;
        break;
      case FileType.video:
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case FileType.audio:
        icon = Icons.audiotrack;
        color = Colors.orange;
        break;
      case FileType.document:
        icon = Icons.description;
        color = Colors.blue;
        break;
      case FileType.archive:
        icon = Icons.archive;
        color = Colors.amber;
        break;
      case FileType.file:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getPathName() {
    if (_currentPath == null) return 'Storage';
    final parts = _currentPath!.split('/');
    return parts.isEmpty ? 'Storage' : parts.last;
  }
}
