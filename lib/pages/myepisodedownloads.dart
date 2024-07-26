import 'dart:developer';
import 'dart:io';

import 'package:dtlive/model/downloadvideomodel.dart';
import 'package:dtlive/provider/showdetailsprovider.dart';
import 'package:dtlive/provider/showdownloadprovider.dart';
import 'package:dtlive/shimmer/shimmerutils.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:social_share/social_share.dart';

class MyEpisodeDownloads extends StatefulWidget {
  final int showId, videoType, typeId;
  const MyEpisodeDownloads(this.showId, this.videoType, this.typeId, {Key? key})
      : super(key: key);

  @override
  State<MyEpisodeDownloads> createState() => _MyEpisodeDownloadsState();
}

class _MyEpisodeDownloadsState extends State<MyEpisodeDownloads> {
  late ShowDownloadProvider downloadProvider;
  List<SessionItem>? mySeasonList;
  List<EpisodeItem>? myEpisodeList;

  @override
  void initState() {
    downloadProvider =
        Provider.of<ShowDownloadProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    super.initState();
  }

  _getData() async {
    mySeasonList =
        await downloadProvider.getDownloadedSeasons(widget.showId.toString());
    log("mySeasonList =================> ${mySeasonList?.length}");

    if ((mySeasonList?.length ?? 0) > 0) {
      await downloadProvider.setSelectedSeason(0);

      myEpisodeList = await downloadProvider.getDownloadedEpisodes(
          widget.showId.toString(), mySeasonList?[0].id.toString() ?? "");
      log("myEpisodeList =================> ${myEpisodeList?.length}");
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    downloadProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, "episodes", true),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              constraints: const BoxConstraints.expand(),
              padding:
                  EdgeInsets.only(top: (Dimens.homeTabHeight + 5), bottom: 10),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Consumer<ShowDownloadProvider>(
                  builder: (context, downloadProvider, child) {
                    if (downloadProvider.loading) {
                      return ShimmerUtils.buildDownloadShimmer(context, 10);
                    } else {
                      if (myEpisodeList != null) {
                        if ((myEpisodeList?.length ?? 0) > 0) {
                          return AlignedGridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 1,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 8,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myEpisodeList?.length ?? 0,
                            itemBuilder: (BuildContext context, int position) {
                              return _buildDownloadItem(position);
                            },
                          );
                        } else {
                          return const NoData(
                              title: 'no_downloads', subTitle: '');
                        }
                      } else {
                        return const NoData(
                            title: 'no_downloads', subTitle: '');
                      }
                    }
                  },
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: Dimens.homeTabHeight,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              color: black.withOpacity(0.8),
              child: _buildSeason(mySeasonList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeason(List<SessionItem>? seasonList) {
    return ListView.separated(
      itemCount: (seasonList?.length ?? 0),
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(13, 5, 13, 5),
      separatorBuilder: (context, index) => const SizedBox(width: 5),
      itemBuilder: (BuildContext context, int index) {
        return Consumer<ShowDownloadProvider>(
          builder: (context, showDownloadProvider, child) {
            return InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () async {
                debugPrint("index ===========> $index");
                myEpisodeList = [];
                await _getEpisodeBySeason(index, seasonList?[index].id ?? 0);
              },
              child: Container(
                constraints: const BoxConstraints(maxHeight: 32),
                decoration: Utils.setBackground(
                  showDownloadProvider.seasonClickIndex == index
                      ? white
                      : transparentColor,
                  20,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(13, 0, 13, 0),
                child: MyText(
                  color: showDownloadProvider.seasonClickIndex == index
                      ? black
                      : white,
                  multilanguage: false,
                  text: (seasonList?[index].name.toString() ?? ""),
                  fontsizeNormal: 12,
                  fontweight: FontWeight.w700,
                  fontsizeWeb: 14,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            );
          },
        );
      },
    );
  }

  _getEpisodeBySeason(int position, int seasonId) async {
    await downloadProvider.setSelectedSeason(position);
    myEpisodeList = await downloadProvider.getDownloadedEpisodes(
        widget.showId.toString(), seasonId.toString());
  }

  Widget _buildDownloadItem(position) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        minHeight: Dimens.heightWatchlist,
      ),
      color: lightBlack,
      child: Row(
        children: [
          Container(
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
                      openPlayer(position);
                    },
                    child: MyNetworkImage(
                      imageUrl: myEpisodeList?[position].landscape ?? "",
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                ((myEpisodeList?[position].videoType ?? 0) != 2)
                    ? _buildWatchBtn(position)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          Flexible(
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
                          text: myEpisodeList?[position].description ?? "",
                          textalign: TextAlign.start,
                          maxline: 2,
                          overflow: TextOverflow.ellipsis,
                          fontsizeNormal: 13,
                          fontweight: FontWeight.w600,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(height: 3),
                        /* Release Year & Video Duration */
                        (myEpisodeList?[position].videoDuration != null &&
                                (myEpisodeList?[position].videoDuration ?? 0) >
                                    0)
                            ? Container(
                                margin: const EdgeInsets.only(right: 20),
                                child: MyText(
                                  color: otherColor,
                                  text: Utils.convertInMin(
                                      myEpisodeList?[position].videoDuration ??
                                          0),
                                  textalign: TextAlign.start,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontsizeNormal: 12,
                                  fontweight: FontWeight.w500,
                                  fontstyle: FontStyle.normal,
                                ),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(height: 6),
                        /* Prime TAG  & Rent TAG */
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /* Prime TAG */
                            (myEpisodeList?[position].isPremium ?? 0) == 1
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
                            (myEpisodeList?[position].isRent ?? 0) == 1
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
          ),
        ],
      ),
    );
  }

  Widget _buildWatchBtn(position) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          openPlayer(position);
        },
        child: MyImage(
          width: 30,
          height: 30,
          imagePath: "play.png",
        ),
      ),
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
                    text: myEpisodeList?[position].description ?? "",
                    multilanguage: false,
                    fontsizeNormal: 16,
                    color: white,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w600,
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
                      (myEpisodeList?[position].videoType ?? 0) != 2
                          ? (myEpisodeList?[position].videoDuration != null &&
                                  (myEpisodeList?[position].videoDuration ??
                                          0) >
                                      0)
                              ? Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: MyText(
                                    color: otherColor,
                                    text: Utils.convertInMin(
                                        myEpisodeList?[position]
                                                .videoDuration ??
                                            0),
                                    textalign: TextAlign.center,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontsizeNormal: 12,
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
                      (myEpisodeList?[position].isPremium ?? 0) == 1
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
                      (myEpisodeList?[position].isRent ?? 0) == 1
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

                  /* Watch Now */
                  ((myEpisodeList?[position].videoType ?? 0) != 2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Navigator.pop(context);
                            openPlayer(position);
                          },
                          child: Container(
                            height: Dimens.minHtDialogContent,
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                MyImage(
                                  width: Dimens.dialogIconSize,
                                  height: Dimens.dialogIconSize,
                                  imagePath: "ic_play.png",
                                  fit: BoxFit.contain,
                                  color: otherColor,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: MyText(
                                    text: "watch_now",
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
                        )
                      : const SizedBox.shrink(),

                  /* Download Add/Delete */
                  ((myEpisodeList?[position].videoType ?? 0) != 2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            bool isDeleted =
                                await deleteFromDownloads(position);
                            log("isDeleted =============> $isDeleted");
                            if (isDeleted) {
                              if (!mounted) return;
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            height: Dimens.minHtDialogContent,
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                MyImage(
                                  width: Dimens.dialogIconSize,
                                  height: Dimens.dialogIconSize,
                                  imagePath:
                                      myEpisodeList?[position].isDownloaded == 1
                                          ? "ic_delete.png"
                                          : "ic_download.png",
                                  fit: BoxFit.contain,
                                  color: otherColor,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: MyText(
                                    text:
                                        myEpisodeList?[position].isDownloaded ==
                                                1
                                            ? "delete_download"
                                            : "download",
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
                        )
                      : const SizedBox.shrink(),

                  /* Video Share */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Navigator.pop(context);
                      _buildShareWithDialog(position);
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_share.png",
                            fit: BoxFit.contain,
                            color: otherColor,
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: MyText(
                              text: "share",
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

                  /* View Details */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      Navigator.pop(context);
                      log("Clicked on position :==> $position");
                      Utils.openDetails(
                        context: context,
                        videoId: widget.showId,
                        upcomingType: 0,
                        videoType: widget.videoType,
                        typeId: widget.typeId,
                      );
                    },
                    child: Container(
                      height: Dimens.minHtDialogContent,
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: Dimens.dialogIconSize,
                            height: Dimens.dialogIconSize,
                            imagePath: "ic_info.png",
                            fit: BoxFit.contain,
                            color: otherColor,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "view_details",
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

  Future<bool> deleteFromDownloads(position) async {
    final showDetailsProvider =
        Provider.of<ShowDetailsProvider>(context, listen: false);
    await downloadProvider.deleteEpisodeFromDownload(
      myEpisodeList?[position].id.toString() ?? "",
      widget.showId.toString(),
      mySeasonList?[downloadProvider.seasonClickIndex ?? 0].id.toString() ?? "",
    );
    log("myEpisodeList =========> ${myEpisodeList?.length}");
    myEpisodeList?.removeAt(position);
    if ((myEpisodeList?.length ?? 0) == 0) {
      if (!mounted) return false;
      await showDetailsProvider.setDownloadComplete(
        context,
        mySeasonList?[downloadProvider.seasonClickIndex ?? 0].id,
        widget.videoType,
        widget.typeId,
        widget.showId,
      );
    }
    setState(() {});
    return true;
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
                    text: myEpisodeList?[position].description ?? "",
                    multilanguage: false,
                    fontsizeNormal: 16,
                    color: white,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w600,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),

                  /* SMS */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Navigator.pop(context);
                      if (Platform.isAndroid) {
                        Utils.redirectToUrl(
                            'sms:?body=${Uri.encodeComponent("Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n")}');
                      } else if (Platform.isIOS) {
                        Utils.redirectToUrl(
                            'sms:&body=${Uri.encodeComponent("Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n")}');
                      }
                    },
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: 22,
                            height: 22,
                            imagePath: "ic_sms.png",
                            fit: BoxFit.fill,
                            color: lightGray,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "sms",
                              multilanguage: true,
                              fontsizeNormal: 16,
                              color: white,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w500,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* Instgram Stories */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Navigator.pop(context);
                      Utils.shareApp(Platform.isIOS
                          ? "Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
                    },
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: 22,
                            height: 22,
                            imagePath: "ic_insta.png",
                            fit: BoxFit.fill,
                            color: lightGray,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "instagram_stories",
                              multilanguage: true,
                              fontsizeNormal: 16,
                              color: white,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w500,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* Copy Link */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Navigator.pop(context);
                      SocialShare.copyToClipboard(
                        text: Platform.isIOS
                            ? "Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                            : "Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n",
                      ).then((data) {
                        debugPrint(data);
                        Utils.showSnackbar(
                            context, "success", "link_copied", true);
                      });
                    },
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: 22,
                            height: 22,
                            imagePath: "ic_link.png",
                            fit: BoxFit.fill,
                            color: lightGray,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "copy_link",
                              multilanguage: true,
                              fontsizeNormal: 16,
                              color: white,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w500,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* More */
                  InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Navigator.pop(context);
                      Utils.shareApp(Platform.isIOS
                          ? "Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${myEpisodeList?[position].description ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
                    },
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          MyImage(
                            width: 22,
                            height: 22,
                            imagePath: "ic_dots_h.png",
                            fit: BoxFit.fill,
                            color: lightGray,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MyText(
                              text: "more",
                              multilanguage: true,
                              fontsizeNormal: 16,
                              color: white,
                              fontstyle: FontStyle.normal,
                              fontweight: FontWeight.w500,
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

  openPlayer(position) async {
    Utils.openPlayer(
      context: context,
      playType: "Download",
      videoId: myEpisodeList?[position].id ?? 0,
      videoType: int.parse(myEpisodeList?[position].videoType.toString() ?? ""),
      typeId: 4,
      otherId: myEpisodeList?[position].showId ?? 0,
      videoUrl: myEpisodeList?[position].savedFile ?? "",
      trailerUrl: "",
      uploadType: myEpisodeList?[position].videoUploadType ?? "",
      videoThumb: myEpisodeList?[position].landscape ?? "",
      vStopTime: 0,
    );
  }
}
