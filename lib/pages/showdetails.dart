import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dtlive/main.dart';
import 'package:dtlive/model/sectiondetailmodel.dart';
import 'package:dtlive/pages/castdetails.dart';
import 'package:dtlive/pages/loginsocial.dart';
import 'package:dtlive/pages/mydownloads.dart';
import 'package:dtlive/provider/episodeprovider.dart';
import 'package:dtlive/provider/showdetailsprovider.dart';
import 'package:dtlive/provider/showdownloadprovider.dart';
import 'package:dtlive/shimmer/shimmerutils.dart';
import 'package:dtlive/subscription/subscription.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/utils/strings.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/webwidget/footerweb.dart';
import 'package:dtlive/widget/castcrew.dart';
import 'package:dtlive/widget/episodebyseason.dart';
import 'package:dtlive/widget/moredetails.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/widget/myusernetworkimg.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:dtlive/widget/relatedvideoshow.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:social_share/social_share.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class ShowDetails extends StatefulWidget {
  final int videoId, upcomingType, videoType, typeId;
  const ShowDetails(
      this.videoId, this.upcomingType, this.videoType, this.typeId,
      {super.key});

  @override
  State<ShowDetails> createState() => ShowDetailsState();
}

class ShowDetailsState extends State<ShowDetails> with RouteAware {
  /* Trailer init */
  VideoPlayerController? _trailerNormalController;
  YoutubePlayerController? _trailerYoutubeController;

  /* Download init */
  // late bool _permissionReady;
  late ShowDownloadProvider downloadProvider;
  final ReceivePort _port = ReceivePort();

  String? audioLanguages;
  List<Cast>? directorList;
  late ShowDetailsProvider showDetailsProvider;
  late EpisodeProvider episodeProvider;

