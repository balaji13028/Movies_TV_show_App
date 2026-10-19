import 'dart:developer';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/utils.dart';
import 'package:media9/widget/nodata.dart';

class LiveTVPlayer extends StatefulWidget {
  final String? adURl;
  final String urlLink;

  const LiveTVPlayer({
    super.key,
    required this.urlLink,
    required this.adURl,
  });

  @override
  State<LiveTVPlayer> createState() => _LiveTVPlayerState();
}

class _LiveTVPlayerState extends State<LiveTVPlayer> {
  VideoPlayerController? _adController;
  VideoPlayerController? _liveTvController;
  ChewieController? _chewieController;

  bool adCompleted = false;
  bool isFormatError = false;
  bool isLoading = true;
  bool _startingLiveTv = false;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      WakelockPlus.enable();
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initializeVideoPlayers();
  }

  Future<void> _initializeVideoPlayers() async {
    try {
      // 1. Play the advertisement first, if available.
      final adUrl = widget.adURl?.trim();

      if (adUrl != null && adUrl.isNotEmpty) {
        _adController = VideoPlayerController.networkUrl(
          Uri.parse(adUrl),
        );

        await _adController!.initialize();

        if (!mounted) return;

        _adController!.addListener(_onAdVideoChanged);

        await _adController!.play();

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        // Do not initialize/start live TV until the ad finishes.
        return;
      }

      // No advertisement: start live TV directly.
      await _startLiveTv();
    } catch (e, stackTrace) {
      log('Ad initialization error: $e', stackTrace: stackTrace);

      // If the ad fails, attempt to play live TV.
      if (mounted) {
        await _startLiveTv();
      }
    }
  }

  void _onAdVideoChanged() {
    final controller = _adController;

    if (controller == null ||
        !controller.value.isInitialized ||
        adCompleted ||
        !controller.value.isCompleted) {
      return;
    }

    controller.removeListener(_onAdVideoChanged);

    if (!mounted) return;

    setState(() {
      adCompleted = true;
    });

    _startLiveTv();
  }

  Future<void> _startLiveTv() async {
    if (_startingLiveTv || !mounted) return;

    _startingLiveTv = true;

    try {
      // 2. Initialize the live stream only after the ad completes.
      final liveController = VideoPlayerController.networkUrl(
        Uri.parse(widget.urlLink),
      );

      _liveTvController = liveController;

      await liveController.initialize();

      if (!mounted) {
        await liveController.dispose();
        return;
      }

      // 3. Create the live TV player after successful initialization.
      final chewieController = ChewieController(
        videoPlayerController: liveController,
        autoPlay: true,
        looping: false,
        aspectRatio:16 / 9,
        fullScreenByDefault: false,
        allowFullScreen: false,
        isLive: false,
        materialProgressColors: ChewieProgressColors(
          bufferedColor: Colors.white54,
          playedColor: primaryColor,
          handleColor: primaryColor,
          backgroundColor: Colors.white24,
        ),
      );

      if (!mounted) {
        chewieController.dispose();
        return;
      }

      setState(() {
        _chewieController = chewieController;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      log('Live TV initialization error: $e', stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          isFormatError = true;
          isLoading = false;
        });
      }
    } finally {
      _startingLiveTv = false;
    }
  }

  @override
  void dispose() {
    _adController?.removeListener(_onAdVideoChanged);
    _adController?.dispose();
    _chewieController?.dispose();
    _liveTvController?.dispose();

    if (!kIsWeb) {
      WakelockPlus.disable();
    }

    if (!(kIsWeb || Constant.isTV)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  Future<bool> onBackPressed() async {
    await _adController?.pause();
    await _liveTvController?.pause();

    if (!(kIsWeb || Constant.isTV)) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    if (mounted) {
      Navigator.pop(context, false);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final adController = _adController;
    final chewieController = _chewieController;

    final showAd = adController != null && !adCompleted;

    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Advertisement is shown first.
              if (showAd) advertisementVideoSection(adController),

              // Show live TV only after the ad is complete.
              if (!showAd && !isFormatError)
                Center(
                  child: chewieController != null
                      ? AspectRatio(
                          aspectRatio: _liveTvController!.value.aspectRatio > 0
                              ? _liveTvController!.value.aspectRatio
                              : 16 / 9,
                          child: Chewie(
                            controller: chewieController,
                          ),
                        )
                      : const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                ),

              if (isFormatError)
                const Center(
                  child: NoData(
                    title: 'Unable to load',
                    subTitle: '',
                  ),
                ),

              if (!kIsWeb)
                Positioned(
                  top: 15,
                  left: 15,
                  child: InkWell(
                    onTap: onBackPressed,
                    focusColor: gray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    child: Utils.buildBackBtnDesign(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget advertisementVideoSection(VideoPlayerController adController) {
    return Center(
      child: adController.value.isInitialized
          ? AspectRatio(
              aspectRatio: adController.value.aspectRatio > 0
                  ? adController.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                children: [
                  // Advertisement video
                  Positioned.fill(
                    child: VideoPlayer(adController),
                  ),

                  // Circular countdown timer
                  Positioned(
                    right: 20,
                    top: 20,
                    child: ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: adController,
                      builder: (context, value, child) {
                        final duration = value.duration.inSeconds;
                        final position = value.position.inSeconds;

                        final remaining = (duration - position)
                            .clamp(0, duration > 0 ? duration : 1);

                        final progress = duration > 0
                            ? (position / duration).clamp(0.0, 1.0)
                            : 0.0;

                        return Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white30,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                '$remaining',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : const CircularProgressIndicator(
              color: Colors.white,
            ),
    );
  }
}
