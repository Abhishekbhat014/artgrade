import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:hugeicons/hugeicons.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final VoidCallback onCompleted;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.onCompleted,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  Duration _watchedDuration = Duration.zero;
  Duration? _lastPosition;

  bool _markedCompleted = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  // ===============================
  // VIDEO INITIALIZATION
  // ===============================
  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoController.initialize();

      // Track watch progress
      _watchedDuration = Duration.zero;
      _lastPosition = null;
      _videoController.addListener(_trackProgress);

      final cs = Theme.of(context).colorScheme;

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,

        // Theme-aware progress colors
        materialProgressColors: ChewieProgressColors(
          playedColor: cs.primary,
          handleColor: cs.primary,
          bufferedColor: cs.onSurface.withOpacity(0.3),
          backgroundColor: cs.onSurface.withOpacity(0.15),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: cs.primary,
          handleColor: cs.primary,
          bufferedColor: cs.onSurface.withOpacity(0.3),
          backgroundColor: cs.onSurface.withOpacity(0.15),
        ),

        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(errorMessage, style: TextStyle(color: cs.onSurface)),
          );
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ Video initialization error: $e");
      if (mounted) setState(() => _isError = true);
    }
  }

  // ===============================
  // 90% WATCH TRACKING LOGIC
  // ===============================
  void _trackProgress() {
    if (_markedCompleted) return;

    final value = _videoController.value;

    if (!value.isInitialized || value.duration == Duration.zero) return;

    // Count ONLY when video is actually playing
    if (value.isPlaying) {
      if (_lastPosition != null) {
        final delta = value.position - _lastPosition!;

        // Ignore abnormal jumps (seeking / buffering)
        if (delta.inMilliseconds > 0 && delta.inSeconds <= 2) {
          _watchedDuration += delta;
        }
      }
      _lastPosition = value.position;
    }

    // Safety: ignore very short videos
    if (value.duration.inSeconds < 30) return;

    final watchedPercent =
        _watchedDuration.inMilliseconds / value.duration.inMilliseconds;

    if (watchedPercent >= 0.9) {
      _markedCompleted = true;
      debugPrint("🎉 Watched ${(_watchedDuration.inSeconds)}s → Completed");
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_trackProgress);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: cs.onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            fontSize: 18,
          ),
        ),
      ),

      body: SafeArea(child: _buildBody(theme, cs)),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme cs) {
    // ❌ Error State
    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 48,
              color: cs.error,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load video",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() => _isError = false);
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    // ⏳ Loading State
    if (_chewieController == null ||
        !_chewieController!.videoPlayerController.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: cs.primary, strokeWidth: 3),
      );
    }

    // ▶️ Player
    return Center(child: Chewie(controller: _chewieController!));
  }
}
