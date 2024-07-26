import 'dart:developer';
import 'dart:io';

import 'package:dtlive/model/downloadvideomodel.dart';
import 'package:dtlive/pages/myepisodedownloads.dart';
import 'package:dtlive/provider/videodownloadprovider.dart';
import 'package:dtlive/provider/videodetailsprovider.dart';
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

class MyDownloads extends StatefulWidget {
  const MyDownloads({Key? key}) : super(key: key);

  @override
  State<MyDownloads> createState() => _MyDownloadsState();
}

class _MyDownloadsState extends State<MyDownloads> {
  late VideoDownloadProvider downloadProvider;
  List<DownloadVideoModel>? myDownloadsList;

  @override
  void initState() {
    downloadProvider =
        Provider.of<VideoDownloadProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    super.initState();
  }

  _getData() async {
    List<DownloadVideoModel>? myVideoDownloadsList =
        await downloadProvider.getDownloadsByType("video");
    List<DownloadVideoModel>? myShowDownloadsList =
        await downloadProvider.getDownloadsByType("show");
    myDownloadsList = [];
    myDownloadsList =
        (myVideoDownloadsList ?? []) + (myShowDownloadsList ?? []);
    log("myDownloadsList =================> ${myDownloadsList?.length}");
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
      appBar: Utils.myAppBarWithBack(context, "downloads", true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Consumer<VideoDownloadProvider>(
              builder: (context, downloadProvider, child) {
                if (downloadProvider.loading) {
                  return ShimmerUtils.buildDownloadShimmer(context, 10);
                } else {
                  if (myDownloadsList != null) {
                    if ((myDownloadsList?.length ?? 0) > 0) {
                      return AlignedGridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 1,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myDownloadsList?.length ?? 0,
                        itemBuilder: (BuildContext context, int position) {
                          return _buildDownloadItem(position);
                        },
                      );
                    } else {
                      return const NoData(title: 'no_downloads', subTitle: '');
                    }
                  } else {
                    return const NoData(title: 'no_downloads', subTitle: '');
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
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
                    onTap: () async {
                      log("Clicked on position ==> $position");
                      if ((myDownloadsList?[position].videoType ?? 0) != 2) {
                        openPlayer(position);
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return MyEpisodeDownloads(
                                myDownloadsList?[position].id ?? 0,
                                myDownloadsList?[position].videoType ?? 0,
                                myDownloadsList?[position].typeId ?? 0,
                              );
                            },
                          ),
                        );
                        _getData();
                      }
                    },
                    child: MyNetworkImage(
                      imageUrl: myDownloadsList?[position].landscapeImg ?? "",
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                ((myDownloadsList?[position].videoType ?? 0) != 2)
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
                          text: myDownloadsList?[position].name ?? "",
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
                            (myDownloadsList?[position].releaseYear != null &&
                                    (myDownloadsList?[position].releaseYear ??
                                            "") !=
                                        "")
                                ? Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: MyText(
                                      color: otherColor,
                                      text: myDownloadsList?[position]
                                              .releaseYear ??
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
                            (myDownloadsList?[position].videoType ?? 0) != 2
                                ? (myDownloadsList?[position].videoDuration !=
                                            null &&
                                        (myDownloadsList?[position]
                                                    .videoDuration ??
                                                0) >
                                            0)
                                    ? Container(
                                        margin:
                                            const EdgeInsets.only(right: 20),
                                        child: MyText(
                                          color: otherColor,
                                          text: Utils.convertInMin(
                                              myDownloadsList?[position]
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
                            (myDownloadsList?[position].isPremium ?? 0) == 1
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
                            (myDownloadsList?[position].isRent ?? 0) == 1
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
                      onTap: () async {
                        if ((myDownloadsList?[position].videoType ?? 0) != 2) {
                          _buildVideoMoreDialog(position);
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return MyEpisodeDownloads(
                                  myDownloadsList?[position].id ?? 0,
                                  myDownloadsList?[position].videoType ?? 0,
                                  myDownloadsList?[position].typeId ?? 0,
                                );
                              },
                            ),
                          );
                          _getData();
                        }
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(6),
                        child: MyImage(
                          width: 18,
                          height: 18,
                          imagePath:
                              ((myDownloadsList?[position].videoType ?? 0) != 2)
                                  ? "ic_more.png"
                                  : "ic_right.png",
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
                    text: myDownloadsList?[position].name ?? "",
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
                  /* Release year, Video duration & Comment Icon */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      (myDownloadsList?[position].releaseYear ?? "").isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: MyText(
                                color: otherColor,
                                text: myDownloadsList?[position].releaseYear ??
                                    "",
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                textalign: TextAlign.center,
                                fontsizeNormal: 12,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            )
                          : const SizedBox.shrink(),
                      (myDownloadsList?[position].videoType ?? 0) != 2
                          ? (myDownloadsList?[position].videoDuration != null &&
                                  (myDownloadsList?[position].videoDuration ??
                                          0) >
                                      0)
                              ? Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: MyText(
                                    color: otherColor,
                                    text: Utils.convertInMin(
                                        myDownloadsList?[position]
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
                      (myDownloadsList?[position].isPremium ?? 0) == 1
                          ? MyText(
                              color: primaryColor,
                              text: "primetag",
                              multilanguage: true,
                              textalign: TextAlign.start,
                              fontsizeNormal: 12,
                              fontsizeWeb: 13,
                              fontweight: FontWeight.w800,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 5),
                      /* Rent TAG */
                      (myDownloadsList?[position].isRent ?? 0) == 1
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
                                    fontsizeWeb: 12,
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
                                  fontsizeWeb: 13,
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
                  ((myDownloadsList?[position].videoType ?? 0) != 2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Navigator.pop(context);
                            openPlayer(position);
                          },
                          child: _buildDialogItems(
                            icon: "ic_play.png",
                            title: "watch_now",
                            isMultilang: true,
                          ),
                        )
                      : const SizedBox.shrink(),

                  /* Watch Trailer */
                  ((myDownloadsList?[position].videoType ?? 0) != 2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            Navigator.pop(context);
                            await Utils.openPlayer(
                                context: context,
                                playType: "Trailer",
                                videoId: myDownloadsList?[position].id ?? 0,
                                videoType:
                                    myDownloadsList?[position].videoType ?? 0,
                                typeId: myDownloadsList?[position].typeId ?? 0,
                                otherId: 0,
                                videoUrl: "",
                                trailerUrl:
                                    myDownloadsList?[position].trailerUrl ?? "",
                                uploadType: myDownloadsList?[position]
                                        .trailerUploadType ??
                                    "",
                                videoThumb:
                                    myDownloadsList?[position].landscapeImg ??
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

                  /* Download Add/Delete */
                  ((myDownloadsList?[position].videoType ?? 0) != 2)
                      ? InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            log("Clicked on position =============> $position");
                            bool isDeleted =
                                await deleteFromDownloads(position);
                            log("isDeleted =============> $isDeleted");
                            if (isDeleted) {
                              if (!mounted) return;
                              Navigator.pop(context);
                            }
                          },
                          child: _buildDialogItems(
                            icon: myDownloadsList?[position].isDownload == 1
                                ? "ic_delete.png"
                                : "ic_download.png",
                            title: myDownloadsList?[position].isDownload == 1
                                ? "delete_download"
                                : "download",
                            isMultilang: true,
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
                        videoId: myDownloadsList?[position].id ?? 0,
                        upcomingType: 0,
                        videoType: myDownloadsList?[position].videoType ?? 0,
                        typeId: myDownloadsList?[position].typeId ?? 0,
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

  Future<bool> deleteFromDownloads(position) async {
    final videoDetailsProvider =
        Provider.of<VideoDetailsProvider>(context, listen: false);
    downloadProvider.deleteVideoFromDownload(
        myDownloadsList?[position].id.toString() ?? "");
    await videoDetailsProvider.setDownloadComplete(
        context,
        myDownloadsList?[position].id,
        myDownloadsList?[position].videoType,
        myDownloadsList?[position].typeId);
    myDownloadsList?.removeAt(position);
    setState(() {});
    return true;
  }

  _buildShareWithDialog(position) {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(0),
        ),
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
                    text: myDownloadsList?[position].name ?? "",
                    multilanguage: false,
                    fontsizeNormal: 18,
                    color: white,
                    fontstyle: FontStyle.normal,
                    fontweight: FontWeight.w700,
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
                            'sms:?body=${Uri.encodeComponent("Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n")}');
                      } else if (Platform.isIOS) {
                        Utils.redirectToUrl(
                            'sms:&body=${Uri.encodeComponent("Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n")}');
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
                          ? "Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
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
                            ? "Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                            : "Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n",
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
                          ? "Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName?.toLowerCase()}/${Constant.appPackageName} \n"
                          : "Hey! I'm watching ${myDownloadsList?[position].name ?? ""}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
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

  openPlayer(position) async {
    Utils.openPlayer(
      context: context,
      playType: "Download",
      videoId: myDownloadsList?[position].id ?? 0,
      videoType: myDownloadsList?[position].videoType ?? 0,
      typeId: myDownloadsList?[position].typeId ?? 0,
      otherId: 0,
      videoUrl: myDownloadsList?[position].savedFile ?? "",
      trailerUrl: myDownloadsList?[position].trailerUrl ?? "",
      uploadType: myDownloadsList?[position].videoUploadType ?? "",
      videoThumb: myDownloadsList?[position].landscapeImg ?? "",
      vStopTime: 0,
    );
  }
}
