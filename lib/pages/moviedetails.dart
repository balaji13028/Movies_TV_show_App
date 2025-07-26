import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:media9/main.dart';
import 'package:media9/model/sectiondetailmodel.dart';
import 'package:media9/pages/castdetails.dart';
import 'package:media9/pages/loginsocial.dart';
import 'package:media9/pages/mydownloads.dart';
import 'package:media9/provider/homeprovider.dart';
import 'package:media9/provider/videodetailsprovider.dart';
import 'package:media9/provider/videodownloadprovider.dart';
import 'package:media9/shimmer/shimmerutils.dart';
import 'package:media9/subscription/subscription.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/dimens.dart';
import 'package:media9/utils/strings.dart';
import 'package:media9/utils/utils.dart';
import 'package:media9/webwidget/footerweb.dart';
import 'package:media9/widget/castcrew.dart';
import 'package:media9/widget/moredetails.dart';
import 'package:media9/widget/myimage.dart';
import 'package:media9/widget/mynetworkimg.dart';
import 'package:media9/widget/mytext.dart';
import 'package:media9/widget/myusernetworkimg.dart';
import 'package:media9/widget/nodata.dart';
import 'package:media9/widget/relatedvideoshow.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class MovieDetails extends StatefulWidget {
  final int videoId, upcomingType, videoType, typeId;
  const MovieDetails(
      this.videoId, this.upcomingType, this.videoType, this.typeId,
      {super.key});

  @override
  State<MovieDetails> createState() => MovieDetailsState();
}

class MovieDetailsState extends State<MovieDetails> with RouteAware {
  /* Trailer init */
  VideoPlayerController? _trailerNormalController;
  YoutubePlayerController? _trailerYoutubeController;

  /* Download init */
  late VideoDownloadProvider downloadProvider;
  // late bool _permissionReady;
  final ReceivePort _port = ReceivePort();

  String? audioLanguages;
  List<Cast>? directorList;
  late VideoDetailsProvider videoDetailsProvider;
  late HomeProvider homeProvider;
  Map<String, String> qualityUrlList = <String, String>{};

