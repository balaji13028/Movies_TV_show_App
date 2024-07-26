import 'dart:developer';
import 'package:dtlive/pages/moviedetails.dart';
import 'package:dtlive/pages/showdetails.dart';
import 'package:dtlive/provider/homeprovider.dart';
import 'package:dtlive/shimmer/shimmerutils.dart';
import 'package:dtlive/tvpages/tvshowdetails.dart';
import 'package:dtlive/webwidget/footerweb.dart';
import 'package:dtlive/widget/moredetails.dart';
import 'package:dtlive/widget/myusernetworkimg.dart';
import 'package:flutter/foundation.dart';

import 'package:dtlive/model/sectiondetailmodel.dart';
import 'package:dtlive/pages/castdetails.dart';
import 'package:dtlive/pages/loginsocial.dart';
import 'package:dtlive/subscription/subscription.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:dtlive/provider/videodetailsprovider.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/utils/strings.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class TVMovieDetails extends StatefulWidget {
  final int videoId, upcomingType, videoType, typeId;
  const TVMovieDetails(
      this.videoId, this.upcomingType, this.videoType, this.typeId,
      {Key? key})
      : super(key: key);

  @override
  State<TVMovieDetails> createState() => TVMovieDetailsState();
}

class TVMovieDetailsState extends State<TVMovieDetails> {
  String? audioLanguages;
  List<Cast>? directorList;
  late VideoDetailsProvider videoDetailsProvider;
  late HomeProvider homeProvider;
  Map<String, String> qualityUrlList = <String, String>{};

  @override
  void initState() {
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    videoDetailsProvider =
        Provider.of<VideoDetailsProvider>(context, listen: false);
    super.initState();
    log("initState videoId ==> ${widget.videoId}");
    log("initState videoType ==> ${widget.videoType}");
    log("initState typeId ==> ${widget.typeId}");
    _getData();
  }

