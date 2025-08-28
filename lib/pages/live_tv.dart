import 'dart:io';
import 'dart:math';

import 'package:media9/model/live_tv_model.dart';
import 'package:media9/pages/livetv_player.dart';
import 'package:media9/provider/adventisements_provider.dart';
import 'package:media9/provider/livetv_provider.dart';
import 'package:media9/shimmer/shimmerwidget.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/dimens.dart';
import 'package:media9/utils/utils.dart';
import 'package:media9/webwidget/commonappbar.dart';
import 'package:media9/widget/mynetworkimg.dart';
import 'package:media9/widget/nodata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../provider/findprovider.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class LiveTv extends StatefulWidget {
  const LiveTv({super.key});

  @override
  State<LiveTv> createState() => _LiveTvState();
}

class _LiveTvState extends State<LiveTv> {
  late LivetvProvider livetvprovider;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _getData() async {
    livetvprovider = Provider.of<LivetvProvider>(context, listen: false);
    if (livetvprovider.liveTvList.isEmpty) {
      await livetvprovider.getTvShowsList();
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
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: (kIsWeb || Constant.isTV)
          ? null
          : Utils.myAppBar(context, "Live Tv", false),
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: livetvprovider.onRefresh,
        child: Stack(
          children: [
            Column(
              children: [
                Visibility(
                  visible: (kIsWeb || Constant.isTV) ? true : false,
                  child: SizedBox(height: Dimens.homeTabHeight),
                ),
                Visibility(
                  visible: (kIsWeb || Constant.isTV) ? false : true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      searchBox(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Consumer<LivetvProvider>(
                      builder: (context, provider, child) {
                        if (provider.loading) {
                          return AlignedGridView.count(
                              shrinkWrap: true,
                              crossAxisCount: ((kIsWeb || Constant.isTV) &&
                                      MediaQuery.of(context).size.width > 700)
                                  ? 5
                                  : 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              itemCount: 25,
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, top: 0),
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder:
                                  (BuildContext context, int position) {
                                return ShimmerWidget.roundrectborder(
                                  height: (kIsWeb || Constant.isTV) &&
                                          MediaQuery.of(context).size.width >
                                              700
                                      ? MediaQuery.of(context).size.width * 0.11
                                      : (kIsWeb || Constant.isTV)
                                          ? MediaQuery.of(context).size.height *
                                              0.15
                                          : MediaQuery.of(context).size.height *
                                              0.125,
                                  width: MediaQuery.of(context).size.width,
                                  shimmerBgColor: shimmerItemColor,
                                  shapeBorder: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5))),
                                );
                              });
                        } else if (provider.liveTvList.isEmpty) {
                          return const NoData(title: '', subTitle: '');
                        }
                        return livetvprovider.searchController.text.isNotEmpty
                            ? Column(
                                children: [
                                  if (provider.searchTvList.isNotEmpty) ...[
                                    if (kIsWeb) ...[
                                      liveTvWidget(provider.searchTvList
                                          .where((item) => item.website == 1)
                                          .toList()),
                                    ] else if (Constant.isTV) ...[
                                      liveTvWidget(provider.searchTvList
                                          .where((item) => item.smartTv == 1)
                                          .toList()),
                                    ] else if (Platform.isAndroid ||
                                        Platform.isIOS) ...[
                                      liveTvWidget(provider.searchTvList
                                          .where((item) => item.mobile == 1)
                                          .toList()),
                                    ] else ...[
                                      liveTvWidget(provider.searchTvList),
                                    ],
                                    /* Browse by END */
                                    const SizedBox(height: 22),
                                  ] else ...[
                                    const NoData(title: '', subTitle: ''),
                                  ]
                                ],
                              )
                            : Column(
                                children: [
                                  if (kIsWeb) ...[
                                    liveTvWidget(provider.liveTvList
                                        .where((item) => item.website == 1)
                                        .toList()),
                                  ] else if (Constant.isTV) ...[
                                    liveTvWidget(provider.liveTvList
                                        .where((item) => item.smartTv == 1)
                                        .toList()),
                                  ] else if (Platform.isAndroid ||
                                      Platform.isIOS) ...[
                                    liveTvWidget(provider.liveTvList
                                        .where((item) => item.mobile == 1)
                                        .toList()),
                                  ] else ...[
                                    liveTvWidget(provider.liveTvList),
                                  ],
                                  /* Browse by END */
                                  const SizedBox(height: 22),
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: (kIsWeb || Constant.isTV) ? true : false,
              child: const CommonAppBar(),
            )
          ],
        ),
      )),
    );
    // }
  }

  Widget searchBox() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      decoration: BoxDecoration(
        color: primaryDarkColor,
        border: Border.all(
          color: primaryLight,
          width: 0.5,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            child: MyImage(
              width: 20,
              height: 20,
              imagePath: "ic_find.png",
              color: white,
            ),
          ),
          Expanded(
            child: Container(
              // padding: EdgeInsets.only(right: 5),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: TextField(
                // onSubmitted: (value) async {
                //   if (value.isNotEmpty) {
                //     await Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) {
                //           return Search(
                //             searchText: value.toString(),
                //           );
                //         },
                //       ),
                //     );
                //     setState(() {
                //       searchController.clear();
                //     });
                //   }
                // },
                onTapOutside: (v){
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                onChanged: (value) async {
                  livetvprovider.filterLiveTvData(value);
                },
                textInputAction: TextInputAction.done,
                obscureText: false,
                controller: livetvprovider.searchController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                style: const TextStyle(
                  color: white,
                  fontSize: 15,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintStyle: TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: 'Search by name or channel no...',
                ),
              ),
            ),
          ),
          Consumer<LivetvProvider>(
            builder: (context, findProvider, child) {
              if (findProvider.searchController.text.toString().isNotEmpty) {
                return InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () async {
                    debugPrint("Click on Clear!");
                    findProvider.searchController.clear();
                    findProvider.clearSearchList();
                    FocusManager.instance.primaryFocus?.unfocus();
                    // setState(() {});
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(15),
                    alignment: Alignment.center,
                    child: MyImage(
                      imagePath: "ic_close.png",
                      color: white,
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              } else {
                return SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }

  AlignedGridView liveTvWidget(List<LiveTvModel> list) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount:
          ((kIsWeb || Constant.isTV) && MediaQuery.of(context).size.width > 700)
              ? 5
              : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 12,
      itemCount: (list.length),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 4),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        return InkWell(
          focusColor: Colors.white70,
          borderRadius: BorderRadius.circular(4),
          onTap: () async {
            final adProvider = context.read<AdventisementsProvider>();
            final random = Random();
            final adventisements = adProvider.filterPreviewsAd();
            // log(adventisements.length);
            final ad = adventisements[random.nextInt(adventisements.length)];
            // print('--------$ad');
            try {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (context) {
                return LiveTVPlayer(
                  urlLink: list[position].liveSource.toString(),
                  adURl: 'https://media9tv.com/public/storage/${ad.videoPath}',
                );
              }));
              adProvider.setPreviewsAd(ad);
            } catch (e) {
              Utils.showSnackbar(context, "", "In correct video format", true);
            }
          },
          child: Container(
              margin: const EdgeInsets.all(5),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: primaryDarkColor,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  MyNetworkImage(
                    imageUrl: list[position].thumbnail.toString(),
                    fit: BoxFit.fill,
                    imgHeight: (kIsWeb || Constant.isTV) &&
                            MediaQuery.of(context).size.width > 700
                        ? MediaQuery.of(context).size.width * 0.11
                        : (kIsWeb || Constant.isTV)
                            ? MediaQuery.of(context).size.height * 0.15
                            : MediaQuery.of(context).size.height * 0.125,
                    imgWidth: MediaQuery.of(context).size.width,
                  ),
                  Visibility(
                    visible: list[position].channelNo != null,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: ColoredBox(
                        color: Colors.black54,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5,right: 5),
                          child: MyText(
                            color: white,
                            text: list[position].channelNo.toString(),
                            textalign: TextAlign.center,
                            fontsizeNormal: 15,
                            fontsizeWeb: 16,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w600,
                            fontstyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )),
        );
      },
    );
  }
}
