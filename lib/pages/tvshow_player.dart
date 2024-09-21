import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media9/provider/playerprovider.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TvshowPlayer extends StatefulWidget {
  final String adURl;
  final String urlLink;
  const TvshowPlayer({super.key, required this.urlLink, required this.adURl});

  @override
  State<TvshowPlayer> createState() => TvshowPlayerState();
}

class TvshowPlayerState extends State<TvshowPlayer> {
  late YoutubePlayerController controller;
  late VideoPlayerController _adController;
  bool fullScreen = false;
  bool adCompleted = false;
  late PlayerProvider playerProvider;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _adController =
        VideoPlayerController.networkUrl(Uri.parse(widget.adURl.toString()));
    controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
    _initPlayer();
  }

  _initPlayer() async {
    await _adController.initialize().then((_) {
      setState(() {});
      _adController.play();
    });

    _adController.addListener(() {
      if (_adController.value.position == _adController.value.duration) {
        try {
          setState(() {
            adCompleted = true;
          });
          _initTvshowPlayer();
        } catch (e) {
          print(e);
        }
      }
    });
  }

  _initTvshowPlayer() async {
    debugPrint("videoUrl :===> ${widget.urlLink}");
    var videoId = YoutubePlayerController.convertUrlToId(widget.urlLink);
    debugPrint("videoId :====> $videoId");
    controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
    // }
    print(controller.value.playerState);
    Future.delayed(const Duration(microseconds: 200)).then((value) {
      if (!mounted) return;
      setState(() {});
    });
    print(controller.value.playerState);
    // if (widget.playType == "Video" || widget.playType != "Show") {
    //   /* Add Video view */
    //   await playerProvider.addVideoView(widget.videoId.toString(),
    //       widget.videoType.toString(), widget.otherId.toString());
    // }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (adCompleted == false) ...[
                _adController.value.isInitialized
                    ? Center(
                        child: AspectRatio(
                            aspectRatio: _adController.value.aspectRatio,
                            child: VideoPlayer(_adController)),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white))
              ] else
                _buildPlayer(),
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

  Widget _buildPlayer() {
    if (kIsWeb) {
      return YoutubePlayer(controller: controller);
    } else {
      return YoutubePlayerScaffold(
        backgroundColor: appBgColor,
        controller: controller,
        autoFullScreen: true,
        defaultOrientations: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        builder: (context, player) {
          return Scaffold(
            body: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (controller.value.playerState == PlayerState.playing) {
                    return player;
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    try {
      controller.pauseVideo();
      _adController.dispose();
      if (!kIsWeb) {
        controller.close();
      }
    } catch (e) {
      print(e);
    }
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
    if (!mounted) return Future.value(false);
    Navigator.pop(context, false);
    return Future.value(true);
    // if (widget.playType == "Video" || widget.playType == "Show") {
    //   if ((playerCPosition ?? 0) > 0) {
    //     /* Add to Continue */
    //     // await playerProvider.addToContinue(
    //     //     "${widget.videoId}", "${widget.videoType}", "$playerCPosition");
    //     if (!mounted) return Future.value(false);
    //     Navigator.pop(context, true);
    //     return Future.value(true);
    //   } else {
    //     if (!mounted) return Future.value(false);
    //     Navigator.pop(context, false);
    //     return Future.value(true);
    //   }
    // } else {
    //   if (!mounted) return Future.value(false);
    //   Navigator.pop(context, false);
    //   return Future.value(true);
    // }
  }
}
