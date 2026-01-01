import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/files/domain/models/file_item.dart';
import 'package:mobile_app/features/media/data/services/media_service.dart';
import 'package:mobile_app/features/media/presentation/audio_player_screen.dart';

class AudioGalleryScreen extends StatefulWidget {
  const AudioGalleryScreen({super.key});

  @override
  State<AudioGalleryScreen> createState() => _AudioGalleryScreenState();
}

class _AudioGalleryScreenState extends State<AudioGalleryScreen> {
  List<FileItem> _audioFiles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final audioFiles = await MediaService.getAllAudio();
      setState(() {
        _audioFiles = audioFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load audio: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _audioFiles.isEmpty ? 'Audio' : 'Audio (${_audioFiles.length})',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAudio),
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
              onPressed: _loadAudio,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_audioFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No audio files found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Play All Button
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioPlayerScreen(
                    audioFiles: _audioFiles,
                    initialIndex: 0,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play All'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Audio List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAudio,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingSmall,
              ),
              itemCount: _audioFiles.length,
              itemBuilder: (context, index) {
                final audio = _audioFiles[index];
                return _buildAudioItem(audio, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioItem(FileItem audio, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: Colors.orange, size: 24),
        ),
        title: Text(
          audio.name,
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${audio.sizeFormatted} • ${audio.extension?.toUpperCase() ?? 'Audio'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.play_circle_outline,
            color: Colors.orange,
            size: 32,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(
                  audioFiles: _audioFiles,
                  initialIndex: index,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