  _getData() async {
    Utils.getCurrencySymbol();
    await videoDetailsProvider.getSectionDetails(
        widget.typeId, widget.videoType, widget.videoId, widget.upcomingType);

    if (videoDetailsProvider.sectionDetailModel.status == 200) {
      if (videoDetailsProvider.sectionDetailModel.result != null) {
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

  @override
  void dispose() {
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
    if (videoDetailsProvider.loading) {
      return SingleChildScrollView(
        child: ((kIsWeb || Constant.isTV) &&
                MediaQuery.of(context).size.width > 720)
            ? ShimmerUtils.buildDetailWebShimmer(context, "video")
            : ShimmerUtils.buildDetailMobileShimmer(context, "video"),
      );
    } else {
      if (videoDetailsProvider.sectionDetailModel.status == 200 &&
          videoDetailsProvider.sectionDetailModel.result != null) {
        if ((kIsWeb || Constant.isTV) &&
            MediaQuery.of(context).size.width > 720) {
          return _buildTVWebData();
        } else {
          return _buildMobileData();
        }
      } else {
        return const NoData(title: '', subTitle: '');
      }
    }
  }

  Widget _buildTVWebData() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            /* Poster */
            Container(
              constraints: BoxConstraints(
                minHeight: Dimens.detailWebPoster,
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Row(
                children: [
                  /* Details */
                  Expanded(
                    child: Container(
                      height: Dimens.detailWebPoster,
                      padding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!kIsWeb)
                            Container(
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                              child: InkWell(
                                autofocus: true,
                                focusColor: gray.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(25),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(8),
                                  child: MyImage(
                                    fit: BoxFit.contain,
                                    imagePath: "back.png",
                                  ),
                                ),
                              ),
                            ),

                          /* Small Poster, Main title, ReleaseYear, Duration, Age Restriction, Video Quality */
                          Expanded(
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              constraints: const BoxConstraints(minHeight: 0),
                              padding: const EdgeInsets.fromLTRB(
                                  0, kIsWeb ? 20 : 0, 10, 8),
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
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              child: MyText(
                                                color: whiteLight,
                                                text: videoDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.releaseYear ??
                                                    "",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 13,
                                                fontsizeWeb: 13,
                                                fontweight: FontWeight.w700,
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
                                              margin: const EdgeInsets.only(
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
                                                textalign: TextAlign.start,
                                                fontsizeNormal: 13,
                                                fontsizeWeb: 13,
                                                fontweight: FontWeight.w700,
                                                maxline: 1,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal,
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
                                                text: videoDetailsProvider
                                                        .sectionDetailModel
                                                        .result
                                                        ?.maxVideoQuality ??
                                                    "",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 10,
                                                fontsizeWeb: 12,
                                                fontweight: FontWeight.w700,
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

                                  /* Category */
                                  if (videoDetailsProvider.sectionDetailModel
                                              .result?.categoryName !=
                                          null &&
                                      videoDetailsProvider.sectionDetailModel
                                              .result?.categoryName !=
                                          "")
                                    Container(
                                      constraints:
                                          const BoxConstraints(minHeight: 0),
                                      margin: const EdgeInsets.only(top: 5),
                                      child: Row(
                                        children: [
                                          MyText(
                                            color: whiteLight,
                                            text: "category",
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 13,
                                            fontweight: FontWeight.w600,
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
                                              color: white,
                                              text: videoDetailsProvider
                                                      .sectionDetailModel
                                                      .result
                                                      ?.categoryName ??
                                                  "",
                                              textalign: TextAlign.start,
                                              fontsizeNormal: 13,
                                              fontsizeWeb: 13,
                                              fontweight: FontWeight.w600,
                                              multilanguage: false,
                                              maxline: 5,
                                              overflow: TextOverflow.ellipsis,
                                              fontstyle: FontStyle.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  /* Language */
                                  Container(
                                    constraints:
                                        const BoxConstraints(minHeight: 0),
                                    margin: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MyText(
                                          color: whiteLight,
                                          text: "language_",
                                          textalign: TextAlign.center,
                                          fontsizeNormal: 13,
                                          fontweight: FontWeight.w600,
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
                                            color: white,
                                            text: audioLanguages ?? "",
                                            textalign: TextAlign.start,
                                            fontsizeNormal: 13,
                                            fontweight: FontWeight.w600,
                                            fontsizeWeb: 13,
                                            multilanguage: false,
                                            maxline: 5,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  /* Subtitle */
                                  Constant.subtitleUrls.isNotEmpty
                                      ? Container(
                                          constraints: const BoxConstraints(
                                              minHeight: 0),
                                          margin: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              MyText(
                                                color: whiteLight,
                                                text: "subtitle",
                                                textalign: TextAlign.center,
                                                fontsizeNormal: 13,
                                                fontweight: FontWeight.w600,
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
                                                  color: white,
                                                  text: "Available",
                                                  textalign: TextAlign.start,
                                                  fontsizeNormal: 13,
                                                  fontweight: FontWeight.w600,
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
                                  (videoDetailsProvider.sectionDetailModel
                                                  .result?.isRent ??
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
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* Poster */
                  Container(
                    padding: const EdgeInsets.all(0),
                    height: Dimens.detailWebPoster,
                    width: MediaQuery.of(context).size.width *
                        Dimens.webBannerImgPr,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
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
                                transparentColor,
                                transparentColor,
                                transparentColor,
                                appBgColor,
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(0),
                          width: MediaQuery.of(context).size.width,
                          height: Dimens.detailWebPoster,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
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
              margin: const EdgeInsets.fromLTRB(20, 10, 0, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                    const SizedBox(width: 10),

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
                  ],
                ),
              ),
            ),

            /* Other Details */
            /* Related ~ More Details */
            Container(
              margin: (kIsWeb || Constant.isTV)
                  ? const EdgeInsets.fromLTRB(0, 10, 0, 0)
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

  Widget _buildMobileData() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            /* Poster */
            Stack(
              alignment: Alignment.center,
              children: [
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
                        ? (videoDetailsProvider
                                .sectionDetailModel.result?.landscape ??
                            "")
                        : (videoDetailsProvider
                                .sectionDetailModel.result?.thumbnail ??
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
            ),

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

                  /* WatchNow & Feature buttons */
                  Container(
                    alignment: Alignment.centerLeft,
                    constraints:
                        const BoxConstraints(minHeight: 0, minWidth: 0),
                    margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
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
                                text: "class",
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
            height: 55,
            constraints: BoxConstraints(
              maxWidth: (kIsWeb || Constant.isTV)
                  ? 190
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
              height: 60,
              constraints: BoxConstraints(
                maxWidth: (kIsWeb || Constant.isTV)
                    ? 220
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
                        const SizedBox(width: 10),
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
                                fontsizeWeb: 13,
                                fontweight: FontWeight.w700,
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
                        const SizedBox(width: 10),
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
              height: 55,
              constraints: BoxConstraints(
                maxWidth: (kIsWeb || Constant.isTV)
                    ? 190
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
        return InkWell(
          focusColor: gray.withOpacity(0.5),
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
                vType: videoDetailsProvider.sectionDetailModel.result?.videoType
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
        );
      }
    } else if ((videoDetailsProvider.sectionDetailModel.result?.isRent ?? 0) ==
        1) {
      if ((videoDetailsProvider.sectionDetailModel.result?.isBuy ?? 0) == 1 ||
          (videoDetailsProvider.sectionDetailModel.result?.rentBuy ?? 0) == 1) {
        return const SizedBox.shrink();
      } else {
        return InkWell(
          focusColor: gray.withOpacity(0.5),
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
                vType: videoDetailsProvider.sectionDetailModel.result?.videoType
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
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: (kIsWeb || Constant.isTV)
                ? (MediaQuery.of(context).size.width * 0.5)
                : MediaQuery.of(context).size.width,
          ),
          height: (kIsWeb || Constant.isTV) ? 35 : Dimens.detailTabs,
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* Related */
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: gray.withOpacity(0.5),
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
                                color: videoDetailsProvider.tabClickedOn !=
                                        "related"
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
              ),
              /* More Details */
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    focusColor: gray.withOpacity(0.5),
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
              ),
            ],
          ),
        ),
        Container(
          height: 0.5,
          color: otherColor,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
              if ((videoDetailsProvider
                          .sectionDetailModel.getRelatedVideo?.length ??
                      0) >
                  0)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  margin: const EdgeInsets.only(top: 25, bottom: 0),
                  child: MyText(
                    color: white,
                    text: "customer_also_watch",
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
              /* video_type =>  1-video,  2-show,  3-language,  4-category */
              /* screen_layout =>  landscape, potrait, square */
              if ((videoDetailsProvider
                          .sectionDetailModel.getRelatedVideo?.length ??
                      0) >
                  0)
                landscape(
                    videoDetailsProvider.sectionDetailModel.getRelatedVideo),

              /* Cast & Crew */
              if ((videoDetailsProvider.sectionDetailModel.cast?.length ?? 0) >
                  0)
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  margin: const EdgeInsets.only(top: 25, bottom: 0),
                  child: MyText(
                    color: white,
                    text: "castandcrew",
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
              if ((videoDetailsProvider.sectionDetailModel.cast?.length ?? 0) >
                  0)
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: MyText(
                          color: otherColor,
                          text: "detailsfrom",
                          multilanguage: true,
                          textalign: TextAlign.center,
                          fontsizeNormal: 12,
                          fontweight: FontWeight.w500,
                          fontsizeWeb: 14,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: otherColor,
                            width: .7,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          shape: BoxShape.rectangle,
                        ),
                        child: MyText(
                          color: otherColor,
                          text: "IMDb",
                          multilanguage: false,
                          textalign: TextAlign.center,
                          fontsizeNormal: 12,
                          fontweight: FontWeight.w700,
                          fontsizeWeb: 13,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              if ((videoDetailsProvider.sectionDetailModel.cast?.length ?? 0) >
                  0)
                _buildCAndCLayout(videoDetailsProvider.sectionDetailModel.cast),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 0.7,
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                color: primaryColor,
              ),

              /* Director */
              if ((directorList?.length ?? 0) > 0) _buildDirector(),
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

  Widget landscape(List<GetRelatedVideo>? relatedDataList) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightLand,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      margin: const EdgeInsets.only(top: 12),
      child: ListView.separated(
        itemCount: relatedDataList?.length ?? 0,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int index) {
          return Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              focusColor: white,
              onTap: () async {
                log("Clicked on index ==> $index");
                if ((relatedDataList?[index].videoType ?? 0) == 5) {
                  if ((relatedDataList?[index].upcomingType ?? 0) == 1) {
                    if (!(context.mounted)) return;
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (kIsWeb || Constant.isTV) {
                            return TVMovieDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          } else {
                            return MovieDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          }
                        },
                      ),
                    );
                  } else if ((relatedDataList?[index].upcomingType ?? 0) == 2) {
                    if (!(context.mounted)) return;
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (kIsWeb || Constant.isTV) {
                            return TVShowDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          } else {
                            return ShowDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          }
                        },
                      ),
                    );
                  }
                } else {
                  if ((relatedDataList?[index].videoType ?? 0) == 1) {
                    if (!(context.mounted)) return;
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (kIsWeb || Constant.isTV) {
                            return TVMovieDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          } else {
                            return MovieDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          }
                        },
                      ),
                    );
                  } else if ((relatedDataList?[index].videoType ?? 0) == 2) {
                    if (!(context.mounted)) return;
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (kIsWeb || Constant.isTV) {
                            return TVShowDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          } else {
                            return ShowDetails(
                              relatedDataList?[index].id ?? 0,
                              relatedDataList?[index].upcomingType ?? 0,
                              relatedDataList?[index].videoType ?? 0,
                              relatedDataList?[index].typeId ?? 0,
                            );
                          }
                        },
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: Dimens.widthLand,
                height: Dimens.heightLand,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: MyNetworkImage(
                    imageUrl:
                        relatedDataList?[index].landscape.toString() ?? "",
                    fit: BoxFit.cover,
                    imgHeight: MediaQuery.of(context).size.height,
                    imgWidth: MediaQuery.of(context).size.width,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCAndCLayout(List<Cast>? castList) {
    if (castList != null && castList.isNotEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        margin: const EdgeInsets.only(top: 12),
        child: ResponsiveGridList(
          minItemWidth: (kIsWeb || Constant.isTV)
              ? Dimens.widthCastWeb
              : Dimens.widthCast,
          verticalGridSpacing: 8,
          horizontalGridSpacing: 6,
          minItemsPerRow: 3,
          maxItemsPerRow: 6,
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: List.generate(
            castList.length,
            (position) {
              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  focusColor: white,
                  onTap: () {
                    log("Item Clicked! => $position");
                    if (kIsWeb || Constant.isTV) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CastDetails(
                            castID: castList[position].id.toString()),
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
                          width: MediaQuery.of(context).size.width,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(Dimens.cardRadius),
                            child: MyUserNetworkImage(
                              imageUrl: castList[position].image.toString(),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(0),
                          width: MediaQuery.of(context).size.width,
                          height: (kIsWeb || Constant.isTV)
                              ? Dimens.heightCastWeb
                              : Dimens.heightCast,
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
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: MyText(
                            multilanguage: false,
                            text: castList[position].name.toString(),
                            fontstyle: FontStyle.normal,
                            fontsizeNormal: 12,
                            fontweight: FontWeight.w600,
                            fontsizeWeb: 14,
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
              );
            },
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  /* Director */
  Widget _buildDirector() {
    if (directorList != null && (directorList?.length ?? 0) > 0) {
      return Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
            minHeight: (kIsWeb || Constant.isTV)
                ? Dimens.heightCastWeb
                : Dimens.heightCast),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        margin: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(Dimens.cardRadius),
                focusColor: white,
                onTap: () {
                  if (kIsWeb || Constant.isTV) return;
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
                          borderRadius:
                              BorderRadius.circular(Dimens.cardRadius),
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
                      Padding(
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
            ),
            const SizedBox(width: 15),
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
                    fontsizeNormal: 15,
                    fontweight: FontWeight.w700,
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
                    fontsizeNormal: 14,
                    fontweight: FontWeight.w600,
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
            width: (kIsWeb || Constant.isTV)
                ? Dimens.featureWebSize
                : Dimens.featureSize,
            height: (kIsWeb || Constant.isTV)
                ? Dimens.featureWebSize
                : Dimens.featureSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryLight,
              ),
              borderRadius: BorderRadius.circular(((kIsWeb || Constant.isTV)
                      ? Dimens.featureWebSize
                      : Dimens.featureSize) /
                  2),
            ),
            child: MyImage(
              width: (kIsWeb || Constant.isTV)
                  ? Dimens.featureIconWebSize
                  : Dimens.featureIconSize,
              height: (kIsWeb || Constant.isTV)
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
