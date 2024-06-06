import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: true,
            looping: true,
            allowedScreenSleep: false,
            allowPlaybackSpeedChanging: false,
            allowMuting: false,
            showControls: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: Colors.red,
              handleColor: Colors.red,
              backgroundColor: Colors.white,
              bufferedColor: Colors.lightGreen,
            ),
            placeholder: Container(
              color: Colors.white,
            ),
            autoInitialize: true,
            fullScreenByDefault: _isFullScreen,
            customControls: Container(
              child: IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  setState(() {
                    _isFullScreen = !_isFullScreen;
                    _chewieController?.enterFullScreen();
                  });
                },
              ),
            ),
          );
        });
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  @override
Widget build(BuildContext context) {
  return _chewieController != null &&
      _chewieController!.videoPlayerController.value.isInitialized
      ? AspectRatio(
          aspectRatio: _chewieController!.videoPlayerController.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        )
      : const Center(
          child: CircularProgressIndicator(),
        );
}

}
