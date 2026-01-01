import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:web_client/core/constants/app_constants.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart';

// Audio gallery provider
final audioGalleryProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final audioFiles = await apiClient.getAllAudio();
  return audioFiles ?? [];
});

class AudioGalleryScreen extends ConsumerStatefulWidget {
  const AudioGalleryScreen({super.key});

  @override
  ConsumerState<AudioGalleryScreen> createState() => _AudioGalleryScreenState();
}

class _AudioGalleryScreenState extends ConsumerState<AudioGalleryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingIndex;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }

      if (state == PlayerState.completed) {
        _playNext();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(List<dynamic> audioFiles, int index) async {
    final apiClient = ref.read(apiClientProvider);
    final audio = audioFiles[index];
    final audioUrl = apiClient.getMediaFileUrl(audio['path']);

    await _audioPlayer.play(UrlSource(audioUrl));
    setState(() {
      _currentlyPlayingIndex = index;
      _position = Duration.zero;
    });
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _playNext() async {
    final audioAsync = ref.read(audioGalleryProvider);
    audioAsync.whenData((audioFiles) {
      if (_currentlyPlayingIndex != null &&
          _currentlyPlayingIndex! < audioFiles.length - 1) {
        _playAudio(audioFiles, _currentlyPlayingIndex! + 1);
      }
    });
  }

  Future<void> _playPrevious() async {
    final audioAsync = ref.read(audioGalleryProvider);
    audioAsync.whenData((audioFiles) {
      if (_currentlyPlayingIndex != null && _currentlyPlayingIndex! > 0) {
        _playAudio(audioFiles, _currentlyPlayingIndex! - 1);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final audioAsync = ref.watch(audioGalleryProvider);

    return Column(
      children: [
        Expanded(
          child: audioAsync.when(
            data: (audioFiles) {
              if (audioFiles.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildAudioList(context, audioFiles);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),
            error: (error, stack) => _buildErrorState(context, error),
          ),
        ),

        // Bottom Player
        if (_currentlyPlayingIndex != null) _buildBottomPlayer(audioAsync),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No audio files found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 64),
          const SizedBox(height: 16),
          Text(
            'Error loading audio',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(audioGalleryProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioList(BuildContext context, List<dynamic> audioFiles) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${audioFiles.length} ${audioFiles.length == 1 ? 'Song' : 'Songs'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _playAudio(audioFiles, 0),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(audioGalleryProvider),
              ),
            ],
          ),
        ),

        // Audio List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: audioFiles.length,
            itemBuilder: (context, index) {
              return _buildAudioItem(audioFiles, audioFiles[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAudioItem(
    List<dynamic> audioFiles,
    Map<String, dynamic> audio,
    int index,
  ) {
    final isPlaying = _currentlyPlayingIndex == index && _isPlaying;
    final isCurrentTrack = _currentlyPlayingIndex == index;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentTrack ? AppTheme.primaryGreen.withOpacity(0.1) : null,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPlaying ? Icons.equalizer : Icons.music_note,
            color: Colors.orange,
          ),
        ),
        title: Text(
          audio['name'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrentTrack ? AppTheme.primaryGreen : null,
            fontWeight: isCurrentTrack ? FontWeight.w600 : null,
          ),
        ),
        subtitle: Text(
          '${audio['sizeFormatted']} • ${audio['extension']?.toUpperCase() ?? 'Audio'}',
        ),
        trailing: IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
            color: Colors.orange,
            size: 36,
          ),
          onPressed: () {
            if (isCurrentTrack && _isPlaying) {
              _togglePlayPause();
            } else {
              _playAudio(audioFiles, index);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBottomPlayer(AsyncValue<List<dynamic>> audioAsync) {
    return audioAsync.when(
      data: (audioFiles) {
        if (_currentlyPlayingIndex == null) return const SizedBox.shrink();

        final currentAudio = audioFiles[_currentlyPlayingIndex!];

        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            children: [
              // Progress Bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                ),
                child: Slider(
                  value: _position.inSeconds.toDouble(),
                  max: _duration.inSeconds.toDouble() > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: Colors.orange,
                  inactiveColor: Colors.white24,
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Current Song Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentAudio['name'],
                              style: Theme.of(context).textTheme.bodyLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          color: _currentlyPlayingIndex! > 0
                              ? Colors.white
                              : Colors.white24,
                        ),
                        onPressed: _currentlyPlayingIndex! > 0
                            ? _playPrevious
                            : null,
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.orange,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next,
                          color: _currentlyPlayingIndex! < audioFiles.length - 1
                              ? Colors.white
                              : Colors.white24,
                        ),
                        onPressed:
                            _currentlyPlayingIndex! < audioFiles.length - 1
                            ? _playNext
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