  @override
  void initState() {
    if (!kIsWeb) {
      /* Download init ****/
      _bindBackgroundIsolate();
      FlutterDownloader.registerCallback(downloadCallback, step: 1); /* ****/
    }

    showDetailsProvider =
        Provider.of<ShowDetailsProvider>(context, listen: false);
    episodeProvider = Provider.of<EpisodeProvider>(context, listen: false);
    downloadProvider =
        Provider.of<ShowDownloadProvider>(context, listen: false);
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
    if (showDetailsProvider.sectionDetailModel.result?.trailerType ==
        "youtube") {
      if (_trailerYoutubeController == null) {
        loadTrailer(
            showDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        if (_trailerYoutubeController != null) {
          _trailerYoutubeController?.seekTo(seconds: 0.0);
          _trailerYoutubeController?.playVideo();
        }
      }
    } else {
      if (_trailerNormalController == null) {
        loadTrailer(
            showDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
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

  Future<void> _getData() async {
    Utils.getCurrencySymbol();
    await showDetailsProvider.getSectionDetails(
        widget.typeId, widget.videoType, widget.videoId, widget.upcomingType);
    if (showDetailsProvider.sectionDetailModel.status == 200) {
      if (showDetailsProvider.sectionDetailModel.result != null) {
        /* Trailer set-up */
        _setUpTrailer();
      }
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {
        log("setState videoId ======================> ${widget.videoId}");
      });
    });
  }

  /* Trailer Set-Up & Loading START */
  _setUpTrailer() {
    debugPrint(
        "trailerUrl ===========> ${showDetailsProvider.sectionDetailModel.result?.trailerUrl}");
    debugPrint(
        "trailerType ==========> ${showDetailsProvider.sectionDetailModel.result?.trailerType}");
    if (showDetailsProvider.sectionDetailModel.result?.trailerType ==
        "youtube") {
      if (_trailerYoutubeController == null) {
        loadTrailer(
            showDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        _trailerYoutubeController?.seekTo(seconds: 0.0);
      }
    } else {
      if (_trailerNormalController == null) {
        loadTrailer(
            showDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "",
            showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
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
        startSeconds: 0,
        params: const YoutubePlayerParams(
          showControls: false,
          showVideoAnnotations: false,
          playsInline: true,
          mute: false,
          showFullscreenButton: false,
          loop: true,
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
      Constant.showDownloadPort,
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

      if (progress > 0) {
        downloadProvider.setDownloadProgress(progress, status);
      }
    });
  }

  void _unbindBackgroundIsolate() {
    log('_unbindBackgroundIsolate');
    IsolateNameServer.removePortNameMapping(Constant.showDownloadPort);
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
      IsolateNameServer.lookupPortByName(Constant.showDownloadPort)
          ?.send([id, status, progress]);
    }
  }

  @override
  void dispose() {
    log("dispose isBroadcast ============================> ${_port.isBroadcast}");
    if (!_port.isBroadcast) {
      downloadProvider.clearProvider();
      showDetailsProvider.clearProvider();
      episodeProvider.clearProvider();
    }
    routeObserver.unsubscribe(this);
    log("dispose isBroadcast ============================> ${_port.isBroadcast}");
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
    if (showDetailsProvider.sectionDetailModel.status == 200) {
      if (showDetailsProvider.sectionDetailModel.cast != null &&
          (showDetailsProvider.sectionDetailModel.cast?.length ?? 0) > 0) {
        directorList = <Cast>[];
        for (int i = 0;
            i < (showDetailsProvider.sectionDetailModel.cast?.length ?? 0);
            i++) {
          if (showDetailsProvider.sectionDetailModel.cast?[i].type ==
              "Director") {
            Cast cast = Cast();
            cast.id = showDetailsProvider.sectionDetailModel.cast?[i].id ?? 0;
            cast.name =
                showDetailsProvider.sectionDetailModel.cast?[i].name ?? "";
            cast.image =
                showDetailsProvider.sectionDetailModel.cast?[i].image ?? "";
            cast.type =
                showDetailsProvider.sectionDetailModel.cast?[i].type ?? "";
            cast.personalInfo =
                showDetailsProvider.sectionDetailModel.cast?[i].personalInfo ??
                    "";
            cast.status =
                showDetailsProvider.sectionDetailModel.cast?[i].status ?? 0;
            cast.createdAt =
                showDetailsProvider.sectionDetailModel.cast?[i].createdAt ?? "";
            cast.updatedAt =
                showDetailsProvider.sectionDetailModel.cast?[i].updatedAt ?? "";
            directorList?.add(cast);
          }
        }
      }
      if (showDetailsProvider.sectionDetailModel.language != null &&
          (showDetailsProvider.sectionDetailModel.language?.length ?? 0) > 0) {
        for (int i = 0;
            i < (showDetailsProvider.sectionDetailModel.language?.length ?? 0);
            i++) {
          if (i == 0) {
            audioLanguages =
                showDetailsProvider.sectionDetailModel.language?[i].name ?? "";
          } else {
            audioLanguages =
                "$audioLanguages, ${showDetailsProvider.sectionDetailModel.language?[i].name ?? ""}";
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
    return (showDetailsProvider.loading)
        ? SingleChildScrollView(
            child: ((kIsWeb || Constant.isTV) &&
                    MediaQuery.of(context).size.width > 720)
                ? ShimmerUtils.buildDetailWebShimmer(context, "show")
                : ShimmerUtils.buildDetailMobileShimmer(context, "show"),
          )
        : (showDetailsProvider.sectionDetailModel.status == 200 &&
                showDetailsProvider.sectionDetailModel.result != null)
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
            ((showDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "")
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
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                              imageUrl: showDetailsProvider.sectionDetailModel
                                          .result?.thumbnail !=
                                      ""
                                  ? (showDetailsProvider.sectionDetailModel
                                          .result?.thumbnail ??
                                      "")
                                  : "",
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
                                text: showDetailsProvider
                                        .sectionDetailModel.result?.name ??
                                    "",
                                multilanguage: false,
                                textalign: TextAlign.start,
                                fontsizeNormal: 20,
                                fontsizeWeb: 24,
                                fontweight: FontWeight.w800,
                                maxline: 2,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  /* Release Year */
                                  (showDetailsProvider.sectionDetailModel.result
                                                  ?.releaseYear !=
                                              null &&
                                          showDetailsProvider.sectionDetailModel
                                                  .result?.releaseYear !=
                                              "")
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(right: 10),
                                          child: MyText(
                                            color: whiteLight,
                                            text: showDetailsProvider
                                                    .sectionDetailModel
                                                    .result
                                                    ?.releaseYear ??
                                                "",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 13,
                                            fontsizeWeb: 13,
                                            multilanguage: false,
                                            fontweight: FontWeight.w500,
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  /* Duration */
                                  (showDetailsProvider.sectionDetailModel.result
                                              ?.videoDuration !=
                                          null)
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(right: 10),
                                          child: MyText(
                                            color: otherColor,
                                            text: ((showDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.videoDuration ??
                                                        0) >
                                                    0)
                                                ? Utils.convertTimeToText(
                                                    showDetailsProvider
                                                            .sectionDetailModel
                                                            .result
                                                            ?.videoDuration ??
                                                        0)
                                                : "",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 13,
                                            fontsizeWeb: 13,
                                            fontweight: FontWeight.w500,
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  /* Age Limit */
                                  (showDetailsProvider.sectionDetailModel.result
                                                  ?.ageRestriction !=
                                              null &&
                                          showDetailsProvider.sectionDetailModel
                                                  .result?.ageRestriction !=
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
                                            text: showDetailsProvider
                                                    .sectionDetailModel
                                                    .result
                                                    ?.ageRestriction ??
                                                "",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 10,
                                            fontsizeWeb: 12,
                                            multilanguage: false,
                                            fontweight: FontWeight.w500,
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  /* MaxQuality */
                                  (showDetailsProvider.sectionDetailModel.result
                                                  ?.maxVideoQuality !=
                                              null &&
                                          showDetailsProvider.sectionDetailModel
                                                  .result?.maxVideoQuality !=
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
                                            text: showDetailsProvider
                                                    .sectionDetailModel
                                                    .result
                                                    ?.maxVideoQuality ??
                                                "",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 10,
                                            fontsizeWeb: 12,
                                            multilanguage: false,
                                            fontweight: FontWeight.w500,
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
                  if (widget.videoType != 5) const SizedBox(height: 15),

                  /* Season Title */
                  if (widget.videoType != 5)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _buildSeasonBtn(),
                    ),

                  /* Release Date */
                  _buildReleaseDate(),

                  /* Prime TAG */
                  if ((showDetailsProvider
                              .sectionDetailModel.result?.isPremium ??
                          0) ==
                      1)
                    Container(
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
                    ),

                  /* Rent TAG */
                  if ((showDetailsProvider.sectionDetailModel.result?.isRent ??
                          0) ==
                      1)
                    Container(
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
                    ),

                  /* Play Video button */
                  /* Continue Watching Button */
                  /* Subscription Button */
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: (widget.videoType == 5)
                        ? _buildWatchTrailer()
                        : _buildWatchNow(),
                  ),

                  /* Included Features buttons */
                  if ((widget.videoType != 5))
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: (kIsWeb || Constant.isTV)
                            ? (MediaQuery.of(context).size.width / 2)
                            : MediaQuery.of(context).size.width,
                        constraints: const BoxConstraints(minHeight: 0),
                        margin: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /* Rent Button */
                            _buildRentBtn(),
                            const SizedBox(width: 5),

                            /* Trailer */
                            Expanded(
                              child: InkWell(
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
                              ),
                            ),

                            /* Download */
                            if (!(kIsWeb || Constant.isTV))
                              Consumer<EpisodeProvider>(
                                builder: (context, episodeProvider, child) {
                                  if ((episodeProvider.episodeBySeasonModel
                                              .result?[0].download ??
                                          0) ==
                                      1) {
                                    return _buildDownloadWithSubCheck();
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),

                            /* Watchlist */
                            Expanded(
                              child: InkWell(
                                focusColor: gray.withOpacity(0.5),
                                onTap: () async {
                                  log("isBookmark ====> ${showDetailsProvider.sectionDetailModel.result?.isBookmark ?? 0}");
                                  if (Constant.userID != null) {
                                    await showDetailsProvider.setBookMark(
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
                                child: Consumer<ShowDetailsProvider>(
                                  builder:
                                      (context, showDetailsProvider, child) {
                                    if ((showDetailsProvider.sectionDetailModel
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

                            /* Share */
                            if (!(kIsWeb || Constant.isTV))
                              Expanded(
                                child: InkWell(
                                  focusColor: gray.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () {
                                    _buildShareWithDialog();
                                  },
                                  child: _buildFeatureBtn(
                                    icon: 'ic_share.png',
                                    title: 'share',
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
                            showDetailsProvider
                                    .sectionDetailModel.result?.description ??
                                "",
                            expandText: more,
                            collapseText: less_,
                            maxLines: (kIsWeb || Constant.isTV) ? 50 : 3,
                            linkColor: otherColor,
                            expandOnTextTap: true,
                            collapseOnTextTap: true,
                            style: TextStyle(
                              fontSize: (kIsWeb || Constant.isTV) ? 13 : 14,
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
                                  "${showDetailsProvider.sectionDetailModel.result?.imdbRating ?? 0}",
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
                                  text: showDetailsProvider.sectionDetailModel
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
                        Consumer<EpisodeProvider>(
                          builder: (context, episodeProvider, child) {
                            if (Constant.subtitleUrls.isNotEmpty) {
                              return Container(
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
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // /* Related ~ More Details */
                  Consumer<ShowDetailsProvider>(
                    builder: (context, showDetailsProvider, child) {
                      return _buildTabs();
                    },
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

  Widget _buildWebData() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                          imageUrl: showDetailsProvider
                                      .sectionDetailModel.result?.landscape !=
                                  ""
                              ? (showDetailsProvider
                                      .sectionDetailModel.result?.landscape ??
                                  "")
                              : (showDetailsProvider
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
                    height: Dimens.detailWebPoster + 30,
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
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              constraints: const BoxConstraints(minHeight: 0),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  MyText(
                                    color: white,
                                    text: showDetailsProvider
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
                                      /* Category */
                                      (showDetailsProvider.sectionDetailModel
                                                      .result?.categoryName !=
                                                  null &&
                                              showDetailsProvider
                                                      .sectionDetailModel
                                                      .result
                                                      ?.categoryName !=
                                                  "")
                                          ? Container(
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              child: MyText(
                                                color: whiteLight,
                                                text: showDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.categoryName ??
                                                    "",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 13,
                                                fontsizeWeb: 13,
                                                fontweight: FontWeight.w600,
                                                multilanguage: false,
                                                maxline: 1,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal,
                                              ),
                                            )
                                          : const SizedBox.shrink(),

                                      /* Release Year */
                                      (showDetailsProvider.sectionDetailModel
                                                      .result?.releaseYear !=
                                                  null &&
                                              showDetailsProvider
                                                      .sectionDetailModel
                                                      .result
                                                      ?.releaseYear !=
                                                  "")
                                          ? Container(
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              child: MyText(
                                                color: whiteLight,
                                                text: showDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.releaseYear ??
                                                    "",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 13,
                                                fontsizeWeb: 13,
                                                fontweight: FontWeight.w500,
                                                multilanguage: false,
                                                maxline: 1,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal,
                                              ),
                                            )
                                          : const SizedBox.shrink(),

                                      /* Duration */
                                      (showDetailsProvider.sectionDetailModel
                                                  .result?.videoDuration !=
                                              null)
                                          ? Container(
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              child: MyText(
                                                color: otherColor,
                                                multilanguage: false,
                                                text: ((showDetailsProvider
                                                                .sectionDetailModel
                                                                .result
                                                                ?.videoDuration ??
                                                            0) >
                                                        0)
                                                    ? Utils.convertTimeToText(
                                                        showDetailsProvider
                                                                .sectionDetailModel
                                                                .result
                                                                ?.videoDuration ??
                                                            0)
                                                    : "",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 13,
                                                fontsizeWeb: 13,
                                                fontweight: FontWeight.w500,
                                                maxline: 1,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal,
                                              ),
                                            )
                                          : const SizedBox.shrink(),

                                      /* MaxQuality */
                                      (showDetailsProvider
                                                      .sectionDetailModel
                                                      .result
                                                      ?.maxVideoQuality !=
                                                  null &&
                                              showDetailsProvider
                                                      .sectionDetailModel
                                                      .result
                                                      ?.maxVideoQuality !=
                                                  "")
                                          ? Container(
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              padding:
                                                  const EdgeInsets.fromLTRB(
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
                                                text: showDetailsProvider
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

                                      /* IMDb */
                                      MyImage(
                                        width: 40,
                                        height: 15,
                                        imagePath: "imdb.png",
                                      ),
                                      MyText(
                                        color: otherColor,
                                        text:
                                            "${showDetailsProvider.sectionDetailModel.result?.imdbRating ?? 0}",
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
                                    constraints:
                                        const BoxConstraints(minHeight: 0),
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
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /* Subtitle */
                                  Consumer<EpisodeProvider>(
                                    builder: (context, episodeProvider, child) {
                                      if (Constant.subtitleUrls.isNotEmpty) {
                                        return Container(
                                          constraints: const BoxConstraints(
                                              minHeight: 0),
                                          margin: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              MyText(
                                                color: whiteLight,
                                                text: "subtitle",
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
                                                  text: "Available",
                                                  textalign: TextAlign.start,
                                                  fontsizeNormal: 13,
                                                  fontweight: FontWeight.w500,
                                                  fontsizeWeb: 13,
                                                  maxline: 1,
                                                  multilanguage: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontstyle: FontStyle.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),

                                  /* Season Title */
                                  if (widget.videoType != 5)
                                    const SizedBox(height: 10),
                                  if (widget.videoType != 5) _buildSeasonBtn(),

                                  /* Release Date */
                                  _buildReleaseDate(),

                                  /* Prime TAG */
                                  (showDetailsProvider.sectionDetailModel.result
                                                  ?.isPremium ??
                                              0) ==
                                          1
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(top: 10),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              MyText(
                                                color: primaryColor,
                                                text: "primetag",
                                                textalign: TextAlign.start,
                                                fontsizeNormal: 12,
                                                fontsizeWeb: 12,
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
                                                fontsizeWeb: 12,
                                                fontweight: FontWeight.w400,
                                                maxline: 1,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal,
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),

                                  /* Rent TAG */
                                  (showDetailsProvider.sectionDetailModel.result
                                                  ?.isRent ??
                                              0) ==
                                          1
                                      ? Container(
                                          margin: const EdgeInsets.only(
                                              top: 10, bottom: 10),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: complimentryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  shape: BoxShape.rectangle,
                                                ),
                                                alignment: Alignment.center,
                                                child: MyText(
                                                  color: white,
                                                  text: Constant.currencySymbol,
                                                  textalign: TextAlign.center,
                                                  fontsizeNormal: 11,
                                                  fontsizeWeb: 11,
                                                  fontweight: FontWeight.w700,
                                                  multilanguage: false,
                                                  maxline: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontstyle: FontStyle.normal,
                                                ),
                                              ),
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 5),
                                                child: MyText(
                                                  color: white,
                                                  text: "renttag",
                                                  textalign: TextAlign.center,
                                                  fontsizeNormal: 12,
                                                  fontsizeWeb: 13,
                                                  multilanguage: true,
                                                  fontweight: FontWeight.w500,
                                                  maxline: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontstyle: FontStyle.normal,
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
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.only(
                                            top: 15, bottom: 8),
                                        child: ExpandableText(
                                          showDetailsProvider.sectionDetailModel
                                                  .result?.description ??
                                              "",
                                          animation: true,
                                          textAlign: TextAlign.start,
                                          expandOnTextTap: true,
                                          collapseOnTextTap: true,
                                          expandText: "",
                                          maxLines: 10,
                                          linkColor: primaryColor,
                                          style: TextStyle(
                                            fontSize: (kIsWeb || Constant.isTV)
                                                ? 13
                                                : 13,
                                            fontStyle: FontStyle.normal,
                                            color: white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                ],
                              ),
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

            /* Included Features buttons */
            Container(
              alignment: Alignment.centerLeft,
              constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
              margin: const EdgeInsets.fromLTRB(30, 10, 0, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /* Continue Watching Button */
                  /* Watch Now button */
                  (widget.videoType == 5)
                      ? _buildWatchTrailer()
                      : _buildWatchNow(),
                  const SizedBox(width: 10),

                  /* Rent Button */
                  if (widget.videoType != 5)
                    Container(
                      constraints: const BoxConstraints(minWidth: 0),
                      child: _buildRentBtn(),
                    ),
                  if (widget.videoType != 5) const SizedBox(width: 10),

                  /* Trailer Button */
                  if (widget.videoType != 5)
                    Container(
                      constraints: const BoxConstraints(minWidth: 50),
                      child: InkWell(
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
                      ),
                    ),
                  if (widget.videoType != 5) const SizedBox(width: 10),

                  /* Watchlist */
                  if (widget.videoType != 5)
                    Container(
                      constraints: const BoxConstraints(minWidth: 50),
                      child: InkWell(
                        onTap: () async {
                          log("isBookmark ====> ${showDetailsProvider.sectionDetailModel.result?.isBookmark ?? 0}");
                          if (Constant.userID != null) {
                            await showDetailsProvider.setBookMark(
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
                        focusColor: gray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Consumer<ShowDetailsProvider>(
                            builder: (context, showDetailsProvider, child) {
                              if ((showDetailsProvider.sectionDetailModel.result
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
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /* Other Details */
            /* Related ~ More Details */
            Consumer<ShowDetailsProvider>(
              builder: (context, showDetailsProvider, child) {
                return _buildTabs();
              },
            ),
            const SizedBox(height: 20),

            /* Web Footer */
            (kIsWeb || Constant.isTV)
                ? const FooterWeb()
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonBtn() {
    if ((kIsWeb || Constant.isTV)) {
      if (showDetailsProvider.sectionDetailModel.session != null &&
          (showDetailsProvider.sectionDetailModel.session?.length ?? 0) > 0) {
        return Consumer<ShowDetailsProvider>(
          builder: (context, showDetailsProvider, child) {
            return DropdownButtonHideUnderline(
              child: DropdownButton2(
                isDense: true,
                isExpanded: true,
                customButton: FittedBox(
                  child: Container(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        MyText(
                          color: white,
                          text: showDetailsProvider
                                  .sectionDetailModel
                                  .session?[showDetailsProvider.seasonPos]
                                  .name ??
                              "",
                          textalign: TextAlign.center,
                          multilanguage: false,
                          fontweight: FontWeight.w700,
                          fontsizeNormal: 15,
                          fontsizeWeb: 16,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(width: 8),
                        MyImage(
                          width: 12,
                          height: 12,
                          imagePath: "ic_dropdown.png",
                          color: lightGray,
                        )
                      ],
                    ),
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  width: 180,
                  useSafeArea: true,
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  decoration: Utils.setBackground(lightBlack, 5),
                  elevation: 8,
                ),
                menuItemStyleData: MenuItemStyleData(
                  overlayColor: MaterialStateProperty.resolveWith(
                    (states) {
                      if (states.contains(MaterialState.focused)) {
                        return white.withOpacity(0.5);
                      }
                      return transparentColor;
                    },
                  ),
                ),
                buttonStyleData: ButtonStyleData(
                  decoration:
                      Utils.setBGWithBorder(transparentColor, white, 20, 1),
                  overlayColor: MaterialStateProperty.resolveWith(
                    (states) {
                      if (states.contains(MaterialState.focused)) {
                        return white.withOpacity(0.5);
                      }
                      if (states.contains(MaterialState.hovered)) {
                        return white.withOpacity(0.5);
                      }
                      return transparentColor;
                    },
                  ),
                ),
                items: _buildWebDropDownItems(),
                onChanged: (Session? value) async {
                  debugPrint("SeasonID ====> ${(value?.id ?? 0)}");
                  int? mSeason;
                  for (var i = 0;
                      i <
                          (showDetailsProvider
                                  .sectionDetailModel.session?.length ??
                              0);
                      i++) {
                    if ((showDetailsProvider
                                .sectionDetailModel.session?[i].id ??
                            0) ==
                        (value?.id ?? 0)) {
                      mSeason = i;
                    }
                  }
                  final detailsProvider =
                      Provider.of<ShowDetailsProvider>(context, listen: false);
                  await detailsProvider.setSeasonPosition(
                      mSeason ?? (detailsProvider.seasonPos));
                  debugPrint("seasonPos ====> ${detailsProvider.seasonPos}");
                  await getAllEpisode(mSeason ?? (detailsProvider.seasonPos),
                      detailsProvider.sectionDetailModel.session);
                },
              ),
            );
          },
        );
      } else {
        return const SizedBox.shrink();
      }
    } else if (showDetailsProvider.sectionDetailModel.session != null &&
        (showDetailsProvider.sectionDetailModel.session?.length ?? 0) > 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            log("session Length ====> ${showDetailsProvider.sectionDetailModel.session?.length ?? 0}");
            _buildSeasonDialog(
                showDetailsProvider.sectionDetailModel.result?.name ?? "",
                showDetailsProvider.sectionDetailModel.session);
          },
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                Consumer<ShowDetailsProvider>(
                  builder: (context, showDetailsProvider, child) {
                    return MyText(
                      color: white,
                      text: showDetailsProvider.sectionDetailModel
                              .session?[showDetailsProvider.seasonPos].name ??
                          "",
                      textalign: TextAlign.center,
                      multilanguage: false,
                      fontweight: FontWeight.w600,
                      fontsizeNormal: 15,
                      fontsizeWeb: 15,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    );
                  },
                ),
                const SizedBox(width: 5),
                MyImage(
                  width: 12,
                  height: 12,
                  imagePath: "ic_dropdown.png",
                  color: lightGray,
                )
              ],
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<DropdownMenuItem<Session>>? _buildWebDropDownItems() {
    return showDetailsProvider.sectionDetailModel.session
        ?.map<DropdownMenuItem<Session>>(
      (Session value) {
        return DropdownMenuItem<Session>(
          value: value,
          alignment: Alignment.center,
          child: FittedBox(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 35, minWidth: 100),
              decoration: Utils.setBackground(
                showDetailsProvider.seasonPos != -1
                    ? ((showDetailsProvider
                                    .sectionDetailModel
                                    .session?[showDetailsProvider.seasonPos]
                                    .id ??
                                0) ==
                            (value.id ?? 0)
                        ? white
                        : transparentColor)
                    : transparentColor,
                20,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: MyText(
                color: showDetailsProvider.seasonPos != -1
                    ? ((showDetailsProvider
                                    .sectionDetailModel
                                    .session?[showDetailsProvider.seasonPos]
                                    .id ??
                                0) ==
                            (value.id ?? 0)
                        ? black
                        : white)
                    : white,
                multilanguage: false,
                text: (value.name.toString()),
                fontsizeNormal: 14,
                fontweight: FontWeight.w600,
                fontsizeWeb: 15,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ),
          ),
        );
      },
    ).toList();
  }

  Widget _buildRentBtn() {
    if ((showDetailsProvider.sectionDetailModel.result?.isPremium ?? 0) == 1 &&
        (showDetailsProvider.sectionDetailModel.result?.isRent ?? 0) == 1) {
      if ((showDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (showDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
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
                  videoId: showDetailsProvider.sectionDetailModel.result?.id
                          .toString() ??
                      '',
                  rentPrice: showDetailsProvider
                          .sectionDetailModel.result?.rentPrice
                          .toString() ??
                      '',
                  vTitle: showDetailsProvider.sectionDetailModel.result?.name
                          .toString() ??
                      '',
                  typeId: showDetailsProvider.sectionDetailModel.result?.typeId
                          .toString() ??
                      '',
                  vType: showDetailsProvider
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
                  "Rent at just\n${Constant.currencySymbol}${showDetailsProvider.sectionDetailModel.result?.rentPrice ?? 0}",
              multilanguage: false,
            ),
          ),
        );
      }
    } else if ((showDetailsProvider.sectionDetailModel.result?.isRent ?? 0) ==
        1) {
      if ((showDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (showDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
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
                  videoId: showDetailsProvider.sectionDetailModel.result?.id
                          .toString() ??
                      '',
                  rentPrice: showDetailsProvider
                          .sectionDetailModel.result?.rentPrice
                          .toString() ??
                      '',
                  vTitle: showDetailsProvider.sectionDetailModel.result?.name
                          .toString() ??
                      '',
                  typeId: showDetailsProvider.sectionDetailModel.result?.typeId
                          .toString() ??
                      '',
                  vType: showDetailsProvider
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
                  "Rent at just\n${Constant.currencySymbol}${showDetailsProvider.sectionDetailModel.result?.rentPrice ?? 0}",
              multilanguage: false,
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildReleaseDate() {
    if (widget.videoType == 5) {
      if (showDetailsProvider.sectionDetailModel.result?.releaseDate != null &&
          (showDetailsProvider.sectionDetailModel.result?.releaseDate ?? "") !=
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
                      showDetailsProvider
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
    if ((showDetailsProvider.sectionDetailModel.result?.trailerType ?? "") ==
        "youtube") {
      if (_trailerYoutubeController != null) {
        return _buildTrailerView(
            showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
      } else {
        return _buildMobilePoster();
      }
    } else {
      if (_trailerNormalController != null &&
          (_trailerNormalController?.value.isInitialized ?? false)) {
        return _buildTrailerView(
            showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
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
            imageUrl: showDetailsProvider
                        .sectionDetailModel.result?.landscape !=
                    ""
                ? (showDetailsProvider.sectionDetailModel.result?.landscape ??
                    "")
                : (showDetailsProvider.sectionDetailModel.result?.thumbnail ??
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
    return Consumer<EpisodeProvider>(
      builder: (context, episodeProvider, child) {
        if (showDetailsProvider.mCurrentEpiPos != -1 &&
            (episodeProvider.episodeBySeasonModel
                        .result?[showDetailsProvider.mCurrentEpiPos].stopTime ??
                    0) >
                0 &&
            episodeProvider
                    .episodeBySeasonModel
                    .result?[showDetailsProvider.mCurrentEpiPos]
                    .videoDuration !=
                null) {
          return Container(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () {
                openPlayer("Show");
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  MyText(
                                    color: white,
                                    text:
                                        "Continue Watching Episode ${(showDetailsProvider.mCurrentEpiPos + 1)}",
                                    multilanguage: false,
                                    textalign: TextAlign.start,
                                    fontsizeNormal: 13,
                                    fontsizeWeb: 15,
                                    fontweight: FontWeight.w700,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                  Row(
                                    children: [
                                      MyText(
                                        color: white,
                                        text: Utils.remainTimeInMin(((episodeProvider
                                                        .episodeBySeasonModel
                                                        .result?[
                                                            showDetailsProvider
                                                                .mCurrentEpiPos]
                                                        .videoDuration ??
                                                    0) -
                                                (episodeProvider
                                                        .episodeBySeasonModel
                                                        .result?[
                                                            showDetailsProvider
                                                                .mCurrentEpiPos]
                                                        .stopTime ??
                                                    0))
                                            .abs()),
                                        textalign: TextAlign.start,
                                        fontsizeNormal: 10,
                                        fontsizeWeb: 12,
                                        multilanguage: false,
                                        fontweight: FontWeight.w500,
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
                                        fontsizeWeb: 12,
                                        multilanguage: true,
                                        fontweight: FontWeight.w500,
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
                              episodeProvider
                                      .episodeBySeasonModel
                                      .result?[
                                          showDetailsProvider.mCurrentEpiPos]
                                      .videoDuration ??
                                  0,
                              episodeProvider
                                      .episodeBySeasonModel
                                      .result?[
                                          showDetailsProvider.mCurrentEpiPos]
                                      .stopTime ??
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
                openPlayer("Show");
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
                          text: "Watch Episode 1",
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
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    onTap: () async {
                      await showDetailsProvider.setTabClick("related");
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: MyText(
                              color:
                                  showDetailsProvider.tabClickedOn != "related"
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
                              showDetailsProvider.tabClickedOn == "related",
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
                /* More Details */
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      await showDetailsProvider.setTabClick("moredetails");
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: MyText(
                              color: showDetailsProvider.tabClickedOn !=
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
                          visible:
                              showDetailsProvider.tabClickedOn == "moredetails",
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
          (showDetailsProvider.tabClickedOn == "related")
              ? Container(
                  padding: ((kIsWeb || Constant.isTV) &&
                          MediaQuery.of(context).size.width > 720)
                      ? const EdgeInsets.fromLTRB(10, 0, 10, 0)
                      : const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      /* Episodes */
                      if (widget.videoType != 5)
                        (showDetailsProvider.sectionDetailModel.session !=
                                    null &&
                                (showDetailsProvider.sectionDetailModel.session
                                            ?.length ??
                                        0) >
                                    0)
                            ? Column(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 55,
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                    alignment: Alignment.bottomLeft,
                                    child: MyText(
                                      color: white,
                                      text: "episodes",
                                      multilanguage: true,
                                      textalign: TextAlign.center,
                                      fontsizeNormal: 15,
                                      fontsizeWeb: 16,
                                      maxline: 1,
                                      fontweight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      fontstyle: FontStyle.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: ((kIsWeb || Constant.isTV) &&
                                            MediaQuery.of(context).size.width >
                                                720)
                                        ? const EdgeInsets.fromLTRB(
                                            20, 0, 20, 0)
                                        : const EdgeInsets.all(0),
                                    width: MediaQuery.of(context).size.width,
                                    constraints:
                                        const BoxConstraints(minHeight: 50),
                                    child: Consumer<EpisodeProvider>(
                                      builder:
                                          (context, episodeProvider, child) {
                                        return EpisodeBySeason(
                                          widget.videoId,
                                          widget.upcomingType,
                                          widget.typeId,
                                          showDetailsProvider.seasonPos,
                                          showDetailsProvider
                                              .sectionDetailModel.session,
                                          showDetailsProvider
                                              .sectionDetailModel.result,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),

                      /* Customers also watched */
                      RelatedVideoShow(
                        relatedDataList: showDetailsProvider
                            .sectionDetailModel.getRelatedVideo,
                      ),

                      /* Cast & Crew */
                      CastCrew(
                          castList:
                              showDetailsProvider.sectionDetailModel.cast),

                      /* Director */
                      _buildDirector(),
                    ],
                  ),
                )
              : /* More Details */
              MoreDetails(
                  moreDetailList:
                      showDetailsProvider.sectionDetailModel.moreDetails)
        ],
      ),
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
              focusColor: white,
              borderRadius: BorderRadius.circular(Dimens.cardRadius),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CastDetails(
                        castID: directorList?[0].id.toString() ?? ""),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(2),
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
                    fontsizeNormal: 14,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 15,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  MyText(
                    color: otherColor,
                    text: directorList?[0].personalInfo ?? "",
                    textalign: TextAlign.start,
                    multilanguage: false,
                    fontsizeNormal: 13,
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
    if ((showDetailsProvider.sectionDetailModel.result?.isPremium ?? 0) == 1) {
      if ((showDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (showDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
        return _buildDownloadBtn();
      } else {
        return const SizedBox.shrink();
      }
    } else if ((showDetailsProvider.sectionDetailModel.result?.isRent ?? 0) ==
        1) {
      if ((showDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (showDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
        return _buildDownloadBtn();
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return _buildDownloadBtn();
    }
  }

  Widget _buildDownloadBtn() {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        focusColor: white,
        onTap: () async {
          if (Constant.userID != null) {
            if (showDetailsProvider.sectionDetailModel
                    .session?[showDetailsProvider.seasonPos].isDownloaded ==
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
              Consumer2<ShowDetailsProvider, ShowDownloadProvider>(
                builder:
                    (context, showDetailsProvider, downloadProvider, child) {
                  if (downloadProvider.sectionDetails?.id ==
                          showDetailsProvider.sectionDetailModel.result?.id &&
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
                        imagePath: (showDetailsProvider
                                    .sectionDetailModel
                                    .session?[showDetailsProvider.seasonPos]
                                    .isDownloaded ==
                                1)
                            ? "ic_download_done.png"
                            : "ic_download.png",
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 5),
              Consumer<ShowDetailsProvider>(
                builder: (context, showDetailsProvider, child) {
                  return MyText(
                    color: white,
                    text: (showDetailsProvider
                                .sectionDetailModel
                                .session?[showDetailsProvider.seasonPos]
                                .isDownloaded ==
                            1)
                        ? "Complete\nSeason ${(showDetailsProvider.seasonPos + 1)}"
                        : "Download\nSeason ${(showDetailsProvider.seasonPos + 1)}",
                    multilanguage: false,
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
  }

  _checkAndDownload() async {
    // _permissionReady = await Utils.checkPermission();
    // if (_permissionReady) {
    if (showDetailsProvider.sectionDetailModel
            .session?[showDetailsProvider.seasonPos].isDownloaded ==
        0) {
      if ((showDetailsProvider.episodeBySeasonModel.result?[0].video320 ?? "")
          .isNotEmpty) {
        log("seasonPos ----------------------> ${showDetailsProvider.seasonPos}");
        log("episode Length -----------------> ${episodeProvider.episodeBySeasonModel.result?.length}");
        if (!mounted) return;
        await downloadProvider.prepareDownload(
            context,
            showDetailsProvider.sectionDetailModel.result,
            showDetailsProvider.sectionDetailModel.session,
            showDetailsProvider.seasonPos,
            episodeProvider.episodeBySeasonModel.result);
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
                      await showDetailsProvider.setDownloadComplete(
                          context,
                          showDetailsProvider.sectionDetailModel
                              .session?[showDetailsProvider.seasonPos].id,
                          showDetailsProvider
                              .sectionDetailModel.result?.videoType,
                          showDetailsProvider.sectionDetailModel.result?.typeId,
                          showDetailsProvider.sectionDetailModel.result?.id);
                      await downloadProvider.deleteShowFromDownload(
                          showDetailsProvider.sectionDetailModel.result?.id
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

  /* ========= Dialogs ========= */
  _buildShareWithDialog() {
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
                    text: showDetailsProvider.sectionDetailModel.result?.name ??
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
                      (showDetailsProvider.sectionDetailModel.result
                                      ?.ageRestriction ??
                                  "")
                              .isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: Utils.setBGWithBorder(
                                  transparentColor, otherColor, 3, 0.7),
                              child: MyText(
                                text: showDetailsProvider.sectionDetailModel
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
                    onTap: () {
                      Navigator.pop(context);
                      if (Platform.isAndroid) {
                        Utils.redirectToUrl(
                            'sms:?body=${Uri.encodeComponent("Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n")}');
                      } else if (Platform.isIOS) {
                        Utils.redirectToUrl(
                            'sms:&body=${Uri.encodeComponent("Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n")}');
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
                    onTap: () {
                      Navigator.pop(context);
                      Utils.shareApp(Platform.isIOS
                          ? "Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
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
                    onTap: () {
                      Navigator.pop(context);
                      SocialShare.copyToClipboard(
                        text: Platform.isIOS
                            ? "Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                            : "Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n",
                      ).then((data) {
                        debugPrint(data);
                        Utils.showSnackbar(
                            context, "success", "link_copied", true);
                      });
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
                    onTap: () {
                      Navigator.pop(context);
                      Utils.shareApp(Platform.isIOS
                          ? "Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${showDetailsProvider.sectionDetailModel.result?.name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
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

  _buildSeasonDialog(String? vTitle, List<Session>? seasonList) {
    log("seasonList Size ===> ${seasonList?.length ?? 0}");
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
                  MyText(
                    text: vTitle ?? "",
                    fontsizeNormal: 16,
                    fontsizeWeb: 15,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.bold,
                    maxline: 1,
                    multilanguage: false,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                    color: white,
                  ),
                  const SizedBox(height: 13),
                  AlignedGridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 1,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 4,
                    itemCount: seasonList?.length ?? 0,
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () async {
                          log("SeasonID ====> ${(seasonList?[index].id ?? 0)}");
                          log("index ====> $index");
                          final detailsProvider =
                              Provider.of<ShowDetailsProvider>(context,
                                  listen: false);
                          Navigator.pop(context);
                          await detailsProvider.setSeasonPosition(index);
                          log("seasonPos ====> ${detailsProvider.seasonPos}");
                          await getAllEpisode(detailsProvider.seasonPos,
                              detailsProvider.sectionDetailModel.session);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: MyText(
                            text: seasonList?[index].name ?? "-",
                            fontsizeNormal: 15,
                            fontsizeWeb: 15,
                            fontstyle: FontStyle.normal,
                            fontweight: FontWeight.w500,
                            multilanguage: false,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            textalign: TextAlign.start,
                            color: white,
                          ),
                        ),
                      );
                    },
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
              fontsizeWeb: 15,
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

  Future<void> getAllEpisode(int position, List<Session>? seasonList) async {
    log("position ====> $position");
    log("seasonList seasonID ====> ${seasonList?[position].id}");
    await episodeProvider.getEpisodeBySeason(
        seasonList?[position].id ?? 0, widget.videoId);

    if (episodeProvider.episodeBySeasonModel.status == 200) {
      if (episodeProvider.episodeBySeasonModel.result != null) {
        /* Set-up Subtitle URLs */
        Utils.setSubtitleURLs(
          subtitleUrl1: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].subtitle1 ??
              ""),
          subtitleUrl2: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].subtitle2 ??
              ""),
          subtitleUrl3: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].subtitle3 ??
              ""),
          subtitleLang1: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].subtitleLang1 ??
              ""),
          subtitleLang2: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].subtitleLang2 ??
              ""),
          subtitleLang3: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].subtitleLang3 ??
              ""),
        );
      }
    }
  }

  /* ========= Open Player ========= */
  openPlayer(String playType) async {
    log("mCurrentEpiPos ========> ${showDetailsProvider.mCurrentEpiPos}");

    /* CHECK SUBSCRIPTION */
    if (playType != "Trailer") {
      bool? isPrimiumUser = await _checkSubsRentLogin();
      log("isPrimiumUser =============> $isPrimiumUser");
      if (!isPrimiumUser) return;
    }
    /* CHECK SUBSCRIPTION */

    if ((episodeProvider.episodeBySeasonModel.result?.length ?? 0) > 0) {
      int? epiID = (episodeProvider.episodeBySeasonModel
              .result?[showDetailsProvider.mCurrentEpiPos].id ??
          0);
      int? showID = (episodeProvider.episodeBySeasonModel
              .result?[showDetailsProvider.mCurrentEpiPos].showId ??
          0);
      int? vType = widget.videoType;
      int? vTypeID = widget.typeId;
      int? stopTime;
      if (playType == "startOver" || playType == "Trailer") {
        stopTime = 0;
      } else {
        stopTime = (episodeProvider.episodeBySeasonModel
                .result?[showDetailsProvider.mCurrentEpiPos].stopTime ??
            0);
      }
      String? videoThumb = (episodeProvider.episodeBySeasonModel
              .result?[showDetailsProvider.mCurrentEpiPos].landscape ??
          "");
      log("epiID ========> $epiID");
      log("vType ========> $vType");
      log("vTypeID ======> $vTypeID");
      log("stopTime =====> $stopTime");
      log("videoThumb ===> $videoThumb");

      String? vUrl, vUploadType;
      if (playType == "Trailer") {
        Utils.clearQualitySubtitle();
        vUploadType =
            (showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
        vUrl =
            (showDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "");
      } else {
        /* Set-up Quality URLs */
        Utils.setQualityURLs(
          video320: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].video320 ??
              ""),
          video480: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].video480 ??
              ""),
          video720: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].video720 ??
              ""),
          video1080: (episodeProvider.episodeBySeasonModel
                  .result?[showDetailsProvider.mCurrentEpiPos].video1080 ??
              ""),
        );

        vUrl = (episodeProvider.episodeBySeasonModel
                .result?[showDetailsProvider.mCurrentEpiPos].video320 ??
            "");
        vUploadType = (episodeProvider.episodeBySeasonModel
                .result?[showDetailsProvider.mCurrentEpiPos].videoUploadType ??
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
      if (!mounted) return;
      dynamic isContinue = await Utils.openPlayer(
        context: context,
        playType: playType == "Trailer" ? "Trailer" : "Show",
        videoId: epiID,
        videoType: vType,
        typeId: vTypeID,
        otherId: showID,
        videoUrl: vUrl,
        trailerUrl: vUrl,
        uploadType: vUploadType,
        videoThumb: videoThumb,
        vStopTime: stopTime,
      );

      log("isContinue ===> $isContinue");
      if (isContinue != null && isContinue == true) {
        await _getData();
        await getAllEpisode(showDetailsProvider.seasonPos,
            showDetailsProvider.sectionDetailModel.session);
      }
    } else {
      String? vUrl, vUploadType;
      if (playType == "Trailer") {
        int? stopTime = 0;
        String? videoThumb =
            (showDetailsProvider.sectionDetailModel.result?.landscape ?? "");
        log("stopTime =====> $stopTime");
        log("videoThumb ===> $videoThumb");
        Utils.clearQualitySubtitle();
        vUploadType =
            (showDetailsProvider.sectionDetailModel.result?.trailerType ?? "");
        vUrl =
            (showDetailsProvider.sectionDetailModel.result?.trailerUrl ?? "");

        log("vUploadType ===> $vUploadType");
        log("stopTime ===> $stopTime");

        if (!mounted) return;
        if (vUrl.isEmpty || vUrl == "") {
          Utils.showSnackbar(context, "info", "trailer_not_found", true);
          return;
        }

        if (!mounted) return;
        await Utils.openPlayer(
          context: context,
          playType: "Trailer",
          videoId: 0,
          videoType: 0,
          typeId: 0,
          otherId: 0,
          videoUrl: vUrl,
          trailerUrl: vUrl,
          uploadType: vUploadType,
          videoThumb: videoThumb,
          vStopTime: stopTime,
        );
      } else {
        if (!mounted) return;
        Utils.showSnackbar(context, "info", "episode_not_found", true);
      }
    }
  }
  /* ========= Open Player ========= */

  Future<bool> _checkSubsRentLogin() async {
    if (Constant.userID != null) {
      if ((showDetailsProvider.sectionDetailModel.result?.isPremium ?? 0) ==
              1 &&
          (showDetailsProvider.sectionDetailModel.result?.isRent ?? 0) == 1) {
        if ((showDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
            (showDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) ==
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
      } else if ((showDetailsProvider.sectionDetailModel.result?.isPremium ??
              0) ==
          1) {
        if ((showDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1) {
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
      } else if ((showDetailsProvider.sectionDetailModel.result?.isRent ?? 0) ==
          1) {
        if ((showDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
            (showDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) ==
                1) {
          return true;
        } else {
          dynamic isRented = await Utils.paymentForRent(
            context: context,
            videoId:
                showDetailsProvider.sectionDetailModel.result?.id.toString() ??
                    '',
            rentPrice: showDetailsProvider.sectionDetailModel.result?.rentPrice
                    .toString() ??
                '',
            vTitle: showDetailsProvider.sectionDetailModel.result?.name
                    .toString() ??
                '',
            typeId: showDetailsProvider.sectionDetailModel.result?.typeId
                    .toString() ??
                '',
            vType: showDetailsProvider.sectionDetailModel.result?.videoType
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