  @override
  void initState() {
    if (!kIsWeb) {
      /* Download init ****/
      _bindBackgroundIsolate();
      FlutterDownloader.registerCallback(downloadCallback, step: 1); /* ****/
    }

    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    videoDetailsProvider =
        Provider.of<VideoDetailsProvider>(context, listen: false);
    downloadProvider =
        Provider.of<VideoDownloadProvider>(context, listen: false);
    super.initState();
    log("initState videoId ==> ${widget.videoId}");
    log("initState videoType ==> ${widget.videoType}");
    log("initState typeId ==> ${widget.typeId}");
    _getData();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  /// Called when the current route has been popped off.
  @override
  void didPop() {
    debugPrint("didPop");
    super.didPop();
  }

  /// Called when the top route has been popped off, and the current route
  /// shows up.
  @override
  void didPopNext() {
    debugPrint("didPopNext");
    if (videoDetailsProvider.sectionDetailModel.result?.trailerType ==
        "youtube") {
      if (_trailerYoutubeController == null) {
        loadTrailer(
            videoDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        if (_trailerYoutubeController != null) {
          _trailerYoutubeController?.seekTo(seconds: 0.0);
          _trailerYoutubeController?.playVideo();
        }
      }
    } else {
      if (_trailerNormalController == null) {
        loadTrailer(
            videoDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        if (_trailerNormalController != null) {
          _trailerNormalController?.play();
        }
      }
    }
    super.didPopNext();
  }

  /// Called when the current route has been pushed.
  @override
  void didPush() {
    debugPrint("didPush");
    super.didPush();
  }

  /// Called when a new route has been pushed, and the current route is no
  /// longer visible.
  @override
  void didPushNext() {
    debugPrint("didPushNext");
    if (_trailerYoutubeController != null) {
      _trailerYoutubeController?.close();
      _trailerYoutubeController = null;
    }
    if (_trailerNormalController != null) {
      _trailerNormalController?.dispose();
      _trailerNormalController = null;
    }
    super.didPushNext();
  }

  _getData() async {
    Utils.getCurrencySymbol();
    await videoDetailsProvider.getSectionDetails(
        widget.typeId, widget.videoType, widget.videoId, widget.upcomingType);

    if (videoDetailsProvider.sectionDetailModel.status == 200) {
      if (videoDetailsProvider.sectionDetailModel.result != null) {
        /* Trailer set-up */
        _setUpTrailer();

        /* Set-up Subtitle URLs */
        Utils.setSubtitleURLs(
          subtitleUrl1:
              (videoDetailsProvider.sectionDetailModel.result?.subtitle1 ?? ""),
          subtitleUrl2:
              (videoDetailsProvider.sectionDetailModel.result?.subtitle2 ?? ""),
          subtitleUrl3:
              (videoDetailsProvider.sectionDetailModel.result?.subtitle3 ?? ""),
          subtitleLang1:
              (videoDetailsProvider.sectionDetailModel.result?.subtitleLang1 ??
                  ""),
          subtitleLang2:
              (videoDetailsProvider.sectionDetailModel.result?.subtitleLang2 ??
                  ""),
          subtitleLang3:
              (videoDetailsProvider.sectionDetailModel.result?.subtitleLang3 ??
                  ""),
        );
      }
    }

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  /* Trailer Set-Up & Loading START */
  _setUpTrailer() {
    debugPrint(
        "trailerUrl ===========> ${videoDetailsProvider.sectionDetailModel.result?.trailerUrl}");
    debugPrint(
        "trailerType ==========> ${videoDetailsProvider.sectionDetailModel.result?.trailerType}");
    if (videoDetailsProvider.sectionDetailModel.result?.trailerType ==
        "youtube") {
      if (_trailerYoutubeController == null) {
        loadTrailer(
            videoDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        _trailerYoutubeController?.seekTo(seconds: 0.0);
      }
    } else {
      if (_trailerNormalController == null) {
        loadTrailer(
            videoDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        _trailerNormalController?.seekTo(Duration.zero);
      }
    }
  }

  Future<void> loadTrailer(trailerUrl, trailerType) async {
    debugPrint("loadTrailer URL ==========> $trailerUrl");
    debugPrint("loadTrailer Type =========> $trailerType");
    if (trailerType == "youtube") {
      var videoId = YoutubePlayerController.convertUrlToId(trailerUrl ?? "");
      debugPrint("Youtube Trailer videoId :====> $videoId");
      _trailerYoutubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId ?? '',
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: false,
          showVideoAnnotations: false,
          playsInline: false,
          mute: false,
          showFullscreenButton: false,
          loop: false,
        ),
      );
      _trailerYoutubeController?.playVideo();
      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    } else {
      _trailerNormalController =
          VideoPlayerController.networkUrl(Uri.parse(trailerUrl ?? ""))
            ..initialize().then((value) {
              if (!mounted) return;
              setState(() {
                debugPrint(
                    "isPlaying =========> ${_trailerNormalController?.value.isPlaying}");
                _trailerNormalController?.play();
              });
            });
      _trailerNormalController?.setLooping(true);
      _trailerNormalController?.addListener(() async {
        if (_trailerNormalController?.value.hasError ?? false) {
          debugPrint(
              "VideoScreen errorDescription ====> ${_trailerNormalController?.value.errorDescription}");
        }
      });
    }
  }
  /* Trailer Set-Up & Loading END */

  void _bindBackgroundIsolate() {
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      Constant.videoDownloadPort,
    );
    log('_bindBackgroundIsolate isSuccess ============> $isSuccess');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      final taskId = (data as List<dynamic>)[0] as String;
      final status = DownloadTaskStatus.fromInt(data[1] as int);

      final progress = data[2] as int;

      log(
        'Callback on UI isolate: '
        'task ($taskId) is in status ($status) and process ($progress)',
      );

      if (downloadProvider.currentTasks != null &&
          downloadProvider.currentTasks!.isNotEmpty) {
        log('currentTask ============> ${downloadProvider.currentTasks?.length}');
        final task = downloadProvider.currentTasks!
            .firstWhere((task) => task.taskId == taskId);
        log('task status ============> ${task.status}');
        if (progress > 0) {
          downloadProvider.setDownloadProgress(progress);
        }
        if (status == DownloadTaskStatus.complete && progress == 100) {
          Utils.setDownloadComplete(
            context,
            "Video",
            videoDetailsProvider.sectionDetailModel.result?.id,
            videoDetailsProvider.sectionDetailModel.result?.videoType,
            videoDetailsProvider.sectionDetailModel.result?.typeId,
            0,
          );
        }
      }
    });
  }

  void _unbindBackgroundIsolate() {
    log('_unbindBackgroundIsolate');
    IsolateNameServer.removePortNameMapping(Constant.videoDownloadPort);
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
    String id,
    int status,
    int progress,
  ) {
    log(
      'Callback on background isolate: '
      'task ($id) is in status ($status) and process ($progress)',
    );

    if (!kIsWeb) {
      IsolateNameServer.lookupPortByName(Constant.videoDownloadPort)
          ?.send([id, status, progress]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    if (!(kIsWeb || Constant.isTV)) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    routeObserver.unsubscribe(this);
    log("dispose isBroadcast ============================> ${_port.isBroadcast}");
    if (!_port.isBroadcast) {
      downloadProvider.clearProvider();
      videoDetailsProvider.clearProvider();
    }
    if (_trailerYoutubeController != null) {
      _trailerYoutubeController?.close();
      _trailerYoutubeController = null;
    }
    if (_trailerNormalController != null) {
      _trailerNormalController?.dispose();
      _trailerNormalController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (videoDetailsProvider.sectionDetailModel.status == 200) {
      if (videoDetailsProvider.sectionDetailModel.cast != null &&
          (videoDetailsProvider.sectionDetailModel.cast?.length ?? 0) > 0) {
        directorList = <Cast>[];
        for (int i = 0;
            i < (videoDetailsProvider.sectionDetailModel.cast?.length ?? 0);
            i++) {
          if (videoDetailsProvider.sectionDetailModel.cast?[i].type ==
              "Director") {
            Cast cast = Cast();
            cast.id = videoDetailsProvider.sectionDetailModel.cast?[i].id ?? 0;
            cast.name =
                videoDetailsProvider.sectionDetailModel.cast?[i].name ?? "";
            cast.image =
                videoDetailsProvider.sectionDetailModel.cast?[i].image ?? "";
            cast.type =
                videoDetailsProvider.sectionDetailModel.cast?[i].type ?? "";
            cast.personalInfo =
                videoDetailsProvider.sectionDetailModel.cast?[i].personalInfo ??
                    "";
            cast.status =
                videoDetailsProvider.sectionDetailModel.cast?[i].status ?? 0;
            cast.createdAt =
                videoDetailsProvider.sectionDetailModel.cast?[i].createdAt ??
                    "";
            cast.updatedAt =
                videoDetailsProvider.sectionDetailModel.cast?[i].updatedAt ??
                    "";
            directorList?.add(cast);
            log("directorList size ===> ${directorList?.length ?? 0}");
          }
        }
      }
      if (videoDetailsProvider.sectionDetailModel.language != null &&
          (videoDetailsProvider.sectionDetailModel.language?.length ?? 0) > 0) {
        for (int i = 0;
            i < (videoDetailsProvider.sectionDetailModel.language?.length ?? 0);
            i++) {
          if (i == 0) {
            audioLanguages =
                videoDetailsProvider.sectionDetailModel.language?[i].name ?? "";
          } else {
            audioLanguages =
                "$audioLanguages, ${videoDetailsProvider.sectionDetailModel.language?[i].name ?? ""}";
          }
        }
      }
    }
    return Scaffold(
      key: widget.key,
      backgroundColor: appBgColor,
      body: SafeArea(
        child: _buildUIWithAppBar(),
      ),
    );
  }

  Widget _buildUIWithAppBar() {
    return (videoDetailsProvider.loading)
        ? SingleChildScrollView(
            child: ((kIsWeb || Constant.isTV) &&
                    MediaQuery.of(context).size.width > 720)
                ? ShimmerUtils.buildDetailWebShimmer(context, "video")
                : ShimmerUtils.buildDetailMobileShimmer(context, "video"),
          )
        : (videoDetailsProvider.sectionDetailModel.status == 200 &&
                videoDetailsProvider.sectionDetailModel.result != null)
            ? (((kIsWeb || Constant.isTV) &&
                    MediaQuery.of(context).size.width > 720)
                ? _buildWebData()
                : _buildMobileData())
            : const NoData(title: '', subTitle: '');
  }

  Widget _buildMobileData() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            /* Poster */
            ((videoDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "")
                    .isNotEmpty)
                ? setUpTrailerView()
                : _buildMobilePoster(),

            /* Other Details */
            Container(
              transform: Matrix4.translationValues(0, -kToolbarHeight, 0),
              child: Column(
                children: [
                  /* Small Poster, Main title, ReleaseYear, Duration, Age Restriction, Video Quality */
                  Container(
                    width: MediaQuery.of(context).size.width,
                    constraints: const BoxConstraints(minHeight: 85),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 65,
                          height: 85,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: MyNetworkImage(
                              fit: BoxFit.cover,
                              imgHeight: 85,
                              imgWidth: 65,
                              imageUrl: videoDetailsProvider
                                      .sectionDetailModel.result?.thumbnail ??
                                  "",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              MyText(
                                color: white,
                                text: videoDetailsProvider
                                        .sectionDetailModel.result?.name ??
                                    "",
                                textalign: TextAlign.start,
                                fontsizeNormal: 20,
                                fontsizeWeb: 24,
                                fontweight: FontWeight.w800,
                                maxline: 2,
                                multilanguage: false,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  /* Release Year */
                                  (videoDetailsProvider.sectionDetailModel
                                                  .result?.releaseYear !=
                                              null &&
                                          videoDetailsProvider
                                                  .sectionDetailModel
                                                  .result
                                                  ?.releaseYear !=
                                              "")
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(right: 10),
                                          child: MyText(
                                            color: whiteLight,
                                            text: videoDetailsProvider
                                                    .sectionDetailModel
                                                    .result
                                                    ?.releaseYear ??
                                                "",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 13,
                                            fontsizeWeb: 15,
                                            fontweight: FontWeight.w500,
                                            multilanguage: false,
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  /* Duration */
                                  (videoDetailsProvider.sectionDetailModel
                                              .result?.videoDuration !=
                                          null)
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(right: 10),
                                          child: MyText(
                                            color: otherColor,
                                            multilanguage: false,
                                            text: ((videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.videoDuration ??
                                                        0) >
                                                    0)
                                                ? Utils.convertTimeToText(
                                                    videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.videoDuration ??
                                                        0)
                                                : "",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 13,
                                            fontsizeWeb: 15,
                                            fontweight: FontWeight.w500,
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  /* MaxQuality */
                                  (videoDetailsProvider.sectionDetailModel
                                                  .result?.maxVideoQuality !=
                                              null &&
                                          videoDetailsProvider
                                                  .sectionDetailModel
                                                  .result
                                                  ?.maxVideoQuality !=
                                              "")
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(right: 10),
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 1, 5, 1),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: otherColor,
                                              width: .7,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            shape: BoxShape.rectangle,
                                          ),
                                          child: MyText(
                                            color: otherColor,
                                            text: videoDetailsProvider
                                                    .sectionDetailModel
                                                    .result
                                                    ?.maxVideoQuality ??
                                                "",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 10,
                                            fontsizeWeb: 12,
                                            fontweight: FontWeight.w500,
                                            multilanguage: false,
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  /* Release Date */
                  _buildReleaseDate(),

                  /* Prime TAG */
                  (videoDetailsProvider.sectionDetailModel.result?.isPremium ??
                              0) ==
                          1
                      ? Container(
                          margin: const EdgeInsets.fromLTRB(20, 11, 20, 0),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              MyText(
                                color: primaryColor,
                                text: "primetag",
                                textalign: TextAlign.start,
                                fontsizeNormal: 12,
                                fontsizeWeb: 15,
                                fontweight: FontWeight.w700,
                                multilanguage: true,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(height: 2),
                              MyText(
                                color: white,
                                text: "primetagdesc",
                                multilanguage: true,
                                textalign: TextAlign.center,
                                fontsizeNormal: 12,
                                fontsizeWeb: 13,
                                fontweight: FontWeight.w500,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Rent TAG */
                  (videoDetailsProvider.sectionDetailModel.result?.isRent ??
                              0) ==
                          1
                      ? Container(
                          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: complimentryColor,
                                  borderRadius: BorderRadius.circular(10),
                                  shape: BoxShape.rectangle,
                                ),
                                alignment: Alignment.center,
                                child: MyText(
                                  color: white,
                                  text: Constant.currencySymbol,
                                  textalign: TextAlign.center,
                                  fontsizeNormal: 10,
                                  fontsizeWeb: 12,
                                  fontweight: FontWeight.w800,
                                  multilanguage: false,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 5),
                                child: MyText(
                                  color: white,
                                  text: "renttag",
                                  textalign: TextAlign.center,
                                  fontsizeNormal: 12,
                                  fontsizeWeb: 13,
                                  multilanguage: true,
                                  fontweight: FontWeight.w500,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Continue Watching Button */
                  /* Watch Now button */
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: (widget.videoType == 5)
                        ? _buildWatchTrailer()
                        : _buildWatchNow(),
                  ),

                  /* Included Features buttons */
                  if (widget.videoType != 5)
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: (kIsWeb || Constant.isTV)
                            ? (MediaQuery.of(context).size.width / 2)
                            : MediaQuery.of(context).size.width,
                        constraints: const BoxConstraints(minHeight: 0),
                        margin: const EdgeInsets.fromLTRB(20, 25, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /* Rent Button */
                            _buildRentBtn(),
                            const SizedBox(width: 5),

                            /* Start Over & Trailer */
                            Expanded(
                              child: Consumer<VideoDetailsProvider>(
                                builder:
                                    (context, videoDetailsProvider, child) {
                                  if ((videoDetailsProvider.sectionDetailModel
                                                  .result?.stopTime ??
                                              0) >
                                          0 &&
                                      videoDetailsProvider.sectionDetailModel
                                              .result?.videoDuration !=
                                          null) {
                                    /* Start Over */
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(5),
                                      focusColor: gray.withOpacity(0.5),
                                      onTap: () async {
                                        openPlayer("startOver");
                                      },
                                      child: _buildFeatureBtn(
                                        icon: 'ic_restart.png',
                                        title: 'startover',
                                        multilanguage: true,
                                      ),
                                    );
                                  } else {
                                    /* Trailer */
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(5),
                                      focusColor: gray.withOpacity(0.5),
                                      onTap: () {
                                        openPlayer("Trailer");
                                      },
                                      child: _buildFeatureBtn(
                                        icon: 'ic_borderplay.png',
                                        title: 'trailer',
                                        multilanguage: true,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),

                            /* Download */
                            if (!(kIsWeb || Constant.isTV))
                              (videoDetailsProvider.sectionDetailModel.result
                                              ?.download ??
                                          0) ==
                                      1
                                  ? _buildDownloadWithSubCheck()
                                  : const SizedBox.shrink(),

                            /* Watchlist */
                            Expanded(
                              child: InkWell(
                                focusColor: gray.withOpacity(0.5),
                                onTap: () async {
                                  log("isBookmark ====> ${videoDetailsProvider.sectionDetailModel.result?.isBookmark ?? 0}");
                                  if (Constant.userID != null) {
                                    await videoDetailsProvider.setBookMark(
                                      context,
                                      widget.typeId,
                                      widget.videoType,
                                      widget.videoId,
                                    );
                                  } else {
                                    if ((kIsWeb || Constant.isTV)) {
                                      Utils.buildWebAlertDialog(
                                          context, "login", "");
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return const LoginSocial();
                                        },
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(5),
                                child: Consumer<VideoDetailsProvider>(
                                  builder:
                                      (context, videoDetailsProvider, child) {
                                    if ((videoDetailsProvider.sectionDetailModel
                                                .result?.isBookmark ??
                                            0) ==
                                        1) {
                                      return _buildFeatureBtn(
                                        icon: 'watchlist_remove.png',
                                        title: 'watchlist',
                                        multilanguage: true,
                                      );
                                    } else {
                                      return _buildFeatureBtn(
                                        icon: 'ic_plus.png',
                                        title: 'watchlist',
                                        multilanguage: true,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),

                            /* More */
                            if (!(kIsWeb || Constant.isTV))
                              Expanded(
                                child: InkWell(
                                  focusColor: gray.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () {
                                    buildMoreDialog(videoDetailsProvider
                                            .sectionDetailModel
                                            .result
                                            ?.stopTime ??
                                        0);
                                  },
                                  child: _buildFeatureBtn(
                                    icon: 'ic_more.png',
                                    title: 'more',
                                    multilanguage: true,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  /* Description, IMDb, Languages & Subtitles */
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          constraints: const BoxConstraints(minHeight: 0),
                          alignment: Alignment.centerLeft,
                          child: ExpandableText(
                            videoDetailsProvider
                                    .sectionDetailModel.result?.description ??
                                "",
                            expandText: more,
                            collapseText: less_,
                            maxLines: (kIsWeb || Constant.isTV) ? 50 : 3,
                            linkColor: otherColor,
                            expandOnTextTap: true,
                            collapseOnTextTap: true,
                            style: TextStyle(
                              fontSize: (kIsWeb || Constant.isTV) ? 12 : 14,
                              fontStyle: FontStyle.normal,
                              color: otherColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            MyImage(
                              width: 50,
                              height: 23,
                              imagePath: "imdb.png",
                            ),
                            const SizedBox(width: 5),
                            MyText(
                              color: otherColor,
                              text:
                                  "${videoDetailsProvider.sectionDetailModel.result?.imdbRating ?? 0}",
                              textalign: TextAlign.start,
                              fontsizeNormal: 14,
                              fontsizeWeb: 16,
                              fontweight: FontWeight.w600,
                              multilanguage: false,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            ),
                          ],
                        ),
                        Container(
                          constraints: const BoxConstraints(minHeight: 0),
                          margin: const EdgeInsets.only(top: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                color: white,
                                text: "category",
                                textalign: TextAlign.center,
                                fontsizeNormal: 13,
                                fontweight: FontWeight.w500,
                                fontsizeWeb: 15,
                                maxline: 1,
                                multilanguage: true,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(width: 5),
                              MyText(
                                color: white,
                                text: ":",
                                textalign: TextAlign.center,
                                fontsizeNormal: 13,
                                fontweight: FontWeight.w500,
                                fontsizeWeb: 15,
                                maxline: 1,
                                multilanguage: false,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: MyText(
                                  color: white,
                                  text: videoDetailsProvider.sectionDetailModel
                                          .result?.categoryName ??
                                      "",
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 13,
                                  fontweight: FontWeight.w500,
                                  fontsizeWeb: 14,
                                  multilanguage: false,
                                  maxline: 5,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minHeight: 0),
                          margin: const EdgeInsets.only(top: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                color: white,
                                text: "language_",
                                textalign: TextAlign.center,
                                fontsizeNormal: 13,
                                fontweight: FontWeight.w500,
                                fontsizeWeb: 15,
                                maxline: 1,
                                multilanguage: true,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(width: 5),
                              MyText(
                                color: white,
                                text: ":",
                                textalign: TextAlign.center,
                                fontsizeNormal: 13,
                                fontweight: FontWeight.w500,
                                fontsizeWeb: 15,
                                maxline: 1,
                                multilanguage: false,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: MyText(
                                  color: white,
                                  text: audioLanguages ?? "",
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 13,
                                  fontweight: FontWeight.w500,
                                  fontsizeWeb: 14,
                                  multilanguage: false,
                                  maxline: 5,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Constant.subtitleUrls.isNotEmpty
                            ? Container(
                                constraints: const BoxConstraints(minHeight: 0),
                                margin: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    MyText(
                                      color: white,
                                      text: "subtitle",
                                      textalign: TextAlign.center,
                                      fontsizeNormal: 13,
                                      fontweight: FontWeight.w500,
                                      fontsizeWeb: 15,
                                      maxline: 1,
                                      multilanguage: true,
                                      overflow: TextOverflow.ellipsis,
                                      fontstyle: FontStyle.normal,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    MyText(
                                      color: white,
                                      text: ":",
                                      textalign: TextAlign.center,
                                      fontsizeNormal: 13,
                                      fontweight: FontWeight.w500,
                                      fontsizeWeb: 15,
                                      maxline: 1,
                                      multilanguage: false,
                                      overflow: TextOverflow.ellipsis,
                                      fontstyle: FontStyle.normal,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    MyText(
                                      color: white,
                                      text: "Available",
                                      textalign: TextAlign.center,
                                      fontsizeNormal: 13,
                                      fontweight: FontWeight.w500,
                                      fontsizeWeb: 14,
                                      maxline: 1,
                                      multilanguage: false,
                                      overflow: TextOverflow.ellipsis,
                                      fontstyle: FontStyle.normal,
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),

                  /* Related ~ More Details */
                  Container(
                    margin: (kIsWeb || Constant.isTV)
                        ? const EdgeInsets.fromLTRB(20, 0, 20, 0)
                        : const EdgeInsets.all(0),
                    child: Consumer<VideoDetailsProvider>(
                      builder: (context, videoDetailsProvider, child) {
                        return _buildTabs();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  /* Web Footer */
                  (kIsWeb) ? const FooterWeb() : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseDate() {
    if (widget.videoType == 5) {
      if (videoDetailsProvider.sectionDetailModel.result?.releaseDate != null &&
          (videoDetailsProvider.sectionDetailModel.result?.releaseDate ?? "") !=
              "") {
        return Container(
          margin: EdgeInsets.fromLTRB(
              (kIsWeb || Constant.isTV) ? 0 : 20, 20, 20, 0),
          width: MediaQuery.of(context).size.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              MyText(
                color: white,
                text: "release_date",
                multilanguage: true,
                textalign: TextAlign.start,
                fontsizeNormal: 14,
                fontsizeWeb: 15,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(width: 5),
              MyText(
                color: white,
                text: ":",
                multilanguage: false,
                textalign: TextAlign.start,
                fontsizeNormal: 14,
                fontsizeWeb: 15,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: MyText(
                  color: complimentryColor,
                  text: DateFormat("dd MMM, yyyy").format(DateTime.parse(
                      videoDetailsProvider
                              .sectionDetailModel.result?.releaseDate ??
                          "")),
                  multilanguage: false,
                  textalign: TextAlign.start,
                  fontsizeNormal: 14,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w700,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  /* Trailer View */
  Widget setUpTrailerView() {
    if ((videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "") ==
        "youtube") {
      if (_trailerYoutubeController != null) {
        return _buildTrailerView(
            videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        return _buildMobilePoster();
      }
    } else {
      if (_trailerNormalController != null &&
          (_trailerNormalController?.value.isInitialized ?? false)) {
        return _buildTrailerView(
            videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        return _buildMobilePoster();
      }
    }
  }

  Widget _buildTrailerView(String trailerType) {
    if (trailerType == "youtube") {
      return Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width,
            height: (kIsWeb || Constant.isTV)
                ? Dimens.detailWebPoster
                : Dimens.detailPoster,
            child: YoutubePlayer(
              controller: _trailerYoutubeController!,
              enableFullScreenOnVerticalDrag: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width,
            height: (kIsWeb || Constant.isTV)
                ? Dimens.detailWebPoster
                : Dimens.detailPoster,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  transparentColor,
                  transparentColor,
                  appBgColor,
                ],
              ),
            ),
          ),
          if (!kIsWeb)
            Positioned(
              top: 15,
              left: 15,
              child: Utils.buildBackBtn(context),
            ),
        ],
      );
    } else {
      return Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width,
            height: (kIsWeb || Constant.isTV)
                ? Dimens.detailWebPoster
                : Dimens.detailPoster,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _trailerNormalController?.value.size.width,
                  height: _trailerNormalController?.value.size.height,
                  child: AspectRatio(
                    aspectRatio:
                        _trailerNormalController?.value.aspectRatio ?? 16 / 9,
                    child: VideoPlayer(_trailerNormalController!),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width,
            height: (kIsWeb || Constant.isTV)
                ? Dimens.detailWebPoster
                : Dimens.detailPoster,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  transparentColor,
                  transparentColor,
                  appBgColor,
                ],
              ),
            ),
          ),
          if (!kIsWeb)
            Positioned(
              top: 15,
              left: 15,
              child: Utils.buildBackBtn(context),
            ),
        ],
      );
    }
  }

  Widget _buildMobilePoster() {
    return Stack(
      alignment: Alignment.center,
      children: [
        /* Poster & Trailer player */
        Container(
          padding: const EdgeInsets.all(0),
          width: MediaQuery.of(context).size.width,
          height: (kIsWeb || Constant.isTV)
              ? Dimens.detailWebPoster
              : Dimens.detailPoster,
          child: MyNetworkImage(
            fit: BoxFit.fill,
            imageUrl: videoDetailsProvider
                        .sectionDetailModel.result?.landscape !=
                    ""
                ? (videoDetailsProvider.sectionDetailModel.result?.landscape ??
                    "")
                : (videoDetailsProvider.sectionDetailModel.result?.thumbnail ??
                    ""),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(0),
          width: MediaQuery.of(context).size.width,
          height: (kIsWeb || Constant.isTV)
              ? Dimens.detailWebPoster
              : Dimens.detailPoster,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [
                transparentColor,
                transparentColor,
                appBgColor,
              ],
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(30),
          focusColor: white,
          onTap: () {
            openPlayer("Trailer");
          },
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: MyImage(
              fit: BoxFit.fill,
              height: 60,
              width: 60,
              imagePath: "play_new.png",
            ),
          ),
        ),
        if (!kIsWeb)
          Positioned(
            top: 15,
            left: 15,
            child: Utils.buildBackBtn(context),
          ),
      ],
    );
  }

  Widget _buildWebData() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            /* Poster */
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Stack(
                alignment: AlignmentDirectional.centerEnd,
                children: [
                  /* Poster */
                  Container(
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width *
                        (Dimens.webBannerImgPr),
                    height: Dimens.detailWebPoster,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(0),
                          width: MediaQuery.of(context).size.width,
                          height: Dimens.detailWebPoster,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                appBgColor,
                                transparentColor,
                                transparentColor,
                                transparentColor,
                                transparentColor,
                                transparentColor,
                                appBgColor,
                              ],
                            ),
                          ),
                        ),
                        MyNetworkImage(
                          fit: BoxFit.fill,
                          imageUrl: videoDetailsProvider
                                      .sectionDetailModel.result?.landscape !=
                                  ""
                              ? (videoDetailsProvider
                                      .sectionDetailModel.result?.landscape ??
                                  "")
                              : (videoDetailsProvider
                                      .sectionDetailModel.result?.thumbnail ??
                                  ""),
                        ),
                        Container(
                          padding: const EdgeInsets.all(0),
                          width: MediaQuery.of(context).size.width,
                          height: Dimens.detailWebPoster,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                appBgColor,
                                transparentColor,
                                transparentColor,
                                appBgColor,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /* Gradient */
                  Container(
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width,
                    height: Dimens.detailWebPoster,
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          appBgColor,
                          appBgColor,
                          appBgColor,
                          appBgColor,
                          transparentColor,
                          transparentColor,
                          transparentColor,
                          transparentColor,
                        ],
                      ),
                    ),
                  ),

                  /* Details */
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: Dimens.detailWebPoster,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            height: MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /* Small Poster, Main title, ReleaseYear, Duration, Age Restriction, Video Quality */
                                Expanded(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    constraints:
                                        const BoxConstraints(minHeight: 0),
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        MyText(
                                          color: white,
                                          text: videoDetailsProvider
                                                  .sectionDetailModel
                                                  .result
                                                  ?.name ??
                                              "",
                                          textalign: TextAlign.start,
                                          fontsizeNormal: 24,
                                          fontsizeWeb: 24,
                                          fontweight: FontWeight.w800,
                                          maxline: 2,
                                          multilanguage: false,
                                          overflow: TextOverflow.ellipsis,
                                          fontstyle: FontStyle.normal,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            /* Category */
                                            (videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.categoryName !=
                                                        null &&
                                                    videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.categoryName !=
                                                        "")
                                                ? Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    child: MyText(
                                                      color: whiteLight,
                                                      text: videoDetailsProvider
                                                              .sectionDetailModel
                                                              .result
                                                              ?.categoryName ??
                                                          "",
                                                      textalign:
                                                          TextAlign.center,
                                                      fontsizeNormal: 13,
                                                      fontsizeWeb: 13,
                                                      fontweight:
                                                          FontWeight.w600,
                                                      multilanguage: false,
                                                      maxline: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),

                                            /* Release Year */
                                            (videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.releaseYear !=
                                                        null &&
                                                    videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.releaseYear !=
                                                        "")
                                                ? Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    child: MyText(
                                                      color: whiteLight,
                                                      text: videoDetailsProvider
                                                              .sectionDetailModel
                                                              .result
                                                              ?.releaseYear ??
                                                          "",
                                                      textalign:
                                                          TextAlign.center,
                                                      fontsizeNormal: 13,
                                                      fontsizeWeb: 13,
                                                      fontweight:
                                                          FontWeight.w500,
                                                      multilanguage: false,
                                                      maxline: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),

                                            /* Duration */
                                            (videoDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.videoDuration !=
                                                    null)
                                                ? Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    child: MyText(
                                                      color: otherColor,
                                                      multilanguage: false,
                                                      text: ((videoDetailsProvider
                                                                      .sectionDetailModel
                                                                      .result
                                                                      ?.videoDuration ??
                                                                  0) >
                                                              0)
                                                          ? Utils.convertTimeToText(
                                                              videoDetailsProvider
                                                                      .sectionDetailModel
                                                                      .result
                                                                      ?.videoDuration ??
                                                                  0)
                                                          : "",
                                                      textalign:
                                                          TextAlign.center,
                                                      fontsizeNormal: 13,
                                                      fontsizeWeb: 13,
                                                      fontweight:
                                                          FontWeight.w500,
                                                      maxline: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),

                                            /* MaxQuality */
                                            (videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.maxVideoQuality !=
                                                        null &&
                                                    videoDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.maxVideoQuality !=
                                                        "")
                                                ? Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    padding: const EdgeInsets
                                                        .fromLTRB(5, 1, 5, 1),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: otherColor,
                                                        width: .7,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      shape: BoxShape.rectangle,
                                                    ),
                                                    child: MyText(
                                                      color: otherColor,
                                                      text: videoDetailsProvider
                                                              .sectionDetailModel
                                                              .result
                                                              ?.maxVideoQuality ??
                                                          "",
                                                      textalign:
                                                          TextAlign.center,
                                                      fontsizeNormal: 10,
                                                      fontsizeWeb: 12,
                                                      fontweight:
                                                          FontWeight.w500,
                                                      multilanguage: false,
                                                      maxline: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),

                                            /* IMDb */
                                            MyImage(
                                              width: 40,
                                              height: 15,
                                              imagePath: "imdb.png",
                                            ),
                                            MyText(
                                              color: otherColor,
                                              text:
                                                  "${videoDetailsProvider.sectionDetailModel.result?.imdbRating ?? 0}",
                                              textalign: TextAlign.start,
                                              fontsizeNormal: 14,
                                              fontsizeWeb: 14,
                                              fontweight: FontWeight.w600,
                                              multilanguage: false,
                                              maxline: 1,
                                              overflow: TextOverflow.ellipsis,
                                              fontstyle: FontStyle.normal,
                                            ),
                                            /* IMDb */
                                          ],
                                        ),

                                        /* Language */
                                        const SizedBox(height: 5),
                                        Container(
                                          constraints: const BoxConstraints(
                                              minHeight: 0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              MyText(
                                                color: whiteLight,
                                                text: "language_",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 13,
                                                fontweight: FontWeight.w500,
                                                fontsizeWeb: 13,
                                                maxline: 1,
                                                multilanguage: true,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal,
                                              ),
                                              const SizedBox(width: 5),
                                              MyText(
                                                color: whiteLight,
                                                text: ":",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 13,
                                                fontweight: FontWeight.w600,
                                                fontsizeWeb: 13,
                                                maxline: 1,
                                                multilanguage: false,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: MyText(
                                                  color: whiteLight,
                                                  text: audioLanguages ?? "",
                                                  textalign: TextAlign.start,
                                                  fontsizeNormal: 13,
                                                  fontweight: FontWeight.w500,
                                                  fontsizeWeb: 13,
                                                  multilanguage: false,
                                                  maxline: 5,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontstyle: FontStyle.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /* Subtitle */
                                        Constant.subtitleUrls.isNotEmpty
                                            ? Container(
                                                constraints:
                                                    const BoxConstraints(
                                                        minHeight: 0),
                                                margin: const EdgeInsets.only(
                                                    top: 8),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    MyText(
                                                      color: whiteLight,
                                                      text: "subtitle",
                                                      textalign:
                                                          TextAlign.center,
                                                      fontsizeNormal: 13,
                                                      fontweight:
                                                          FontWeight.w500,
                                                      fontsizeWeb: 13,
                                                      maxline: 1,
                                                      multilanguage: true,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    MyText(
                                                      color: whiteLight,
                                                      text: ":",
                                                      textalign:
                                                          TextAlign.center,
                                                      fontsizeNormal: 13,
                                                      fontweight:
                                                          FontWeight.w600,
                                                      fontsizeWeb: 13,
                                                      maxline: 1,
                                                      multilanguage: false,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      child: MyText(
                                                        color: whiteLight,
                                                        text: "Available",
                                                        textalign:
                                                            TextAlign.start,
                                                        fontsizeNormal: 13,
                                                        fontweight:
                                                            FontWeight.w500,
                                                        fontsizeWeb: 13,
                                                        maxline: 1,
                                                        multilanguage: false,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontstyle:
                                                            FontStyle.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink(),

                                        /* Release Date */
                                        _buildReleaseDate(),

                                        /* Prime TAG */
                                        (videoDetailsProvider.sectionDetailModel
                                                        .result?.isPremium ??
                                                    0) ==
                                                1
                                            ? Container(
                                                margin: const EdgeInsets.only(
                                                    top: 10),
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    MyText(
                                                      color: primaryColor,
                                                      text: "primetag",
                                                      textalign:
                                                          TextAlign.start,
                                                      fontsizeNormal: 12,
                                                      fontsizeWeb: 12,
                                                      fontweight:
                                                          FontWeight.w700,
                                                      multilanguage: true,
                                                      maxline: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    MyText(
                                                      color: white,
                                                      text: "primetagdesc",
                                                      multilanguage: true,
                                                      textalign:
                                                          TextAlign.center,
                                                      fontsizeNormal: 12,
                                                      fontsizeWeb: 12,
                                                      fontweight:
                                                          FontWeight.w400,
                                                      maxline: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontstyle:
                                                          FontStyle.normal,
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink(),

                                        /* Rent TAG */
                                        (videoDetailsProvider.sectionDetailModel
                                                        .result?.isRent ??
                                                    0) ==
                                                1
                                            ? Container(
                                                margin: const EdgeInsets.only(
                                                    top: 10, bottom: 10),
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Container(
                                                      width: 18,
                                                      height: 18,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            complimentryColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        shape:
                                                            BoxShape.rectangle,
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: MyText(
                                                        color: white,
                                                        text: Constant
                                                            .currencySymbol,
                                                        textalign:
                                                            TextAlign.center,
                                                        fontsizeNormal: 11,
                                                        fontsizeWeb: 11,
                                                        fontweight:
                                                            FontWeight.w700,
                                                        multilanguage: false,
                                                        maxline: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontstyle:
                                                            FontStyle.normal,
                                                      ),
                                                    ),
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 5),
                                                      child: MyText(
                                                        color: white,
                                                        text: "renttag",
                                                        textalign:
                                                            TextAlign.center,
                                                        fontsizeNormal: 12,
                                                        fontsizeWeb: 13,
                                                        multilanguage: true,
                                                        fontweight:
                                                            FontWeight.w500,
                                                        maxline: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontstyle:
                                                            FontStyle.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink(),

                                        /* Description */
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              margin: const EdgeInsets.only(
                                                  top: 15, bottom: 8),
                                              child: ExpandableText(
                                                videoDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.description ??
                                                    "",
                                                animation: true,
                                                textAlign: TextAlign.start,
                                                expandOnTextTap: true,
                                                collapseOnTextTap: true,
                                                expandText: "",
                                                maxLines: 10,
                                                linkColor: primaryColor,
                                                style: TextStyle(
                                                  fontSize:
                                                      (kIsWeb || Constant.isTV)
                                                          ? 12
                                                          : 13,
                                                  fontStyle: FontStyle.normal,
                                                  color: white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width *
                              Dimens.webBannerImgPr,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /* WatchNow & Feature buttons */
            Container(
              alignment: Alignment.centerLeft,
              constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
              margin: const EdgeInsets.fromLTRB(30, 10, 0, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /* WatchNow & ContinueWatching */
                  (widget.videoType == 5)
                      ? _buildWatchTrailer()
                      : _buildWatchNow(),
                  if (widget.videoType != 5) const SizedBox(width: 10),

                  /* Rent Button */
                  if (widget.videoType != 5)
                    Container(
                      constraints: const BoxConstraints(minWidth: 0),
                      child: _buildRentBtn(),
                    ),
                  if (widget.videoType != 5) const SizedBox(width: 10),

                  /* Trailer & StartOver Button */
                  if (widget.videoType != 5)
                    Container(
                      constraints: const BoxConstraints(minWidth: 50),
                      child: Consumer<VideoDetailsProvider>(
                        builder: (context, videoDetailsProvider, child) {
                          if ((videoDetailsProvider.sectionDetailModel.result
                                          ?.stopTime ??
                                      0) >
                                  0 &&
                              videoDetailsProvider.sectionDetailModel.result
                                      ?.videoDuration !=
                                  null) {
                            /* Start Over */
                            return InkWell(
                              focusColor: gray.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(5),
                              onTap: () async {
                                openPlayer("startOver");
                              },
                              child: _buildFeatureBtn(
                                icon: 'ic_restart.png',
                                title: 'startover',
                                multilanguage: true,
                              ),
                            );
                          } else {
                            /* Trailer */
                            return InkWell(
                              focusColor: gray.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(5),
                              onTap: () {
                                openPlayer("Trailer");
                              },
                              child: _buildFeatureBtn(
                                icon: 'ic_borderplay.png',
                                title: 'trailer',
                                multilanguage: true,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  if (widget.videoType != 5) const SizedBox(width: 10),

                  /* Watchlist */
                  if (widget.videoType != 5)
                    Container(
                      constraints: const BoxConstraints(minWidth: 50),
                      child: InkWell(
                        focusColor: gray.withOpacity(0.5),
                        onTap: () async {
                          log("isBookmark ====> ${videoDetailsProvider.sectionDetailModel.result?.isBookmark ?? 0}");
                          if (Constant.userID != null) {
                            await videoDetailsProvider.setBookMark(
                              context,
                              widget.typeId,
                              widget.videoType,
                              widget.videoId,
                            );
                          } else {
                            if ((kIsWeb || Constant.isTV)) {
                              Utils.buildWebAlertDialog(context, "login", "")
                                  .then((value) => _getData());
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const LoginSocial();
                                },
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(5),
                        child: Consumer<VideoDetailsProvider>(
                          builder: (context, videoDetailsProvider, child) {
                            if ((videoDetailsProvider.sectionDetailModel.result
                                        ?.isBookmark ??
                                    0) ==
                                1) {
                              return _buildFeatureBtn(
                                icon: 'watchlist_remove.png',
                                title: 'watchlist',
                                multilanguage: true,
                              );
                            } else {
                              return _buildFeatureBtn(
                                icon: 'ic_plus.png',
                                title: 'watchlist',
                                multilanguage: true,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /* Other Details */
            /* Related ~ More Details */
            Container(
              margin: (kIsWeb || Constant.isTV)
                  ? const EdgeInsets.fromLTRB(10, 10, 20, 0)
                  : const EdgeInsets.all(0),
              child: Consumer<VideoDetailsProvider>(
                builder: (context, videoDetailsProvider, child) {
                  return _buildTabs();
                },
              ),
            ),
            const SizedBox(height: 20),

            /* Web Footer */
            (kIsWeb) ? const FooterWeb() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  double getDynamicHeight(String? videoType, String? layoutType) {
    if (videoType == "1" || videoType == "2") {
      if (layoutType == "landscape") {
        return Dimens.heightLand;
      } else if (layoutType == "potrait") {
        return Dimens.heightPort;
      } else if (layoutType == "square") {
        return Dimens.heightSquare;
      } else {
        return Dimens.heightLand;
      }
    } else if (videoType == "3" || videoType == "4") {
      return Dimens.heightLangGen;
    } else {
      if (layoutType == "landscape") {
        return Dimens.heightLand;
      } else if (layoutType == "potrait") {
        return Dimens.heightPort;
      } else if (layoutType == "square") {
        return Dimens.heightSquare;
      } else {
        return Dimens.heightLand;
      }
    }
  }

  Widget _buildWatchTrailer() {
    return Container(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {
          openPlayer("Trailer");
        },
        focusColor: white,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            height: (kIsWeb || Constant.isTV) ? 40 : 55,
            constraints: BoxConstraints(
              maxWidth: (kIsWeb || Constant.isTV)
                  ? 180
                  : MediaQuery.of(context).size.width,
            ),
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            decoration: BoxDecoration(
              color: primaryDark,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MyImage(
                  width: 18,
                  height: 18,
                  imagePath: "ic_play.png",
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: MyText(
                    color: white,
                    text: "watch_trailer",
                    multilanguage: true,
                    textalign: TextAlign.start,
                    fontsizeNormal: 15,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 16,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchNow() {
    if ((videoDetailsProvider.sectionDetailModel.result?.stopTime ?? 0) > 0 &&
        videoDetailsProvider.sectionDetailModel.result?.videoDuration != null) {
      return Container(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () async {
            openPlayer("Video");
          },
          focusColor: white,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: (kIsWeb || Constant.isTV) ? 40 : 55,
              constraints: BoxConstraints(
                maxWidth: (kIsWeb || Constant.isTV)
                    ? 190
                    : MediaQuery.of(context).size.width,
              ),
              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20),
                        MyImage(
                          width: 18,
                          height: 18,
                          imagePath: "ic_play.png",
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              MyText(
                                color: white,
                                text: "continuewatching",
                                multilanguage: true,
                                textalign: TextAlign.start,
                                fontsizeNormal: 13,
                                fontsizeWeb: 15,
                                fontweight: FontWeight.w600,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              Row(
                                children: [
                                  MyText(
                                    color: white,
                                    text: Utils.remainTimeInMin(
                                        ((videoDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.videoDuration ??
                                                    0) -
                                                (videoDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.stopTime ??
                                                    0))
                                            .abs()),
                                    textalign: TextAlign.start,
                                    fontsizeNormal: 10,
                                    fontweight: FontWeight.w500,
                                    fontsizeWeb: 12,
                                    multilanguage: false,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                  const SizedBox(width: 5),
                                  MyText(
                                    color: white,
                                    text: "left",
                                    textalign: TextAlign.start,
                                    fontsizeNormal: 10,
                                    fontweight: FontWeight.w500,
                                    fontsizeWeb: 12,
                                    multilanguage: true,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  Container(
                    height: 4,
                    constraints: const BoxConstraints(minWidth: 0),
                    margin: const EdgeInsets.all(3),
                    child: LinearPercentIndicator(
                      padding: const EdgeInsets.all(0),
                      barRadius: const Radius.circular(2),
                      lineHeight: 4,
                      percent: Utils.getPercentage(
                          videoDetailsProvider
                                  .sectionDetailModel.result?.videoDuration ??
                              0,
                          videoDetailsProvider
                                  .sectionDetailModel.result?.stopTime ??
                              0),
                      backgroundColor: secProgressColor,
                      progressColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () {
            openPlayer("Video");
          },
          focusColor: white,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: (kIsWeb || Constant.isTV) ? 40 : 55,
              constraints: BoxConstraints(
                maxWidth: (kIsWeb || Constant.isTV)
                    ? 180
                    : MediaQuery.of(context).size.width,
              ),
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MyImage(
                    width: 18,
                    height: 18,
                    imagePath: "ic_play.png",
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: MyText(
                      color: white,
                      text: "watch_now",
                      multilanguage: true,
                      textalign: TextAlign.start,
                      fontsizeNormal: 15,
                      fontweight: FontWeight.w600,
                      fontsizeWeb: 16,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildRentBtn() {
    if ((videoDetailsProvider.sectionDetailModel.result?.isPremium ?? 0) == 1 &&
        (videoDetailsProvider.sectionDetailModel.result?.isRent ?? 0) == 1) {
      if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (videoDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
        return const SizedBox.shrink();
      } else {
        return Expanded(
          child: InkWell(
            focusColor: white,
            borderRadius: BorderRadius.circular(5),
            onTap: () async {
              if (Constant.userID != null) {
                dynamic isRented = await Utils.paymentForRent(
                  context: context,
                  videoId: videoDetailsProvider.sectionDetailModel.result?.id
                          .toString() ??
                      '',
                  rentPrice: videoDetailsProvider
                          .sectionDetailModel.result?.rentPrice
                          .toString() ??
                      '',
                  vTitle: videoDetailsProvider.sectionDetailModel.result?.name
                          .toString() ??
                      '',
                  typeId: videoDetailsProvider.sectionDetailModel.result?.typeId
                          .toString() ??
                      '',
                  vType: videoDetailsProvider
                          .sectionDetailModel.result?.videoType
                          .toString() ??
                      '',
                );
                if (isRented != null && isRented == true) {
                  _getData();
                }
              } else {
                if ((kIsWeb || Constant.isTV)) {
                  Utils.buildWebAlertDialog(context, "login", "")
                      .then((value) => _getData());
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const LoginSocial();
                    },
                  ),
                );
              }
            },
            child: _buildFeatureBtn(
              icon: 'ic_store.png',
              title:
                  "Rent at just\n${Constant.currencySymbol}${videoDetailsProvider.sectionDetailModel.result?.rentPrice ?? 0}",
              multilanguage: false,
            ),
          ),
        );
      }
    } else if ((videoDetailsProvider.sectionDetailModel.result?.isRent ?? 0) ==
        1) {
      if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (videoDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
        return const SizedBox.shrink();
      } else {
        return Expanded(
          child: InkWell(
            focusColor: white,
            borderRadius: BorderRadius.circular(5),
            onTap: () async {
              if (Constant.userID != null) {
                dynamic isRented = await Utils.paymentForRent(
                  context: context,
                  videoId: videoDetailsProvider.sectionDetailModel.result?.id
                          .toString() ??
                      '',
                  rentPrice: videoDetailsProvider
                          .sectionDetailModel.result?.rentPrice
                          .toString() ??
                      '',
                  vTitle: videoDetailsProvider.sectionDetailModel.result?.name
                          .toString() ??
                      '',
                  typeId: videoDetailsProvider.sectionDetailModel.result?.typeId
                          .toString() ??
                      '',
                  vType: videoDetailsProvider
                          .sectionDetailModel.result?.videoType
                          .toString() ??
                      '',
                );
                if (isRented != null && isRented == true) {
                  _getData();
                }
              } else {
                if ((kIsWeb || Constant.isTV)) {
                  Utils.buildWebAlertDialog(context, "login", "")
                      .then((value) => _getData());
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const LoginSocial();
                    },
                  ),
                );
              }
            },
            child: _buildFeatureBtn(
              icon: 'ic_store.png',
              title:
                  "Rent at just\n${Constant.currencySymbol}${videoDetailsProvider.sectionDetailModel.result?.rentPrice ?? 0}",
              multilanguage: false,
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTabs() {
    return Column(
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: (kIsWeb || Constant.isTV)
                ? (MediaQuery.of(context).size.width * 0.5)
                : MediaQuery.of(context).size.width,
          ),
          height: (kIsWeb || Constant.isTV) ? 35 : Dimens.detailTabs,
          child: Row(
            children: [
              /* Related */
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(5),
                  focusColor: Colors.grey.withOpacity(0.5),
                  onTap: () async {
                    await videoDetailsProvider.setTabClick("related");
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: MyText(
                              color:
                                  videoDetailsProvider.tabClickedOn != "related"
                                      ? otherColor
                                      : white,
                              text: "related",
                              multilanguage: true,
                              textalign: TextAlign.center,
                              fontsizeNormal: 16,
                              fontweight: FontWeight.w600,
                              fontsizeWeb: 16,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        Visibility(
                          visible:
                              videoDetailsProvider.tabClickedOn == "related",
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 2,
                            color: white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              /* More Details */
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(5),
                  focusColor: Colors.grey.withOpacity(0.5),
                  onTap: () async {
                    await videoDetailsProvider.setTabClick("moredetails");
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: MyText(
                              color: videoDetailsProvider.tabClickedOn !=
                                      "moredetails"
                                  ? otherColor
                                  : white,
                              text: "moredetails",
                              textalign: TextAlign.center,
                              fontsizeNormal: 16,
                              fontweight: FontWeight.w600,
                              fontsizeWeb: 16,
                              multilanguage: true,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: videoDetailsProvider.tabClickedOn ==
                              "moredetails",
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 2,
                            color: white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 0.5,
          color: otherColor,
          constraints: BoxConstraints(
            maxWidth: (kIsWeb || Constant.isTV)
                ? (MediaQuery.of(context).size.width * 0.5)
                : MediaQuery.of(context).size.width,
          ),
        ),
        /* Data */
        if (videoDetailsProvider.tabClickedOn == "related")
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* Customers also watched */
              RelatedVideoShow(
                relatedDataList:
                    videoDetailsProvider.sectionDetailModel.getRelatedVideo,
              ),
              /* Cast & Crew */
              CastCrew(castList: videoDetailsProvider.sectionDetailModel.cast),
              /* Director */
              _buildDirector(),
            ],
          )
        else
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: MoreDetails(
                moreDetailList:
                    videoDetailsProvider.sectionDetailModel.moreDetails),
          )
      ],
    );
  }

  Widget _buildDirector() {
    if (directorList != null && (directorList?.length ?? 0) > 0) {
      return Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
            minHeight: (kIsWeb || Constant.isTV)
                ? Dimens.heightCastWeb
                : Dimens.heightCast),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(Dimens.cardRadius),
              focusColor: white,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CastDetails(
                        castID: directorList?[0].id.toString() ?? ""),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.antiAlias,
                  children: <Widget>[
                    SizedBox(
                      height: (kIsWeb || Constant.isTV)
                          ? Dimens.heightCastWeb
                          : Dimens.heightCast,
                      width: (kIsWeb || Constant.isTV)
                          ? Dimens.widthCastWeb
                          : Dimens.widthCast,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimens.cardRadius),
                        child: MyUserNetworkImage(
                          imageUrl: directorList?[0].image ?? "",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(0),
                      height: (kIsWeb || Constant.isTV)
                          ? Dimens.heightCastWeb
                          : Dimens.heightCast,
                      width: (kIsWeb || Constant.isTV)
                          ? Dimens.widthCastWeb
                          : Dimens.widthCast,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            transparentColor,
                            blackTransparent,
                            black,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: (kIsWeb || Constant.isTV)
                          ? Dimens.widthCastWeb
                          : Dimens.widthCast,
                      padding: const EdgeInsets.all(5),
                      child: MyText(
                        multilanguage: false,
                        text: directorList?[0].name ?? "",
                        fontstyle: FontStyle.normal,
                        fontsizeNormal: 12,
                        fontweight: FontWeight.w500,
                        fontsizeWeb: 13,
                        maxline: 3,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.center,
                        color: white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  MyText(
                    color: white,
                    text: "directors",
                    multilanguage: true,
                    textalign: TextAlign.start,
                    fontsizeNormal: 13,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 15,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 6),
                  MyText(
                    color: otherColor,
                    text: directorList?[0].personalInfo ?? "",
                    textalign: TextAlign.start,
                    multilanguage: false,
                    fontsizeNormal: 12,
                    fontweight: FontWeight.w500,
                    fontsizeWeb: 14,
                    maxline: 7,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFeatureBtn({
    required String title,
    required String icon,
    required bool multilanguage,
  }) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ((kIsWeb || Constant.isTV))
                ? Dimens.featureWebSize
                : Dimens.featureSize,
            height: ((kIsWeb || Constant.isTV))
                ? Dimens.featureWebSize
                : Dimens.featureSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryLight,
              ),
              borderRadius: BorderRadius.circular((((kIsWeb || Constant.isTV))
                      ? Dimens.featureWebSize
                      : Dimens.featureSize) /
                  2),
            ),
            child: MyImage(
              width: ((kIsWeb || Constant.isTV))
                  ? Dimens.featureIconWebSize
                  : Dimens.featureIconSize,
              height: ((kIsWeb || Constant.isTV))
                  ? Dimens.featureIconWebSize
                  : Dimens.featureIconSize,
              color: lightGray,
              imagePath: icon,
            ),
          ),
          const SizedBox(height: 5),
          MyText(
            color: white,
            text: title,
            multilanguage: multilanguage,
            fontsizeNormal: 10,
            fontsizeWeb: 14,
            fontweight: FontWeight.w600,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  /* ========= Download ========= */
  Widget _buildDownloadWithSubCheck() {
    if ((videoDetailsProvider.sectionDetailModel.result?.isPremium ?? 0) == 1) {
      if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (videoDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
        return _buildDownloadBtn();
      } else {
        return const SizedBox.shrink();
      }
    } else if ((videoDetailsProvider.sectionDetailModel.result?.isRent ?? 0) ==
        1) {
      if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (videoDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
        return _buildDownloadBtn();
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return _buildDownloadBtn();
    }
  }

  Widget _buildDownloadBtn() {
    if (videoDetailsProvider.sectionDetailModel.result?.videoUploadType ==
            "server_video" ||
        videoDetailsProvider.sectionDetailModel.result?.videoUploadType ==
            "external") {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          focusColor: gray.withOpacity(0.5),
          onTap: () {
            if (Constant.userID != null) {
              if (videoDetailsProvider
                      .sectionDetailModel.result?.isDownloaded ==
                  0) {
                if (downloadProvider.dProgress == 0) {
                  _checkAndDownload();
                } else {
                  Utils.showSnackbar(context, "info", "please_wait", true);
                }
              } else {
                buildDownloadCompleteDialog();
              }
            } else {
              if ((kIsWeb || Constant.isTV)) {
                Utils.buildWebAlertDialog(context, "login", "")
                    .then((value) => _getData());
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const LoginSocial();
                  },
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer2<VideoDetailsProvider, VideoDownloadProvider>(
                  builder:
                      (context, videoDetailsProvider, downloadProvider, child) {
                    if (downloadProvider.currentTasks != null &&
                        downloadProvider.currentTasks?[0].id ==
                            videoDetailsProvider
                                .sectionDetailModel.result?.id &&
                        downloadProvider.dProgress != 0 &&
                        downloadProvider.dProgress > 0) {
                      return CircularPercentIndicator(
                        radius: (Dimens.featureSize / 2),
                        lineWidth: 2.0,
                        percent: (downloadProvider.dProgress / 100).toDouble(),
                        center: MyText(
                          color: white,
                          text: "${downloadProvider.dProgress}%",
                          multilanguage: false,
                          fontsizeNormal: 10,
                          fontweight: FontWeight.w600,
                          fontsizeWeb: 14,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                        progressColor: primaryColor,
                      );
                    } else {
                      return Container(
                        width: Dimens.featureSize,
                        height: Dimens.featureSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryLight),
                          borderRadius:
                              BorderRadius.circular(Dimens.featureSize / 2),
                        ),
                        child: MyImage(
                          width: Dimens.featureIconSize,
                          height: Dimens.featureIconSize,
                          color: lightGray,
                          imagePath: (videoDetailsProvider.sectionDetailModel
                                      .result?.isDownloaded ==
                                  1)
                              ? "ic_download_done.png"
                              : "ic_download.png",
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 5),
                Consumer<VideoDetailsProvider>(
                  builder: (context, videoDetailsProvider, child) {
                    return MyText(
                      color: white,
                      text: (videoDetailsProvider
                                  .sectionDetailModel.result?.isDownloaded ==
                              1)
                          ? "complete"
                          : "download",
                      multilanguage: true,
                      fontsizeNormal: 10,
                      fontweight: FontWeight.w600,
                      fontsizeWeb: 14,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  _checkAndDownload() async {
    // _permissionReady = await Utils.checkPermission();
    // log("_permissionReady ====> $_permissionReady");
    // if (_permissionReady) {
    if (videoDetailsProvider.sectionDetailModel.result?.isDownloaded == 0) {
      if ((videoDetailsProvider.sectionDetailModel.result?.video320 ?? "")
          .isNotEmpty) {
        File? mTargetFile;
        String? localPath;
        String? mFileName =
            '${(videoDetailsProvider.sectionDetailModel.result?.name ?? "").replaceAll(" ", "")}'
            '${(videoDetailsProvider.sectionDetailModel.result?.id ?? 0)}${(Constant.userID)}';
        try {
          localPath = await Utils.prepareSaveDir();
          log("localPath ====> $localPath");
          mTargetFile = File(path.join(localPath,
              '$mFileName.${(videoDetailsProvider.sectionDetailModel.result?.videoExtension ?? "mp4")}'));
          // This is a sync operation on a real
          // app you'd probably prefer to use writeAsByte and handle its Future
        } catch (e) {
          debugPrint("saveVideoStorage Exception ===> $e");
        }
        log("mFileName ========> $mFileName");
        log("mTargetFile ========> ${mTargetFile?.absolute.path ?? ""}");
        if (mTargetFile != null) {
          try {
            downloadProvider.prepareDownload(
                videoDetailsProvider.sectionDetailModel.result,
                localPath,
                mFileName);
            log("mTargetFile length ========> ${mTargetFile.length()}");
          } catch (e) {
            log("Downloading... Exception ======> $e");
          }
        }
      } else {
        if (!mounted) return;
        Utils.showSnackbar(context, "fail", "invalid_url", true);
      }
    }
    // }
  }

  buildDownloadCompleteDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MyText(
                    text: "download_options",
                    multilanguage: true,
                    fontsizeNormal: 16,
                    color: white,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w700,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 5),
                  MyText(
                    text: "download_options_note",
                    multilanguage: true,
                    fontsizeNormal: 10,
                    color: otherColor,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w500,
                    maxline: 5,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),

                  /* To Download */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () async {
                      Navigator.pop(context);
                      if (Constant.userID != null) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MyDownloads(),
                          ),
                        );
                        setState(() {});
                      } else {
                        if ((kIsWeb || Constant.isTV)) {
                          Utils.buildWebAlertDialog(context, "login", "")
                              .then((value) => _getData());
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginSocial(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_setting.png",
                            fit: BoxFit.fill,
                            color: lightGray,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "take_me_to_the_downloads_page",
                              multilanguage: true,
                              fontsizeNormal: 14,
                              color: white,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w600,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* Delete */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () async {
                      Navigator.pop(context);
                      await videoDetailsProvider.setDownloadComplete(
                          context,
                          videoDetailsProvider.sectionDetailModel.result?.id,
                          videoDetailsProvider
                              .sectionDetailModel.result?.videoType,
                          videoDetailsProvider
                              .sectionDetailModel.result?.typeId);
                      await downloadProvider.deleteVideoFromDownload(
                          videoDetailsProvider.sectionDetailModel.result?.id
                                  .toString() ??
                              "");
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_delete.png",
                            fit: BoxFit.fill,
                            color: lightGray,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "delete_download",
                              multilanguage: true,
                              fontsizeNormal: 14,
                              color: white,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w600,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  /* ========= Download ========= */

  /* ========= Dialogs ========= */
  buildLangSubtitleDialog(List<Language>? languageList) {
    log("languageList Size ===> ${languageList?.length ?? 0}");
    String? audioLanguages;
    if ((languageList?.length ?? 0) > 0) {
      for (int i = 0; i < (languageList?.length ?? 0); i++) {
        if (i == 0) {
          audioLanguages = languageList?[i].name ?? "";
        } else {
          audioLanguages = "$audioLanguages, ${languageList?[i].name ?? ""}";
        }
      }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MyText(
                    text: "avalablelanguage",
                    fontsizeNormal: 17,
                    fontweight: FontWeight.w700,
                    fontsizeWeb: 18,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    color: white,
                  ),
                  const SizedBox(height: 5),
                  MyText(
                    text: "languagechangenote",
                    fontsizeNormal: 13,
                    fontweight: FontWeight.w500,
                    fontsizeWeb: 14,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    color: otherColor,
                  ),
                  const SizedBox(height: 10),
                  MyText(
                    text: "audios",
                    fontsizeNormal: 17,
                    fontweight: FontWeight.w500,
                    fontsizeWeb: 18,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    color: white,
                  ),
                  const SizedBox(height: 2),
                  MyText(
                    text: audioLanguages ?? "-",
                    fontsizeNormal: 13,
                    fontweight: FontWeight.w500,
                    fontsizeWeb: 14,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    color: otherColor,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 0.7,
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                    color: otherColor,
                  ),
                  MyText(
                    text: "subtitle",
                    fontsizeNormal: 17,
                    fontweight: FontWeight.w700,
                    fontsizeWeb: 16,
                    multilanguage: true,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    color: white,
                  ),
                  const SizedBox(height: 2),
                  MyText(
                    text: Constant.subtitleUrls.isNotEmpty ? "Available" : "-",
                    fontsizeNormal: 16,
                    fontweight: FontWeight.w500,
                    fontsizeWeb: 17,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    color: otherColor,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  buildMoreDialog(stopTime) {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /* Share */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () {
                      Navigator.pop(context);
                      buildShareWithDialog();
                    },
                    child: _buildDialogItems(
                      icon: "ic_share.png",
                      title: "share",
                      isMultilang: true,
                    ),
                  ),

                  /* Trailer */
                  stopTime > 0
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          focusColor: white,
                          onTap: () {
                            Navigator.pop(context);
                            openPlayer("Trailer");
                          },
                          child: _buildDialogItems(
                            icon: "ic_borderplay.png",
                            title: "trailer",
                            isMultilang: true,
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  buildShareWithDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MyText(
                    text:
                        videoDetailsProvider.sectionDetailModel.result?.name ??
                            "",
                    multilanguage: false,
                    fontsizeNormal: 18,
                    fontsizeWeb: 18,
                    color: white,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w700,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      (videoDetailsProvider.sectionDetailModel.result
                                      ?.ageRestriction ??
                                  "")
                              .isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: Utils.setBGWithBorder(
                                  transparentColor, otherColor, 3, 0.7),
                              child: MyText(
                                text: videoDetailsProvider.sectionDetailModel
                                        .result?.ageRestriction ??
                                    "",
                                multilanguage: false,
                                fontsizeNormal: 10,
                                fontsizeWeb: 12,
                                color: otherColor,
                                fontstyle: FontStyle.normal,
                                fontweight: FontWeight.w500,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.start,
                              ),
                            )
                          : const SizedBox.shrink(),
                      MyImage(
                        width: 18,
                        height: 18,
                        imagePath: "ic_comment.png",
                        fit: BoxFit.fill,
                        color: lightGray,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /* SMS */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () {
                      Navigator.pop(context);
                      if (Platform.isAndroid) {
                        Utils.redirectToUrl(
                            'sms:?body=${Uri.encodeComponent("Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n")}');
                      } else if (Platform.isIOS) {
                        Utils.redirectToUrl(
                            'sms:&body=${Uri.encodeComponent("Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n")}');
                      }
                    },
                    child: _buildDialogItems(
                      icon: "ic_sms.png",
                      title: "sms",
                      isMultilang: true,
                    ),
                  ),

                  /* Instgram Stories */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () {
                      Navigator.pop(context);
                      Utils.shareApp(Platform.isIOS
                          ? "Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
                    },
                    child: _buildDialogItems(
                      icon: "ic_insta.png",
                      title: "instagram_stories",
                      isMultilang: true,
                    ),
                  ),

                  /* Copy Link */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () {
                      Navigator.pop(context);

                      // SocialShare.copyToClipboard(
                      //   text: Platform.isIOS
                      //       ? "Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                      //       : "Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n",
                      // ).then((data) {
                      //   debugPrint(data);
                      //   Utils.showSnackbar(
                      //       context, "success", "link_copied", true);
                      // });
                    },
                    child: _buildDialogItems(
                      icon: "ic_link.png",
                      title: "copy_link",
                      isMultilang: true,
                    ),
                  ),

                  /* More */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: white,
                    onTap: () {
                      Navigator.pop(context);
                      Utils.shareApp(Platform.isIOS
                          ? "Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${videoDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
                    },
                    child: _buildDialogItems(
                      icon: "ic_dots_h.png",
                      title: "more",
                      isMultilang: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogItems({
    required String icon,
    required String title,
    required bool isMultilang,
  }) {
    return Container(
      height: Dimens.minHtDialogContent,
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MyImage(
            width: Dimens.dialogIconSize,
            height: Dimens.dialogIconSize,
            imagePath: icon,
            fit: BoxFit.contain,
            color: otherColor,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: MyText(
              text: title,
              multilanguage: isMultilang,
              fontsizeNormal: 14,
              fontsizeWeb: 16,
              color: white,
              fontstyle: FontStyle.normal,
              fontweight: FontWeight.w600,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
  /* ========= Dialogs ========= */

  /* ========= Open Player ========= */
  openPlayer(String playType) async {
    /* CHECK SUBSCRIPTION */
    if (playType != "Trailer") {
      bool? isPrimiumUser = await _checkSubsRentLogin();
      log("isPrimiumUser =============> $isPrimiumUser");
      if (!isPrimiumUser) return;
    }
    /* CHECK SUBSCRIPTION */
    log("ID :===> ${(videoDetailsProvider.sectionDetailModel.result?.id ?? 0)}");

    int? vID = (videoDetailsProvider.sectionDetailModel.result?.id ?? 0);
    int? vType =
        (videoDetailsProvider.sectionDetailModel.result?.videoType ?? 0);
    int? vTypeID = widget.typeId;

    int? stopTime;
    if (playType == "startOver" || playType == "Trailer") {
      stopTime = 0;
    } else {
      stopTime =
          (videoDetailsProvider.sectionDetailModel.result?.stopTime ?? 0);
    }

    String? videoThumb =
        (videoDetailsProvider.sectionDetailModel.result?.landscape ?? "");

    String? vUrl, vUploadType;
    if (playType == "Trailer") {
      Utils.clearQualitySubtitle();
      vUploadType =
          (videoDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      vUrl = (videoDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "");
    } else {
      /* Set-up Quality URLs */
      Utils.setQualityURLs(
        video320:
            (videoDetailsProvider.sectionDetailModel.result?.video320 ?? ""),
        video480:
            (videoDetailsProvider.sectionDetailModel.result?.video480 ?? ""),
        video720:
            (videoDetailsProvider.sectionDetailModel.result?.video720 ?? ""),
        video1080:
            (videoDetailsProvider.sectionDetailModel.result?.video1080 ?? ""),
      );

      vUrl = (videoDetailsProvider.sectionDetailModel.result?.video320 ?? "");
      vUploadType =
          (videoDetailsProvider.sectionDetailModel.result?.videoUploadType ??
              "");
    }

    log("vUploadType ===> $vUploadType");
    log("stopTime ===> $stopTime");

    if (!mounted) return;
    if (vUrl.isEmpty || vUrl == "") {
      if (playType == "Trailer") {
        Utils.showSnackbar(context, "info", "trailer_not_found", true);
      } else {
        Utils.showSnackbar(context, "info", "video_not_found", true);
      }
      return;
    }

    dynamic isContinue = await Utils.openPlayer(
      context: context,
      playType: playType == "Trailer" ? "Trailer" : "Video",
      videoId: vID,
      videoType: vType,
      typeId: vTypeID,
      otherId: 0,
      videoUrl: vUrl,
      trailerUrl: vUrl,
      uploadType: vUploadType,
      videoThumb: videoThumb,
      vStopTime: stopTime,
    );

    log("isContinue ===> $isContinue");
    if (isContinue != null && isContinue == true) {
      _getData();
    }
  }
  /* ========= Open Player ========= */

  Future<bool> _checkSubsRentLogin() async {
    if (Constant.userID != null) {
      if ((videoDetailsProvider.sectionDetailModel.result?.isPremium ?? 0) ==
              1 &&
          (videoDetailsProvider.sectionDetailModel.result?.isRent ?? 0) == 1) {
        if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
            (videoDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) ==
                1) {
          return true;
        } else {
          dynamic isSubscribed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const Subscription();
              },
            ),
          );
          if (isSubscribed != null && isSubscribed == true) {
            _getData();
          }
          return false;
        }
      } else if ((videoDetailsProvider.sectionDetailModel.result?.isPremium ??
              0) ==
          1) {
        if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1) {
          return true;
        } else {
          dynamic isSubscribed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const Subscription();
              },
            ),
          );
          if (isSubscribed != null && isSubscribed == true) {
            _getData();
          }
          return false;
        }
      } else if ((videoDetailsProvider.sectionDetailModel.result?.isRent ??
              0) ==
          1) {
        if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
            (videoDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) ==
                1) {
          return true;
        } else {
          dynamic isRented = await Utils.paymentForRent(
            context: context,
            videoId:
                videoDetailsProvider.sectionDetailModel.result?.id.toString() ??
                    '',
            rentPrice: videoDetailsProvider.sectionDetailModel.result?.rentPrice
                    .toString() ??
                '',
            vTitle: videoDetailsProvider.sectionDetailModel.result?.name
                    .toString() ??
                '',
            typeId: videoDetailsProvider.sectionDetailModel.result?.typeId
                    .toString() ??
                '',
            vType: videoDetailsProvider.sectionDetailModel.result?.videoType
                    .toString() ??
                '',
          );
          if (isRented != null && isRented == true) {
            _getData();
          }
          return false;
        }
      } else {
        return true;
      }
    } else {
      if ((kIsWeb || Constant.isTV)) {
        Utils.buildWebAlertDialog(context, "login", "")
            .then((value) => _getData());
        return false;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const LoginSocial();
          },
        ),
      );
      return false;
    }
  }
}
