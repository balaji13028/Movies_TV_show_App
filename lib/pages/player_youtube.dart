import 'dart:developer';

import 'package:media9/provider/playerprovider.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PlayerYoutube extends StatefulWidget {
  final int? videoId, videoType, typeId, otherId, stopTime;
  final String? playType, videoUrl, vUploadType, videoThumb;
   PlayerYoutube(
      this.playType,
      this.videoId,
      this.videoType,
      this.typeId,
      this.otherId,
      this.videoUrl,
      this.stopTime,
      this.vUploadType,
      this.videoThumb,
      {super.key});

  @override
  State<PlayerYoutube> createState() => PlayerYoutubeState();
}

class PlayerYoutubeState extends State<PlayerYoutube> {
  late YoutubePlayerController controller;
  bool fullScreen = false;
  late PlayerProvider playerProvider;
  int? playerCPosition, videoDuration;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _initPlayer();
  }

  _initPlayer() async {
    controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
    debugPrint("videoUrl :===> ${widget.videoUrl}");
    var videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl ?? "");
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

    Future.delayed(const Duration(microseconds: 200)).then((value) {
      if (!mounted) return;
      setState(() {});
    });
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

  @override
  void dispose() {
    controller.close();
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
    log("onBackPressed playerCPosition :===> $playerCPosition");
    log("onBackPressed videoDuration :===> $videoDuration");
    log("onBackPressed playType :===> ${widget.playType}");
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
