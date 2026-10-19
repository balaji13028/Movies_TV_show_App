import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/utils.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TvshowPlayer extends StatefulWidget {
  final String? adURl;
  final String urlLink;

  const TvshowPlayer({
    super.key,
    required this.urlLink,
    required this.adURl,
  });

  @override
  State<TvshowPlayer> createState() => TvshowPlayerState();
}

class TvshowPlayerState extends State<TvshowPlayer> {
  YoutubePlayerController? controller;
  VideoPlayerController? _adController;

  bool adCompleted = false;
  bool isLoading = true;
  bool isError = false;
  bool _startingYoutube = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final adUrl = widget.adURl?.trim();

    // Play the advertisement first, when available.
    if (adUrl != null && adUrl.isNotEmpty) {
      try {
        final adController = VideoPlayerController.networkUrl(
          Uri.parse(adUrl),
        );

        _adController = adController;

        await adController.initialize();

        if (!mounted) return;

        adController.addListener(_onAdChanged);

        await adController.play();

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        // Wait until the ad finishes before initializing YouTube.
        return;
      } catch (e, stackTrace) {
        log('Advertisement initialization error: $e',
            stackTrace: stackTrace);

        // Continue to YouTube if the ad cannot be played.
        if (mounted) {
          await _initializeYoutube();
        }
        return;
      }
    }

    // No advertisement URL: start YouTube directly.
    await _initializeYoutube();
  }

  void _onAdChanged() {
    final ad = _adController;

    if (ad == null ||
        !ad.value.isInitialized ||
        !ad.value.isCompleted ||
        adCompleted) {
      return;
    }

    ad.removeListener(_onAdChanged);

    if (!mounted) return;

    setState(() {
      adCompleted = true;
      isLoading = true;
    });

    _initializeYoutube();
  }

  Future<void> _initializeYoutube() async {
    if (_startingYoutube || !mounted) return;

    _startingYoutube = true;

    try {
      final videoId =
      YoutubePlayerController.convertUrlToId(widget.urlLink);

      if (videoId == null || videoId.isEmpty) {
        throw Exception('Invalid YouTube URL: ${widget.urlLink}');
      }

      log('YouTube video ID: $videoId');

      final youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          mute: false,
          showFullscreenButton: true,
          loop: false,
          origin: 'https://www.youtube-nocookie.com',
          enableJavaScript: true,
        ),
      );

      if (!mounted) {
        youtubeController.close();
        return;
      }

      controller = youtubeController;

      setState(() {
        isLoading = false;
        isError = false;
      });
    } catch (e, stackTrace) {
      log('YouTube initialization error: $e',
          stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } finally {
      _startingYoutube = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = _adController;
    final showAd = !adCompleted && ad != null;

    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Advertisement with circular countdown.
              if (showAd)
                Center(
                  child: ad.value.isInitialized
                      ? AspectRatio(
                    aspectRatio: ad.value.aspectRatio > 0
                        ? ad.value.aspectRatio
                        : 16 / 9,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: VideoPlayer(ad),
                        ),

                        // Circular timer in the bottom-right corner.
                        Positioned(
                          right: 20,
                          top: 20,
                          child: ValueListenableBuilder<
                              VideoPlayerValue>(
                            valueListenable: ad,
                            builder: (context, value, child) {
                              final duration =
                                  value.duration.inSeconds;
                              final position =
                                  value.position.inSeconds;

                              final remaining = duration > 0
                                  ? (duration - position)
                                  .clamp(0, duration)
                                  : 0;

                              final progress = duration > 0
                                  ? (position / duration)
                                  .clamp(0.0, 1.0)
                                  : 0.0;

                              return Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withOpacity(0.65),
                                  shape: BoxShape.circle,
                                ),
                                padding:
                                const EdgeInsets.all(4),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child:
                                      CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 3,
                                        backgroundColor:
                                        Colors.white30,
                                        valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                          primaryColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$remaining',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight:
                                        FontWeight.bold,
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
                )

              // YouTube is only shown after the ad completes.
              else if (!isError && controller != null)
                _buildYoutubePlayer()

              // Loading indicator.
              else if (!isError)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),

              // Error message.
              if (isError)
                const Center(
                  child: Text(
                    'Unable to load video',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              // Back button.
              if (!kIsWeb)
                Positioned(
                  top: 15,
                  left: 15,
                  child: SafeArea(
                    child: InkWell(
                      onTap: onBackPressed,
                      focusColor: gray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      child: Utils.buildBackBtnDesign(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYoutubePlayer() {
    final youtubeController = controller!;

    if (kIsWeb || Constant.isTV) {
      return YoutubePlayerControllerProvider(
        controller: youtubeController,
        child: YoutubePlayer(
          controller: youtubeController,
        ),
      );
    }

    return YoutubePlayerScaffold(
      backgroundColor: appBgColor,
      controller: youtubeController,
      autoFullScreen: true,
      defaultOrientations: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      builder: (context, player) {
        return Center(child: player);
      },
    );
  }

  Future<bool> onBackPressed() async {
    if (!(kIsWeb || Constant.isTV)) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    if (!mounted) return false;

    Navigator.pop(context, false);
    return true;
  }

  @override
  void dispose() {
    _adController?.removeListener(_onAdChanged);
    _adController?.dispose();

    controller?.close();

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
}