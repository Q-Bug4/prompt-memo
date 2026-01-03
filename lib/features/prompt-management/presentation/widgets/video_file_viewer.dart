import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget for viewing video files
class VideoFileViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const VideoFileViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<VideoFileViewer> createState() => _VideoFileViewerState();
}

class _VideoFileViewerState extends State<VideoFileViewer> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.filePath));
      await _controller.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: _hasError
          ? _buildError(context)
          : _controller.value.isInitialized
              ? _buildVideoPlayer()
              : const Center(
                  child: CircularProgressIndicator(),
                ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildPositionIndicator(),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.blue,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              _buildDurationIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.replay_10,
                onPressed: () {
                  _controller.seekTo(
                    _controller.value.position - const Duration(seconds: 10),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                icon: Icons.fast_rewind,
                onPressed: () {
                  _controller.seekTo(
                    _controller.value.position - const Duration(seconds:5),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildPlayPauseButton(),
              const SizedBox(width: 16),
              _buildControlButton(
                icon: Icons.fast_forward,
                onPressed: () {
                  _controller.seekTo(
                    _controller.value.position + const Duration(seconds: 5),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                icon: Icons.forward_10,
                onPressed: () {
                  _controller.seekTo(
                    _controller.value.position + const Duration(seconds: 10),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      iconSize: 32,
    );
  }

  Widget _buildPlayPauseButton() {
    final isPlaying = _controller.value.isPlaying;
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      iconSize: 48,
    );
  }

  Widget _buildPositionIndicator() {
    final position = _controller.value.position;
    return Text(
      _formatDuration(position),
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  Widget _buildDurationIndicator() {
    final duration = _controller.value.duration;
    return Text(
      _formatDuration(duration),
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load video',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeVideo,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
