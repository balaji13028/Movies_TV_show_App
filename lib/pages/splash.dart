import 'dart:async';
import 'dart:developer';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:media9/pages/bottombar.dart';
import 'package:media9/pages/home.dart';
import 'package:media9/pages/intro.dart';
import 'package:media9/pagetransition.dart';
import 'package:media9/provider/homeprovider.dart';
import 'package:media9/tvpages/tvhome.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/sharedpre.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => SplashState();
}

class SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  String? seen;
  SharedPre sharedPre = SharedPre();

  @override
  void initState() {
    playVideo();
    // Future.delayed(const Duration(milliseconds: 4100)).then((value) async {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      seen = await sharedPre.read('seen') ?? "0";
      //     navigator();
      //   });

      isFirstCheck();
    });
    super.initState();
  }

  void playVideo() {
    print('is tv');
    if (Constant.isTV) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      print('is tv');
      // _controller = VideoPlayerController.asset('assets/videos/tv_splash_video.mp4');
      _controller = VideoPlayerController.asset('assets/videos/splash_screen_tv_video.mp4');
      print('_controller $_controller');
      _controller.initialize().then((_) {
        _controller.setLooping(false);
        Timer(const Duration(milliseconds: 100), () {
          setState(() {
            _controller.play();
          });
          _controller.addListener(() async {
            // checkStatus();
          });
        });
      });
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      _controller =
          // VideoPlayerController.asset("assets/videos/mobile_splash_video.mp4");
          VideoPlayerController.asset("assets/videos/splash_screen_mobile_video.mp4");
      _controller.initialize().then((_) {
        _controller.setLooping(false);
        Timer(const Duration(milliseconds: 100), () {
          setState(() {
            _controller.play();
          });
          _controller.addListener(() async {
            // checkStatus();
          });
        });
      });
    }
  }

  // checkStatus() async {
  //   if (_controller.value.isCompleted) {
  //     await navigator();
  //   }
  // }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    _controller.dispose();

    super.dispose();
  }

  // _getVideoBackground() {
  //   return AnimatedOpacity(
  //     opacity: _visible ? 1.0 : 0.0,
  //     duration: const Duration(milliseconds: 1000),
  //     child: VideoPlayer(_controller),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return
        // SizedBox(
        //     height: size.height,
        //     width: size.width,
        //     child: Center(child: VideoPlayer(_controller)));
        // FlutterSplashScreen.gif(
        //   gifPath: 'assets/videos/gif_splash.gif',
        //   gifWidth: size.width,
        //   gifHeight: size.height,
        //   nextScreen: const Intro(),
        //   duration: const Duration(milliseconds: 6775),
        //   onInit: () async {
        //     debugPrint("onInit");
        //   },
        //   onEnd: () async {
        //     debugPrint("onEnd 1");
        //   },
        // );

        Scaffold(
      body: AnimatedSplashScreen(
        curve: Curves.easeOutExpo,
        splash: SizedBox(
            height: size.height,
            width: size.width,
            child: Center(
                child: _controller.value.isInitialized
                    ? VideoPlayer(_controller)
                    : const CircularProgressIndicator())),
        nextScreen: kIsWeb || Constant.isTV
            ? const Home(pageName: '')
            : seen == '1'
                ? const Bottombar()
                : const Intro(),

        splashIconSize: size.height,
        centered: true,
        animationDuration: Duration(milliseconds: Constant.isTV ? 2600 : 2660),
        splashTransition: SplashTransition.fadeTransition,
        // customTween: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
        pageTransitionType: PageTransitionType.rightToLeftWithFade,
        // duration: 3440,
      ),
    );
  }

  Future<void> isFirstCheck() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    // await homeProvider.setLoading(true);

    seen = await sharedPre.read('seen') ?? "0";
    Constant.userID = await sharedPre.read('userid');
    log('seen ==> $seen');
    log('Constant userID ==> ${Constant.userID}');
    if (!mounted) return;
  }

  void navigator() {
    Future.delayed(const Duration(milliseconds: 0), () {
      if (kIsWeb || Constant.isTV) {
        return Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const TVHome(pageName: "");
            },
          ),
        );
      } else {
        if (seen == "1") {
          return Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const Bottombar();
              },
            ),
          );
        } else {
          return Navigator.pushReplacement(
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

// enum PageTransitionType {
//   fade,
//   rightToLeft,
//   leftToRight,
//   upToDown,
//   downToUp,
//   scale,
//   rotate,
//   size,
//   rightToLeftWithFade,
//   leftToRightWithFade,
// }
