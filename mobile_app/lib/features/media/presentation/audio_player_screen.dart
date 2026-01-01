import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/files/domain/models/file_item.dart';

class AudioPlayerScreen extends StatefulWidget {
  final List<FileItem> audioFiles;
  final int initialIndex;

  const AudioPlayerScreen({
    super.key,
    required this.audioFiles,
    required this.initialIndex,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);

      if (state == PlayerState.completed) {
        _playNext();
      }
    });

    _playAudio(_currentIndex);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(int index) async {
    final audio = widget.audioFiles[index];
    await _audioPlayer.play(DeviceFileSource(audio.path));
    setState(() {
      _currentIndex = index;
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
    if (_currentIndex < widget.audioFiles.length - 1) {
      await _playAudio(_currentIndex + 1);
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      await _playAudio(_currentIndex - 1);
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final currentAudio = widget.audioFiles[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                size: 120,
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 40),

            // Song Title
            Text(
              currentAudio.name,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Song Info
            Text(
              '${_currentIndex + 1} of ${widget.audioFiles.length}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),

            const SizedBox(height: 40),

            // Progress Bar
            Column(
              children: [
                Slider(
                  value: _position.inSeconds.toDouble(),
                  max: _duration.inSeconds.toDouble() > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: Colors.orange,
                  inactiveColor: Colors.white24,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: Icon(
                    Icons.skip_previous,
                    color: _currentIndex > 0 ? Colors.white : Colors.white24,
                  ),
                  onPressed: _currentIndex > 0 ? _playPrevious : null,
                ),
                const SizedBox(width: 24),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 48,
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 48,
                  icon: Icon(
                    Icons.skip_next,
                    color: _currentIndex < widget.audioFiles.length - 1
                        ? Colors.white
                        : Colors.white24,
                  ),
                  onPressed: _currentIndex < widget.audioFiles.length - 1
                      ? _playNext
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
