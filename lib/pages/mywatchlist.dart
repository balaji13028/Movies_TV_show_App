import 'dart:developer';
import 'dart:io';

import 'package:dtlive/pages/loginsocial.dart';
import 'package:dtlive/provider/watchlistprovider.dart';
import 'package:dtlive/shimmer/shimmerutils.dart';
import 'package:dtlive/subscription/subscription.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:social_share/social_share.dart';

class MyWatchlist extends StatefulWidget {
  const MyWatchlist({Key? key}) : super(key: key);

  @override
  State<MyWatchlist> createState() => _MyWatchlistState();
}

class _MyWatchlistState extends State<MyWatchlist> {
  late WatchlistProvider watchlistProvider;

  @override
  void initState() {
    watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    _getData();
    super.initState();
  }

  _getData() async {
    await watchlistProvider.getWatchlist();
  }

  @override
  void dispose() {
    watchlistProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, "watchlist", true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Consumer<WatchlistProvider>(
              builder: (context, watchlistProvider, child) {
                if (watchlistProvider.loading) {
                  return ShimmerUtils.buildWatchlistShimmer(context, 10);
                } else {
                  if (watchlistProvider.watchlistModel.status == 200 &&
                      watchlistProvider.watchlistModel.result != null) {
                    if ((watchlistProvider.watchlistModel.result?.length ?? 0) >
                        0) {
                      return AlignedGridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 1,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            watchlistProvider.watchlistModel.result?.length ??
                                0,
                        itemBuilder: (BuildContext context, int position) {
                          return _buildWatchlistItem(position);
                        },
                      );
                    } else {
                      return const NoData(
                        title: 'browse_now_watch_later',
                        subTitle: 'watchlist_note',
                      );
                    }
                  } else {
                    return const NoData(
                      title: 'browse_now_watch_later',
                      subTitle: 'watchlist_note',
                    );
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistItem(position) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(minHeight: Dimens.heightWatchlist),
      color: lightBlack,
      child: Row(
        children: [
          _buildImage(position),
          _buildDetails(position),
        ],
      ),
    );
  }

  Widget _buildImage(int position) {
    return Container(
      constraints: BoxConstraints(
        minHeight: Dimens.heightWatchlist,
        maxWidth: MediaQuery.of(context).size.width * 0.44,
      ),
      child: Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: [
          Container(
            constraints: BoxConstraints(
              minHeight: Dimens.heightWatchlist,
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(0),
              onTap: () {
                log("Clicked on position ==> $position");
                Utils.openDetails(
                  context: context,
                  videoId:
                      watchlistProvider.watchlistModel.result?[position].id ??
                          0,
                  upcomingType: 0,
                  videoType: watchlistProvider
                          .watchlistModel.result?[position].videoType ??
                      0,
                  typeId: watchlistProvider
                          .watchlistModel.result?[position].typeId ??
                      0,
                );
              },
              child: MyNetworkImage(
                imageUrl: (watchlistProvider
                                .watchlistModel.result?[position].landscape ??
                            "")
                        .isNotEmpty
                    ? (watchlistProvider
                            .watchlistModel.result?[position].landscape ??
                        "")
                    : (watchlistProvider
                            .watchlistModel.result?[position].thumbnail ??
                        ""),
                fit: BoxFit.fill,
              ),
            ),
          ),
          ((watchlistProvider.watchlistModel.result?[position].videoType ??
                      0) !=
                  2)
              ? _buildWatchBtnWithProgress(position)
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildDetails(int position) {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          minHeight: Dimens.heightWatchlist,
          maxWidth: MediaQuery.of(context).size.width * 0.66,
        ),
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /* Title */
                  MyText(
                    color: white,
                    text: watchlistProvider
                            .watchlistModel.result?[position].name ??
                        "",
                    textalign: TextAlign.start,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    fontsizeNormal: 13,
                    fontweight: FontWeight.w600,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 3),
                  /* Release Year & Video Duration */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      (watchlistProvider.watchlistModel.result?[position]
                                      .releaseYear !=
                                  null &&
                              (watchlistProvider.watchlistModel
                                          .result?[position].releaseYear ??
                                      "") !=
                                  "")
                          ? Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: MyText(
                                color: otherColor,
                                text: watchlistProvider.watchlistModel
                                        .result?[position].releaseYear ??
                                    "",
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.start,
                                fontsizeNormal: 12,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            )
                          : const SizedBox.shrink(),
                      (watchlistProvider.watchlistModel.result?[position]
                                      .videoType ??
                                  0) !=
                              2
                          ? (watchlistProvider.watchlistModel.result?[position]
                                          .videoDuration !=
                                      null &&
                                  (watchlistProvider
                                              .watchlistModel
                                              .result?[position]
                                              .videoDuration ??
                                          0) >
                                      0)
                              ? Container(
                                  margin: const EdgeInsets.only(right: 20),
                                  child: MyText(
                                    color: otherColor,
                                    text: Utils.convertInMin(watchlistProvider
                                            .watchlistModel
                                            .result?[position]
                                            .videoDuration ??
                                        0),
                                    textalign: TextAlign.start,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontsizeNormal: 12,
                                    fontweight: FontWeight.w500,
                                    fontstyle: FontStyle.normal,
                                  ),
                                )
                              : const SizedBox.shrink()
                          : const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  /* Prime TAG  & Rent TAG */
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* Prime TAG */
                      (watchlistProvider.watchlistModel.result?[position]
                                      .isPremium ??
                                  0) ==
                              1
                          ? MyText(
                              color: primaryColor,
                              text: "primetag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 10,
                              fontweight: FontWeight.w800,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 3),
                      /* Rent TAG */
                      (watchlistProvider.watchlistModel.result?[position]
                                      .isRent ??
                                  0) ==
                              1
                          ? MyText(
                              color: white,
                              text: "renttag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 11,
                              fontweight: FontWeight.w500,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: InkWell(
                onTap: () {
                  _buildVideoMoreDialog(position);
                },
                child: Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  child: MyImage(
                    width: 18,
                    height: 18,
                    imagePath: "ic_more.png",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchBtnWithProgress(position) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 5),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              openPlayer("Video", position);
            },
            child: MyImage(
              width: 30,
              height: 30,
              imagePath: "play.png",
            ),
          ),
        ),
        ((watchlistProvider.watchlistModel.result?[position].videoDuration) !=
                    null &&
                (watchlistProvider.watchlistModel.result?[position].stopTime ??
                        0) >
                    0)
            ? Container(
                constraints: const BoxConstraints(minWidth: 0),
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(3),
                child: LinearPercentIndicator(
                  padding: const EdgeInsets.all(0),
                  barRadius: const Radius.circular(2),
                  lineHeight: 4,
                  percent: Utils.getPercentage(
                      watchlistProvider
                              .watchlistModel.result?[position].videoDuration ??
                          0,
                      watchlistProvider
                              .watchlistModel.result?[position].stopTime ??
                          0),
                  backgroundColor: secProgressColor,
                  progressColor: primaryColor,
                ),
              )
            : const SizedBox.shrink(),
        (watchlistProvider.watchlistModel.result?[position].releaseTag !=
                    null &&
                (watchlistProvider
                            .watchlistModel.result?[position].releaseTag ??
                        "")
                    .isNotEmpty)
            ? Container(
                decoration: const BoxDecoration(
                  color: black,
                  shape: BoxShape.rectangle,
                ),
                width: 172,
                height: 12,
                child: MyText(
                  color: white,
                  text: watchlistProvider
                          .watchlistModel.result?[position].releaseTag ??
                      "",
                  textalign: TextAlign.center,
                  fontsizeNormal: 6,
                  maxline: 1,
                  fontweight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  _buildVideoMoreDialog(position) {
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
                  /* Title */
                  MyText(
                    text: watchlistProvider
                            .watchlistModel.result?[position].name ??
                        "",
                    multilanguage: false,
                    fontsizeNormal: 18,
                    fontsizeWeb: 20,
                    color: white,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w700,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 5),
                  /* Release year, Video duration & Comment Icon */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      (watchlistProvider.watchlistModel.result?[position]
                                      .releaseYear ??
                                  "")
                              .isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: MyText(
                                color: otherColor,
                                text: watchlistProvider.watchlistModel
                                        .result?[position].releaseYear ??
                                    "",
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.center,
                                fontsizeNormal: 12,
                                fontsizeWeb: 13,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            )
                          : const SizedBox.shrink(),
                      (watchlistProvider.watchlistModel.result?[position]
                                      .videoType ??
                                  0) !=
                              2
                          ? (watchlistProvider.watchlistModel.result?[position]
                                          .videoDuration !=
                                      null &&
                                  (watchlistProvider
                                              .watchlistModel
                                              .result?[position]
                                              .videoDuration ??
                                          0) >
                                      0)
                              ? Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: MyText(
                                    color: otherColor,
                                    text: Utils.convertInMin(watchlistProvider
                                            .watchlistModel
                                            .result?[position]
                                            .videoDuration ??
                                        0),
                                    textalign: TextAlign.center,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontsizeNormal: 12,
                                    fontsizeWeb: 13,
                                    fontweight: FontWeight.w500,
                                    fontstyle: FontStyle.normal,
                                  ),
                                )
                              : const SizedBox.shrink()
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
                  const SizedBox(height: 8),
                  /* Prime TAG  & Rent TAG */
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* Prime TAG */
                      (watchlistProvider.watchlistModel.result?[position]
                                      .isPremium ??
                                  0) ==
                              1
                          ? MyText(
                              color: primaryColor,
                              text: "primetag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 12,
                              fontweight: FontWeight.w800,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 5),
                      /* Rent TAG */
                      (watchlistProvider.watchlistModel.result?[position]
                                      .isRent ??
                                  0) ==
                              1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: complimentryColor,
                                    borderRadius: BorderRadius.circular(10),
                                    shape: BoxShape.rectangle,
                                  ),
                                  margin: const EdgeInsets.only(right: 5),
                                  alignment: Alignment.center,
                                  child: MyText(
                                    color: white,
                                    text: Constant.currencySymbol,
                                    textalign: TextAlign.center,
                                    fontsizeNormal: 10,
                                    multilanguage: false,
                                    fontweight: FontWeight.w800,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal,
                                  ),
                                ),
                                MyText(
                                  color: white,
                                  text: "renttag",
                                  multilanguage: true,
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 12,
                                  fontweight: FontWeight.w500,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /* Watch Now / Resume */
                  ((watchlistProvider
                                  .watchlistModel.result?[position].videoType ??
                              0) !=
                          2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Navigator.pop(context);
                            openPlayer("Video", position);
                          },
                          child: _buildDialogItems(
                            icon: (watchlistProvider.watchlistModel
                                            .result?[position].stopTime ??
                                        0) >
                                    0
                                ? "ic_resume.png"
                                : "ic_play.png",
                            title: (watchlistProvider.watchlistModel
                                            .result?[position].stopTime ??
                                        0) >
                                    0
                                ? "resume"
                                : "watch_now",
                            isMultilang: true,
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Start Over */
                  ((watchlistProvider.watchlistModel.result?[position]
                                      .stopTime ??
                                  0) >
                              0 &&
                          (watchlistProvider.watchlistModel.result?[position]
                                      .videoType ??
                                  0) !=
                              2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Navigator.pop(context);
                            openPlayer("startOver", position);
                          },
                          child: _buildDialogItems(
                            icon: "ic_restart.png",
                            title: "startover",
                            isMultilang: true,
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Watch Trailer */
                  ((watchlistProvider
                                  .watchlistModel.result?[position].videoType ??
                              0) !=
                          2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Navigator.pop(context);
                            await Utils.openPlayer(
                                context: context,
                                playType: "Trailer",
                                videoId: watchlistProvider.watchlistModel.result?[position].id ??
                                    0,
                                videoType: watchlistProvider.watchlistModel
                                        .result?[position].videoType ??
                                    0,
                                typeId: watchlistProvider.watchlistModel
                                        .result?[position].typeId ??
                                    0,
                                otherId: 0,
                                videoUrl: "",
                                trailerUrl: watchlistProvider.watchlistModel
                                        .result?[position].trailerUrl ??
                                    "",
                                uploadType: watchlistProvider.watchlistModel
                                        .result?[position].trailerType ??
                                    "",
                                videoThumb: watchlistProvider.watchlistModel
                                        .result?[position].landscape ??
                                    "",
                                vStopTime: 0);
                          },
                          child: _buildDialogItems(
                            icon: "ic_borderplay.png",
                            title: "watch_trailer",
                            isMultilang: true,
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Add to Watchlist / Remove from Watchlist */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Navigator.pop(context);
                      log("isBookmark ====> ${watchlistProvider.watchlistModel.result?[position].isBookmark ?? 0}");
                      if (Constant.userID != null) {
                        await watchlistProvider.setBookMark(
                          context,
                          position,
                          watchlistProvider
                                  .watchlistModel.result?[position].typeId ??
                              0,
                          watchlistProvider
                                  .watchlistModel.result?[position].videoType ??
                              0,
                          watchlistProvider
                                  .watchlistModel.result?[position].id ??
                              0,
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
                    child: _buildDialogItems(
                      icon: ((watchlistProvider.watchlistModel.result?[position]
                                      .isBookmark ??
                                  0) ==
                              1)
                          ? "watchlist_remove.png"
                          : "ic_plus.png",
                      title: ((watchlistProvider.watchlistModel
                                      .result?[position].isBookmark ??
                                  0) ==
                              1)
                          ? "remove_from_watchlist"
                          : "add_to_watchlist",
                      isMultilang: true,
                    ),
                  ),

                  /* Download Add/Delete */
                  // ((watchlistProvider
                  //                 .watchlistModel.result?[position].videoType ??
                  //             0) !=
                  //         2)
                  //     ? InkWell(
                  //         borderRadius: BorderRadius.circular(5),
                  //         onTap: () async {
                  //           Navigator.pop(context);
                  //         },
                  //         child: _buildDialogItems(
                  //           icon: "ic_download.png",
                  //           title: "download",
                  //           isMultilang: true,
                  //         ),
                  //       )
                  //     : const SizedBox.shrink(),

                  /* Video Share */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Navigator.pop(context);
                      _buildShareWithDialog(position);
                    },
                    child: _buildDialogItems(
                      icon: "ic_share.png",
                      title: "share",
                      isMultilang: true,
                    ),
                  ),

                  /* View Details */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Navigator.pop(context);
                      log("Clicked on position :==> $position");
                      Utils.openDetails(
                        context: context,
                        videoId: watchlistProvider
                                .watchlistModel.result?[position].id ??
                            0,
                        upcomingType: 0,
                        videoType: watchlistProvider
                                .watchlistModel.result?[position].videoType ??
                            0,
                        typeId: watchlistProvider
                                .watchlistModel.result?[position].typeId ??
                            0,
                      );
                    },
                    child: _buildDialogItems(
                      icon: "ic_info.png",
                      title: "view_details",
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

  _buildShareWithDialog(position) {
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
                    text: watchlistProvider
                            .watchlistModel.result?[position].name ??
                        "",
                    multilanguage: false,
                    fontsizeNormal: 18,
                    fontsizeWeb: 20,
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
                      (watchlistProvider.watchlistModel.result?[position]
                                      .ageRestriction ??
                                  "")
                              .isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: Utils.setBGWithBorder(
                                  transparentColor, otherColor, 3, 0.7),
                              child: MyText(
                                text: watchlistProvider.watchlistModel
                                        .result?[position].ageRestriction ??
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
                            'sms:?body=${Uri.encodeComponent("Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n")}');
                      } else if (Platform.isIOS) {
                        Utils.redirectToUrl(
                            'sms:&body=${Uri.encodeComponent("Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n")}');
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
                          ? "Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
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
                            ? "Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                            : "Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n",
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
                          ? "Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${watchlistProvider.watchlistModel.result?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
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

  /* ========= Open Player ========= */
  openPlayer(playType, position) async {
    /* CHECK SUBSCRIPTION */
    if (playType != "Trailer") {
      bool? isPrimiumUser = await _checkSubsRentLogin(position);
      log("isPrimiumUser =============> $isPrimiumUser");
      if (!isPrimiumUser) return;
    }
    /* CHECK SUBSCRIPTION */

    /* Set-up Quality URLs */
    Utils.setQualityURLs(
      video320:
          (watchlistProvider.watchlistModel.result?[position].video320 ?? ""),
      video480:
          (watchlistProvider.watchlistModel.result?[position].video480 ?? ""),
      video720:
          (watchlistProvider.watchlistModel.result?[position].video720 ?? ""),
      video1080:
          (watchlistProvider.watchlistModel.result?[position].video1080 ?? ""),
    );

    /* Set-up Subtitle URLs */
    Utils.setSubtitleURLs(
      subtitleUrl1:
          (watchlistProvider.watchlistModel.result?[position].subtitle1 ?? ""),
      subtitleUrl2:
          (watchlistProvider.watchlistModel.result?[position].subtitle2 ?? ""),
      subtitleUrl3:
          (watchlistProvider.watchlistModel.result?[position].subtitle3 ?? ""),
      subtitleLang1:
          (watchlistProvider.watchlistModel.result?[position].subtitleLang1 ??
              ""),
      subtitleLang2:
          (watchlistProvider.watchlistModel.result?[position].subtitleLang2 ??
              ""),
      subtitleLang3:
          (watchlistProvider.watchlistModel.result?[position].subtitleLang3 ??
              ""),
    );

    if (!mounted) return;
    var isContinues = await Utils.openPlayer(
        context: context,
        playType: playType ?? "",
        videoId: watchlistProvider.watchlistModel.result?[position].id ?? 0,
        videoType:
            watchlistProvider.watchlistModel.result?[position].videoType ?? 0,
        typeId: watchlistProvider.watchlistModel.result?[position].typeId ?? 0,
        otherId: 0,
        videoUrl:
            watchlistProvider.watchlistModel.result?[position].video320 ?? "",
        trailerUrl:
            watchlistProvider.watchlistModel.result?[position].trailerUrl ?? "",
        uploadType: watchlistProvider
                .watchlistModel.result?[position].videoUploadType ??
            "",
        videoThumb:
            watchlistProvider.watchlistModel.result?[position].landscape ?? "",
        vStopTime:
            watchlistProvider.watchlistModel.result?[position].stopTime ?? 0);
    if (isContinues != null && isContinues == true) {
      await watchlistProvider.getWatchlist();
    }
  }
  /* ========= Open Player ========= */

  Future<bool> _checkSubsRentLogin(position) async {
    if (Constant.userID != null) {
      if ((watchlistProvider.watchlistModel.result?[position].isPremium ?? 0) ==
              1 &&
          (watchlistProvider.watchlistModel.result?[position].isRent ?? 0) ==
              1) {
        if ((watchlistProvider.watchlistModel.result?[position].isBuy ?? 0) ==
                1 ||
            (watchlistProvider.watchlistModel.result?[position].rentBuy ?? 0) ==
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
      } else if ((watchlistProvider
                  .watchlistModel.result?[position].isPremium ??
              0) ==
          1) {
        if ((watchlistProvider.watchlistModel.result?[position].isBuy ?? 0) ==
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
      } else if ((watchlistProvider.watchlistModel.result?[position].isRent ??
              0) ==
          1) {
        if ((watchlistProvider.watchlistModel.result?[position].isBuy ?? 0) ==
                1 ||
            (watchlistProvider.watchlistModel.result?[position].rentBuy ?? 0) ==
                1) {
          return true;
        } else {
          dynamic isRented = await Utils.paymentForRent(
            context: context,
            videoId: watchlistProvider.watchlistModel.result?[position].id
                    .toString() ??
                '',
            rentPrice: watchlistProvider
                    .watchlistModel.result?[position].rentPrice
                    .toString() ??
                '',
            vTitle: watchlistProvider.watchlistModel.result?[position].name
                    .toString() ??
                '',
            typeId: watchlistProvider.watchlistModel.result?[position].typeId
                    .toString() ??
                '',
            vType: watchlistProvider.watchlistModel.result?[position].videoType
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
