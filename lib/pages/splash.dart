import 'dart:async';
import 'dart:developer';

import 'package:dtlive/pages/bottombar.dart';
import 'package:dtlive/pages/intro.dart';
import 'package:dtlive/provider/homeprovider.dart';
import 'package:dtlive/tvpages/tvhome.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/utils/sharedpre.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => SplashState();
}

class SplashState extends State<Splash> {
  late VideoPlayerController _controller;
  bool _visible = false;
  String? seen;
  SharedPre sharedPre = SharedPre();

  @override
  void initState() {
    isFirstCheck();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    playVideo();

    Future.delayed(const Duration(milliseconds: 3000)).then((value) {
      if (!mounted) return;
      navigator();
    });
    super.initState();
  }

  playVideo() {
    _controller = VideoPlayerController.asset("assets/videos/splashVideo.mp4");
    _controller.initialize().then((_) {
      _controller.setLooping(false);
      Timer(const Duration(milliseconds: 100), () {
        setState(() {
          _controller.play();
          _visible = true;
        });
        // _controller.addListener(() async {
        //   checkStatus();
        // });
      });
    });
  }

  checkStatus() async {
    if (_controller.value.isCompleted) {
      await navigator();
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    _controller.removeListener(checkStatus);
    _controller.dispose();
    _controller;
    super.dispose();
  }

  _getVideoBackground() {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1000),
      child: VideoPlayer(_controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        alignment: Alignment.center,
        // color: appBgColor,
        child: Center(
          child: _controller.value.isInitialized
              ? VideoPlayer(_controller)
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> isFirstCheck() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await homeProvider.setLoading(true);

    seen = await sharedPre.read('seen') ?? "0";
    Constant.userID = await sharedPre.read('userid');
    log('seen ==> $seen');
    log('Constant userID ==> ${Constant.userID}');
    if (!mounted) return;
  }

  navigator() {
    Future.delayed(const Duration(milliseconds: 0), () {
      if (kIsWeb || Constant.isTV) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const TVHome(pageName: "");
            },
          ),
        );
      } else {
        if (seen == "1") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const Bottombar();
              },
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const Intro();
              },
            ),
          );
        }
      }
    });
  }
}
