import 'dart:developer' as log;
import 'dart:math';

// import 'dart:math';

import 'package:chewie/chewie.dart';
import 'package:dtlive/provider/adventisements_provider.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class LiveTVPlayer extends StatefulWidget {
  final String adURl;
  final String urlLink;
  const LiveTVPlayer({super.key, required this.urlLink, required this.adURl});

  @override
  _LiveTVPlayerState createState() => _LiveTVPlayerState();
}

class _LiveTVPlayerState extends State<LiveTVPlayer> {
  late VideoPlayerController _adController;
  late VideoPlayerController _liveTvController;
  late ChewieController _chewieController;
  bool adCompleted = false;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);

    _adController =
        VideoPlayerController.networkUrl(Uri.parse(widget.adURl.toString()));

    _initializeVideoPlayers();

    super.initState();
  }

  Future<void> _initializeVideoPlayers() async {
    await _adController.initialize().then((_) {
      setState(() {});
      _adController.play();
    });

    _liveTvController =
        VideoPlayerController.networkUrl(Uri.parse(widget.urlLink));
    _liveTvController.initialize();

    // Listen for ad video completion
    _adController.addListener(() {
      if (_adController.value.position == _adController.value.duration) {
        setState(() {
          adCompleted = true;
        });
        _playLiveTv();
      }
    });
  }

  void _playLiveTv() async {
    _chewieController = ChewieController(
        videoPlayerController: _liveTvController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        fullScreenByDefault: true,
        materialProgressColors: ChewieProgressColors(
          bufferedColor: Colors.white54,
          playedColor: primaryColor,
          handleColor: primaryColor,
          backgroundColor: Colors.white24,
        ));
  }

  @override
  void dispose() {
    _adController.dispose();
    _liveTvController.dispose();
    _chewieController.dispose();
    if (!(kIsWeb || Constant.isTV)) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Future<bool> onBackPressed() async {
    if (!(kIsWeb || Constant.isTV)) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    // if (!mounted) return Future.value(false);
    Navigator.pop(context, false);
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: adCompleted == false
                  ? _adController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _adController.value.aspectRatio,
                          child: VideoPlayer(_adController),
                        )
                      : const CircularProgressIndicator(color: Colors.white)
                  : _liveTvController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _liveTvController.value.aspectRatio,
                          child: Chewie(controller: _chewieController),
                        )
                      : const CircularProgressIndicator(color: Colors.white),
            ),
            //back button.
            Positioned(
              top: 35.0, // Adjust the position as needed
              left: 16.0, // Adjust the position as needed
              child: Visibility(
                visible: adCompleted,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30.0),
                  onPressed: () {
                    // Stop the video and dispose of the controllers before navigating back
                    if (_chewieController
                        .videoPlayerController.value.isPlaying) {
                      _chewieController.pause();
                    }
                    onBackPressed();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
