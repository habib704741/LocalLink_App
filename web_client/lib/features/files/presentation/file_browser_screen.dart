import 'dart:developer';
import 'dart:js_interop' as web;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:web_client/core/api/api_client.dart';
import 'package:web_client/core/constants/app_constants.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart';
import 'package:web/web.dart' as web;
// ignore: unused_import
import 'dart:typed_data';

// File browser state provider
final fileBrowserProvider =
    StateNotifierProvider.autoDispose<FileBrowserNotifier, FileBrowserState>((
      ref,
    ) {
      final apiClient = ref.watch(apiClientProvider);
      return FileBrowserNotifier(apiClient);
    });

class FileBrowserNotifier extends StateNotifier<FileBrowserState> {
  final ApiClient _apiClient;

  FileBrowserNotifier(this._apiClient) : super(FileBrowserState.initial()) {
    loadRoots();
  }

  Future<void> loadRoots() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final roots = await _apiClient.getStorageRoots();
      if (roots != null) {
        state = state.copyWith(
          files: roots,
          currentPath: null,
          pathHistory: [],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Failed to load storage roots',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: $e', isLoading: false);
    }
  }

  Future<void> loadFiles(String path, {bool addToHistory = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.listFiles(path);
      if (response != null) {
        final files = response['files'] as List<dynamic>;

        List<String> newHistory = [...state.pathHistory];
        if (addToHistory && state.currentPath != null) {
          newHistory.add(state.currentPath!);
        }

        state = state.copyWith(
          files: files,
          currentPath: path,
          pathHistory: newHistory,
          isLoading: false,
        );
      } else {
        state = state.copyWith(error: 'Failed to load files', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: $e', isLoading: false);
    }
  }

  void navigateBack() {
    if (state.pathHistory.isEmpty) {
      loadRoots();
    } else {
      final history = [...state.pathHistory];
      final previousPath = history.removeLast();

      state = state.copyWith(pathHistory: history);

      loadFiles(previousPath, addToHistory: false);
    }
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
  }
}

class FileBrowserState {
  final List<dynamic> files;
  final String? currentPath;
  final List<String> pathHistory;
  final bool isLoading;
  final String? error;
  final ViewMode viewMode;

  FileBrowserState({
    required this.files,
    this.currentPath,
    required this.pathHistory,
    required this.isLoading,
    this.error,
    required this.viewMode,
  });

  factory FileBrowserState.initial() {
    return FileBrowserState(
      files: [],
      pathHistory: [],
      isLoading: true,
      viewMode: ViewMode.grid,
    );
  }

  FileBrowserState copyWith({
    List<dynamic>? files,
    String? currentPath,
    List<String>? pathHistory,
    bool? isLoading,
    String? error,
    ViewMode? viewMode,
  }) {
    return FileBrowserState(
      files: files ?? this.files,
      currentPath: currentPath,
      pathHistory: pathHistory ?? this.pathHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

enum ViewMode { grid, list }

class FileBrowserScreen extends ConsumerWidget {
  const FileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileBrowserProvider);

    return Column(
      children: [
        _buildToolbar(context, ref, state),
        Expanded(child: _buildContent(context, ref, state)),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    FileBrowserState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (state.currentPath != null || state.pathHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                ref.read(fileBrowserProvider.notifier).navigateBack();
              },
              tooltip: 'Back',
            ),

          const SizedBox(width: 8),

          // Breadcrumb
          Expanded(child: _buildBreadcrumb(context, state)),

          // View mode toggle
          IconButton(
            icon: Icon(
              state.viewMode == ViewMode.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            onPressed: () {
              ref.read(fileBrowserProvider.notifier).toggleViewMode();
            },
            tooltip: state.viewMode == ViewMode.grid
                ? 'List view'
                : 'Grid view',
          ),

          const SizedBox(width: 8),

          // Upload button (only show when in a directory)
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _handleUpload(ref, state.currentPath!),
            tooltip: 'Upload File',
          ),

          const SizedBox(width: 8),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (state.currentPath != null) {
                ref
                    .read(fileBrowserProvider.notifier)
                    .loadFiles(state.currentPath!);
              } else {
                ref.read(fileBrowserProvider.notifier).loadRoots();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, FileBrowserState state) {
    if (state.currentPath == null) {
      return Text('Storage', style: Theme.of(context).textTheme.titleMedium);
    }

    final parts = state.currentPath!
        .split('/')
        .where((p) => p.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Storage',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
          for (var i = 0; i < parts.length; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right, size: 16, color: Colors.white54),
            ),
            Text(
              parts[i],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: i == parts.length - 1
                    ? AppTheme.primaryGreen
                    : Colors.white54,
                fontWeight: i == parts.length - 1
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    FileBrowserState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 64),
            const SizedBox(height: 16),
            Text('Error', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (state.currentPath != null) {
                  ref
                      .read(fileBrowserProvider.notifier)
                      .loadFiles(state.currentPath!);
                } else {
                  ref.read(fileBrowserProvider.notifier).loadRoots();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.white24),
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

    return state.viewMode == ViewMode.grid
        ? _buildGridView(context, ref, state)
        : _buildListView(context, ref, state);
  }

  Widget _buildGridView(
    BuildContext context,
    WidgetRef ref,
    FileBrowserState state,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: state.files.length,
      itemBuilder: (context, index) {
        final file = state.files[index];
        return _buildGridItem(context, ref, file);
      },
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> file,
  ) {
    final isDirectory = file['isDirectory'] ?? false;
    final name = file['name'] ?? 'Unknown';
    final type = file['type'] ?? 'file';

    return InkWell(
      onTap: () => _handleFileTap(ref, file),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFileIcon(type, isDirectory),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (!isDirectory) ...[
              const SizedBox(height: 4),
              Text(
                file['sizeFormatted'] ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    FileBrowserState state,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: state.files.length,
      itemBuilder: (context, index) {
        final file = state.files[index];
        return _buildListItem(context, ref, file);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> file,
  ) {
    final isDirectory = file['isDirectory'] ?? false;
    final name = file['name'] ?? 'Unknown';
    final type = file['type'] ?? 'file';
    final size = file['sizeFormatted'] ?? '';
    final extension = file['extension']?.toUpperCase() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildFileIcon(type, isDirectory, size: 32),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: isDirectory
            ? const Text('Folder')
            : Text('$size${extension.isNotEmpty ? ' • $extension' : ''}'),
        trailing: isDirectory
            ? const Icon(Icons.chevron_right, color: AppTheme.primaryGreen)
            : null,
        onTap: () => _handleFileTap(ref, file),
      ),
    );
  }

  Widget _buildFileIcon(String type, bool isDirectory, {double size = 48}) {
    IconData icon;
    Color color;

    if (isDirectory) {
      icon = Icons.folder;
      color = AppTheme.primaryGreen;
    } else {
      switch (type) {
        case 'image':
          icon = Icons.image;
          color = Colors.purple;
          break;
        case 'video':
          icon = Icons.videocam;
          color = Colors.red;
          break;
        case 'audio':
          icon = Icons.audiotrack;
          color = Colors.orange;
          break;
        case 'document':
          icon = Icons.description;
          color = Colors.blue;
          break;
        case 'archive':
          icon = Icons.archive;
          color = Colors.amber;
          break;
        default:
          icon = Icons.insert_drive_file;
          color = Colors.white54;
      }
    }

    return Icon(icon, color: color, size: size);
  }

  void _handleFileTap(WidgetRef ref, Map<String, dynamic> file) {
    final isDirectory = file['isDirectory'] ?? false;

    if (isDirectory) {
      final path = file['path'];
      ref.read(fileBrowserProvider.notifier).loadFiles(path);
    } else {
      // Show download dialog
      _showFileOptions(ref, file);
    }
  }

  void _showFileOptions(WidgetRef ref, Map<String, dynamic> file) {
    final context = ref.context;
    final apiClient = ref.read(apiClientProvider);
    final path = file['path'];
    final name = file['name'];
    final size = file['sizeFormatted'];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: $size'),
            const SizedBox(height: 8),
            Text('Type: ${file['extension']?.toUpperCase() ?? 'File'}'),
            const SizedBox(height: 8),
            Text(
              'Path: $path',
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _downloadFile(apiClient, path, name);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _downloadFile(ApiClient apiClient, String path, String fileName) {
    // Get download URL
    final downloadUrl = apiClient.getDownloadUrl(path);

    // Use modern web API to trigger download
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = downloadUrl;
    anchor.download = fileName;
    anchor.style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
  }

  void _handleUpload(WidgetRef ref, String destinationPath) async {
    // Create file input element
    final uploadInput =
        web.document.createElement('input') as web.HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.multiple = false;

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files != null && files.length > 0) {
        final file = files.item(0)!;
        await _uploadFile(ref, destinationPath, file);
      }
    });

    uploadInput.click();
  }

  Future<void> _uploadFile(
    WidgetRef ref,
    String destinationPath,
    web.File file,
  ) async {
    final context = ref.context;

    // Show uploading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Uploading...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text('Uploading ${file.name}'),
          ],
        ),
      ),
    );

    try {
      // Read file bytes
      final reader = web.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoadEnd.first;

      final arrayBuffer = reader.result as web.JSArrayBuffer;
      final bytes = arrayBuffer.toDart.asUint8List();

      // Upload file
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.uploadFile(
        destinationPath,
        bytes,
        file.name,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (result != null && result['success'] == true) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploaded ${file.name} successfully'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }

        // Refresh file list
        ref.read(fileBrowserProvider.notifier).loadFiles(destinationPath);
      } else {
        // Show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      log('Upload error: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
