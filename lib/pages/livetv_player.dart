import 'dart:developer';

import 'package:chewie/chewie.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class LiveTVPlayer extends StatefulWidget {
  final String urlLink;
  const LiveTVPlayer({super.key, required this.urlLink});

  @override
  _LiveTVPlayerState createState() => _LiveTVPlayerState();
}

class _LiveTVPlayerState extends State<LiveTVPlayer> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    initializeLate();
    super.initState();
  }

  initializeLate() async {
    log(widget.urlLink.toString());
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.urlLink));
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
        // overlay: SafeArea(
        //   child: Padding(
        //     padding: const EdgeInsets.only(left: 2, top: 10),
        //     child: IconButton(
        //         onPressed: () {
        //           SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        //               overlays: SystemUiOverlay.values);
        //           // if (!mounted) return Future.value(false);
        //           Navigator.pop(context, false);
        //         },
        //         icon: const Icon(Icons.arrow_back_sharp,
        //             size: 22, color: Colors.white)),
        //   ),
        // ),
        // isLive: true,
        // allowFullScreen: true,
        // allowedScreenSleep: true,
        videoPlayerController: _videoPlayerController,
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
    // )
    Future.delayed(const Duration(microseconds: 300)).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
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
        body: Center(
          child: _videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController)
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
