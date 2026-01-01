import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
// ignore: unused_import
import 'package:web_client/core/api/api_client.dart';
import 'package:web_client/core/constants/app_constants.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart';
import 'package:video_player/video_player.dart';

// Video gallery provider
final videoGalleryProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final videos = await apiClient.getAllVideos();
  return videos ?? [];
});

class VideoGalleryScreen extends ConsumerWidget {
  const VideoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videoGalleryProvider);

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildGallery(context, ref, videos);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      ),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No videos found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 64),
          const SizedBox(height: 16),
          Text(
            'Error loading videos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(videoGalleryProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> videos,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${videos.length} ${videos.length == 1 ? 'Video' : 'Videos'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(videoGalleryProvider),
              ),
            ],
          ),
        ),

        // Video List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return _buildVideoItem(context, ref, videos[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> video,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 120,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.video_library, color: Colors.white24, size: 32),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          video['name'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${video['sizeFormatted']} • ${video['extension']?.toUpperCase() ?? 'Video'}',
          ),
        ),
        trailing: const Icon(
          Icons.play_circle_outline,
          color: AppTheme.primaryGreen,
          size: 36,
        ),
        onTap: () => _openVideoPlayer(context, ref, video),
      ),
    );
  }

  void _openVideoPlayer(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> video,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => _VideoPlayerScreen(video: video)),
    );
  }
}

// Video Player Screen
class _VideoPlayerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> video;

  const _VideoPlayerScreen({required this.video});

  @override
  ConsumerState<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<_VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  // ignore: unused_field
  String? _errorMessage;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final videoUrl = apiClient.getMediaFileUrl(widget.video['path']);

      print('🎥 Attempting to load video from: $videoUrl');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {'Accept': '*/*'},
      );

      _controller!.addListener(() {
        if (_controller!.value.hasError) {
          print('❌ Video player error: ${_controller!.value.errorDescription}');
          setState(() {
            _hasError = true;
            _errorMessage =
                _controller!.value.errorDescription ?? 'Unknown video error';
          });
        }
      });

      await _controller!.initialize();

      print('✅ Video initialized successfully');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
      }
    } catch (e) {
      print('❌ Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && !_hasError)
            GestureDetector(
              onTap: _toggleControls,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),

          if (!_isInitialized && !_hasError)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),

          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorRed,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cannot play this video format',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video['name'],
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final apiClient = ref.read(apiClientProvider);
                          final downloadUrl = apiClient.getDownloadUrl(
                            widget.video['path'],
                          );
                          final fileName = widget.video['name'];

                          final anchor =
                              web.document.createElement('a')
                                  as web.HTMLAnchorElement;
                          anchor.href = downloadUrl;
                          anchor.download = fileName;
                          anchor.click();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading $fileName'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download Video'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tip: MP4 videos work best in browsers. Other formats may need to be downloaded.',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          if (_isInitialized && !_hasError && _showControls)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.video['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Center(
                      child: IconButton(
                        iconSize: 72,
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppTheme.primaryGreen,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _formatDuration(_controller!.value.position),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Text(
                                ' / ',
                                style: TextStyle(color: Colors.white54),
                              ),
                              Text(
                                _formatDuration(_controller!.value.duration),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  _controller!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
