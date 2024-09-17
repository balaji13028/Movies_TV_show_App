import 'dart:async';
import 'dart:developer' as log;
import 'dart:io';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:media9/model/live_tv_model.dart';
import 'package:media9/model/menulist_model.dart';
import 'package:media9/model/sectionlistmodel.dart' as list;
import 'package:media9/model/sectionlistmodel.dart';
import 'package:media9/model/slides_model.dart';
import 'package:media9/model/tvshowmodel.dart';
import 'package:media9/pages/live_tv.dart';
import 'package:media9/pages/livetv_player.dart';
import 'package:media9/pages/tv_shows.dart';
import 'package:media9/pages/tvshow_player.dart';
import 'package:media9/pages/videosbyid.dart';
import 'package:media9/provider/adventisements_provider.dart';
import 'package:media9/provider/bottombar_provider.dart';
import 'package:media9/provider/homeprovider.dart';
import 'package:media9/provider/sectiondataprovider.dart';
import 'package:media9/provider/slides_provider.dart';
import 'package:media9/shimmer/shimmerutils.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/dimens.dart';
import 'package:media9/utils/sharedpre.dart';
import 'package:media9/utils/strings.dart';
import 'package:media9/utils/utils.dart';
import 'package:media9/webwidget/commonappbar.dart';
import 'package:media9/webwidget/footerweb.dart';
import 'package:media9/widget/myimage.dart';
import 'package:media9/widget/mynetworkimg.dart';
import 'package:media9/widget/mytext.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Home extends StatefulWidget {
  final String? pageName;
  const Home({super.key, required this.pageName});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  late SectionDataProvider sectionDataProvider;
  final FirebaseAuth auth = FirebaseAuth.instance;
  SharedPre sharedPref = SharedPre();
  CarouselController carouselController = CarouselController();
  final tabScrollController = ScrollController();
  late ListObserverController observerController;
  late HomeProvider homeProvider;
  late BottombarProvider bottomPRovider;
  int? videoId, videoType, typeId;
  String? currentPage,
      langCatName,
      aboutUsUrl,
      privacyUrl,
      termsConditionUrl,
      refundPolicyUrl,
      mSearchText;

  _onItemTapped(String page) async {
    debugPrint("_onItemTapped -----------------> $page");
    if (page != "") {
      await setSelectedTab(-1);
    }
    setState(() {
      currentPage = page;
    });
  }

  @override
  void initState() {
    sectionDataProvider =
        Provider.of<SectionDataProvider>(context, listen: false);
    bottomPRovider = Provider.of<BottombarProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    observerController =
        ListObserverController(controller: tabScrollController);
    currentPage = widget.pageName ?? "";
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    if (!kIsWeb) {
      OneSignal.Notifications.addClickListener(_handleNotificationOpened);
    }
  }

  // What to do when the user opens/taps on a notification
  _handleNotificationOpened(result) {
    /* id, video_type, type_id */

    debugPrint(
        "setNotificationOpenedHandler additionalData ===> ${result.notification.additionalData.toString()}");
    debugPrint(
        "setNotificationOpenedHandler video_id ===> ${result.notification.additionalData?['id']}");
    debugPrint(
        "setNotificationOpenedHandler upcoming_type ===> ${result.notification.additionalData?['upcoming_type']}");
    debugPrint(
        "setNotificationOpenedHandler video_type ===> ${result.notification.additionalData?['video_type']}");
    debugPrint(
        "setNotificationOpenedHandler type_id ===> ${result.notification.additionalData?['type_id']}");

    if (result.notification.additionalData?['id'] != null &&
        result.notification.additionalData?['upcoming_type'] != null &&
        result.notification.additionalData?['video_type'] != null &&
        result.notification.additionalData?['type_id'] != null) {
      String? videoID =
          result.notification.additionalData?['id'].toString() ?? "";
      String? upcomingType =
          result.notification.additionalData?['upcoming_type'].toString() ?? "";
      String? videoType =
          result.notification.additionalData?['video_type'].toString() ?? "";
      String? typeID =
          result.notification.additionalData?['type_id'].toString() ?? "";
      log.log("videoID =======> $videoID");
      log.log("upcomingType ==> $upcomingType");
      log.log("videoType =====> $videoType");
      log.log("typeID ========> $typeID");

      Utils.openDetails(
        context: context,
        videoId: int.parse(videoID),
        upcomingType: int.parse(upcomingType),
        videoType: int.parse(videoType),
        typeId: int.parse(typeID),
      );
    }
  }

  _getData() async {
    if (!kIsWeb) {
      OneSignal.Notifications.requestPermission(true);
    }
    final slidesProvider = Provider.of<SlidesProvider>(context, listen: false);
    final adeventisementProvider =
        Provider.of<AdventisementsProvider>(context, listen: false);
    // await homeProvider.getMenuList();
    await adeventisementProvider.getAdvenmtisementsList();
    await slidesProvider.getSlides();
    await homeProvider.gethomeScreenData();
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
    // generalsetting.getGeneralsetting();
    // generalsetting.getPages();
    Utils.getCurrencySymbol();
  }

  Future<void> setSelectedTab(int tabPos) async {
    debugPrint("setSelectedTab tabPos ====> $tabPos");
    if (!mounted) return;
    await homeProvider.setSelectedTab(tabPos);
    // _scrollToCurrent();
    debugPrint(
        "setSelectedTab selectedIndex ====> ${homeProvider.selectedIndex}");
    debugPrint(
        "setSelectedTab lastTabPosition ====> ${sectionDataProvider.lastTabPosition}");
    if (sectionDataProvider.lastTabPosition == tabPos) {
      return;
    } else {
      sectionDataProvider.setTabPosition(tabPos);
    }
  }

  Future<void> getTabData(int position, List<MenulistModel>? menuList) async {
    debugPrint("getTabData position ====> $position");
    await setSelectedTab(position);
    await sectionDataProvider.setLoading(true);
    // await sectionDataProvider.getSectionList(
    //     position == 0 ? "0" : (sectionTypeList?[position - 1].id),
    //     position == 0 ? "1" : "2");
  }

  // openDetailPage(String pageName, int videoId, int upcomingType, int videoType,
  //     int typeId) async {
  //   debugPrint("pageName =======> $pageName");
  //   debugPrint("videoId ========> $videoId");
  //   debugPrint("upcomingType ===> $upcomingType");
  //   debugPrint("videoType ======> $videoType");
  //   debugPrint("typeId =========> $typeId");
  //   if (pageName != "" && (kIsWeb || Constant.isTV)) {
  //     await setSelectedTab(-1);
  //   }
  //   if (!mounted) return;
  //   Utils.openDetails(
  //     context: context,
  //     videoId: videoId,
  //     upcomingType: upcomingType,
  //     videoType: videoType,
  //     typeId: typeId,
  //   );
  // }

  @override
  void dispose() {
    super.dispose();
  }

  _scrollToCurrent() {
    log.log("selectedIndex ======> ${homeProvider.selectedIndex.toDouble()}");
    observerController.animateTo(
      index: homeProvider.selectedIndex,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: (kIsWeb || Constant.isTV)
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: appBgColor,
              toolbarHeight: 65,
              title: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                alignment: Alignment.center,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: transparentColor,
                  highlightColor: transparentColor,
                  onTap: () async {
                    // await getTabData(0, homeProvider.sectionTypeModel.result);
                  },
                  child: MyImage(
                      width: 120, height: 120, imagePath: "appicon.png"),
                ),
              ), // This is the title in the app bar.
            ),
      body: SafeArea(
        child: (kIsWeb || Constant.isTV)
            ? _webAppBarWithDetails()
            : _mobileAppBarWithDetails(),
      ),
    );
  }

  Widget _mobileAppBarWithDetails() {
    return NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              // sliver: SliverAppBar(
              //   automaticallyImplyLeading: false,
              //   backgroundColor: appBgColor,
              //   toolbarHeight: 65,
              //   title: Container(
              //     width: MediaQuery.of(context).size.width,
              //     height: MediaQuery.of(context).size.height,
              //     alignment: Alignment.center,
              //     child: InkWell(
              //       borderRadius: BorderRadius.circular(8),
              //       splashColor: transparentColor,
              //       highlightColor: transparentColor,
              //       onTap: () async {
              //         await getTabData(
              //             0,
              //             homeProvider.menulist
              //                 .where((item) => item.home == 1)
              //                 .toList());
              //       },
              //       child: MyImage(
              //           width: 120, height: 120, imagePath: "appicon.png"),
              //     ),
              //   ), // This is the title in the app bar.
              //   pinned: false,
              //   expandedHeight: 0,
              //   forceElevated: innerBoxIsScrolled,
              // ),
            ),
          ];
        },
        body: homeProvider.loading
            ? ShimmerUtils.buildHomeMobileShimmer(context)
            : Stack(
                children: [
                  tabItem(),
                  // if (homeProvider.menulist.isNotEmpty) ...[
                  //   Container(
                  //     width: MediaQuery.of(context).size.width,
                  //     height: Dimens.homeTabHeight,
                  //     padding: const EdgeInsets.only(top: 8, bottom: 8),
                  //     color: black.withOpacity(0.8),
                  //     child: tabTitle(homeProvider.menulist
                  //         .where((item) => item.home == 1)
                  //         .toList()),
                  //   ),
                  // ],
                ],
              )
        // : const NoData(title: '', subTitle: '')
        // : const NoData(title: '', subTitle: ''),
        );
  }

  Widget _webAppBarWithDetails() {
    if (homeProvider.loading) {
      return ShimmerUtils.buildHomeMobileShimmer(context);
    } else {
      return Column(
        children: [
          const CommonAppBar(),
          // _clickToRedirect(pageName: currentPage ?? ""),
          Expanded(child: tabItem()),
        ],
      );
      //   } else {
      //     return const SizedBox.shrink();
      //   }
      // } else {
      //   return const SizedBox.shrink();
      // }
    }
  }

  Widget tabTitle(List<MenulistModel>? menuList) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (tabScrollController.hasClients) {
        _scrollToCurrent();
      }
    });
    return ListViewObserver(
      controller: observerController,
      child: ListView.separated(
        itemCount: (menuList?.length ?? 0) + 1,
        shrinkWrap: true,
        controller: tabScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(13, 5, 13, 5),
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int index) {
          return Consumer<HomeProvider>(
            builder: (context, homeProvider, child) {
              return InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () async {
                  debugPrint("index ===========> $index");
                  if (kIsWeb) _onItemTapped("");
                  await getTabData(
                      index,
                      homeProvider.menulist
                          .where((item) => item.home == 1)
                          .toList());
                },
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 32),
                  decoration: Utils.setBackground(
                    homeProvider.selectedIndex == index
                        ? white
                        : transparentColor,
                    20,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(13, 0, 13, 0),
                  child: MyText(
                    color: homeProvider.selectedIndex == index ? black : white,
                    multilanguage: false,
                    text: index == 0
                        ? "Home"
                        : index > 0
                            ? (menuList?[index - 1].name.toString() ?? "")
                            : "",
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
      ),
    );
  }

  Widget tabItem() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Visibility(
            //   visible: (kIsWeb || Constant.isTV) ? true : false,
            //   child: SizedBox(height: Dimens.homeTabHeight),
            // ),

            /* Slides */
            Consumer<SlidesProvider>(
              builder: (context, slidesProvider, child) {
                if (slidesProvider.loading || homeProvider.loading) {
                  if ((kIsWeb || Constant.isTV) &&
                      MediaQuery.of(context).size.width > 720) {
                    return ShimmerUtils.bannerWeb(context);
                  } else {
                    return ShimmerUtils.bannerMobile(context);
                  }
                } else {
                  if (slidesProvider.slides.isNotEmpty ||
                      slidesProvider.slides.isNotEmpty) {
                    if ((kIsWeb || Constant.isTV) &&
                        MediaQuery.of(context).size.width > 720) {
                      // return const SizedBox();
                      return _webHomeBanner(
                          slidesProvider.slides, slidesProvider);
                    } else {
                      return _mobileHomeBanner(
                          slidesProvider.slides, slidesProvider);
                    }
                  } else {
                    return const SizedBox.shrink();
                  }
                }
              },
            ),

            /* Live tv & show tv Sections */
            Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                if (homeProvider.loading) {
                  return sectionShimmer();
                } else {
                  if (homeProvider.listData != null) {
                    return Column(children: [
                      if (homeProvider.livetVList.isNotEmpty) ...[
                        /* Live Tv list */
                        ((kIsWeb || Constant.isTV) &&
                                MediaQuery.of(context).size.width > 720)
                            ? continueWatchingLayout(true)
                            : Column(
                                children: [
                                  const SizedBox(height: 25),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                    child: InkWell(
                                      onTap: () {
                                        bottomPRovider.onItemTapped(1);
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          MyText(
                                            color: white,
                                            text: "Live Tv",
                                            multilanguage: false,
                                            textalign: TextAlign.center,
                                            fontsizeNormal: 16,
                                            fontsizeWeb: 16,
                                            fontweight: FontWeight.w600,
                                            maxline: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (kIsWeb) ...[
                                    liveTvWidget(homeProvider.livetVList
                                        .where((item) => item.website == 1)
                                        .toList()),
                                  ] else if (Constant.isTV) ...[
                                    liveTvWidget(homeProvider.livetVList
                                        .where((item) => item.smartTv == 1)
                                        .toList()),
                                  ] else if (Platform.isAndroid ||
                                      Platform.isIOS) ...[
                                    liveTvWidget(homeProvider.livetVList
                                        .where((item) => item.mobile == 1)
                                        .toList()),
                                  ] else ...[
                                    liveTvWidget(homeProvider.livetVList),
                                  ]
                                ],
                              )
                      ] else ...[
                        const SizedBox.shrink(),
                      ],
                      if (homeProvider.tvshowsList.isNotEmpty) ...[
                        ((kIsWeb || Constant.isTV) &&
                                MediaQuery.of(context).size.width > 720)
                            ? continueWatchingLayout(false)
                            : Column(children: [
                                /* tvShows  list */
                                const SizedBox(height: 25),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                  child: InkWell(
                                    onTap: () {
                                      bottomPRovider.onItemTapped(2);
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        MyText(
                                          color: white,
                                          text: "Tv Shows",
                                          multilanguage: false,
                                          textalign: TextAlign.center,
                                          fontsizeNormal: 16,
                                          fontsizeWeb: 16,
                                          fontweight: FontWeight.w600,
                                          maxline: 1,
                                          overflow: TextOverflow.ellipsis,
                                          fontstyle: FontStyle.normal,
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                if (kIsWeb) ...[
                                  tvShowsWidget(homeProvider.tvshowsList
                                      .where((item) => item.website == true)
                                      .toList()),
                                ] else if (Constant.isTV) ...[
                                  tvShowsWidget(homeProvider.tvshowsList
                                      .where((item) => item.smartTv == true)
                                      .toList()),
                                ] else if (Platform.isAndroid ||
                                    Platform.isIOS) ...[
                                  tvShowsWidget(homeProvider.tvshowsList
                                      .where((item) => item.mobile == true)
                                      .toList()),
                                ] else ...[
                                  tvShowsWidget(homeProvider.tvshowsList),
                                ],
                                const SizedBox(height: 20),
                              ]),
                      ] else ...[
                        const SizedBox.shrink(),
                      ],
                      const SizedBox(height: 40),
                    ]);
                    // continueWatchingLayout(true),

                    // // // /* Remaining Sections */
                    // continueWatchingLayout(false)
                  } else {
                    return const SizedBox.shrink();
                  }
                }

                // continueWatchingLayout(true),

                // // // /* Remaining Sections */
                // continueWatchingLayout(false)
              },
            ),

            /* Web Footer */
            kIsWeb ? const FooterWeb() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  AlignedGridView tvShowsWidget(List<TvShowModel> list) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      itemCount: (list.length),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final adProvider = context.read<AdventisementsProvider>();
            final random = Random();
            final adventisements = adProvider.filterPreviewsAd();
            // log(adventisements.length);
            final ad = adventisements[random.nextInt(adventisements.length)];
            try {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return TvshowPlayer(
                        urlLink: list[position].source.toString(),
                        adURl:
                            'https://media9tv.com/public/storage/${ad.videoPath}');
                  },
                ),
              );
              adProvider.setPreviewsAd(ad);
            } catch (e) {
              Utils.showSnackbar(context, "", "In correct video format", true);
            }
          },
          child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: primaryDarkColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: MyNetworkImage(
                imageUrl: list[position].thumbnail.toString(),
                fit: BoxFit.fill,
                imgHeight: MediaQuery.of(context).size.height * 0.12,
                imgWidth: MediaQuery.of(context).size.width,
              )),
        );
      },
    );
  }

  AlignedGridView liveTvWidget(List<LiveTvModel> list) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      itemCount: (list.length),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final adProvider = context.read<AdventisementsProvider>();
            final random = Random();
            final adventisements = adProvider.filterPreviewsAd();
            // log(adventisements.length);
            final ad = adventisements[random.nextInt(adventisements.length)];
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
              width: MediaQuery.of(context).size.width,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: primaryDarkColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: MyNetworkImage(
                imageUrl: list[position].thumbnail.toString(),
                fit: BoxFit.fill,
                imgHeight: MediaQuery.of(context).size.height * 0.12,
                imgWidth: MediaQuery.of(context).size.width,
              )),
        );
      },
    );
  }

  /* Section Shimmer */
  Widget sectionShimmer() {
    return Column(
      children: [
        /* Continue Watching */
        if (Constant.userID != null && homeProvider.selectedIndex == 0)
          ShimmerUtils.continueWatching(context),

        /* Remaining Sections */
        ListView.builder(
          itemCount: 10, // itemCount must be greater than 5
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            if (index == 1) {
              return ShimmerUtils.setHomeSections(context, "potrait");
            } else if (index == 2) {
              return ShimmerUtils.setHomeSections(context, "square");
            } else if (index == 3) {
              return ShimmerUtils.setHomeSections(context, "langGen");
            } else {
              return ShimmerUtils.setHomeSections(context, "landscape");
            }
          },
        ),
      ],
    );
  }

  Widget _mobileHomeBanner(
      List<SlidesModel>? slidesList, SlidesProvider provider) {
    if ((slidesList?.length ?? 0) > 0) {
      return Stack(
        alignment: AlignmentDirectional.bottomCenter,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: Dimens.homeBanner,
            child: CarouselSlider.builder(
              itemCount: (slidesList?.length ?? 0),
              carouselController: carouselController,
              options: CarouselOptions(
                initialPage: 0,
                height: Dimens.homeBanner,
                enlargeCenterPage: false,
                autoPlay: true,
                autoPlayCurve: Curves.linear,
                enableInfiniteScroll: true,
                autoPlayInterval:
                    Duration(milliseconds: Constant.bannerDuration),
                autoPlayAnimationDuration:
                    Duration(milliseconds: Constant.animationDuration),
                viewportFraction: 1.0,
                onPageChanged: (val, _) async {
                  await provider.setCurrentBanner(val);
                },
              ),
              itemBuilder:
                  (BuildContext context, int index, int pageViewIndex) {
                return InkWell(
                  focusColor: white,
                  borderRadius: BorderRadius.circular(0),
                  onTap: () {
                    log.log("Clicked on index ==> $index");
                    // openDetailPage(
                    //   (sectionBannerList?[index].videoType ?? 0) == 2
                    //       ? "showdetail"
                    //       : "videodetail",
                    //   sectionBannerList?[index].id ?? 0,
                    //   sectionBannerList?[index].upcomingType ?? 0,
                    //   sectionBannerList?[index].videoType ?? 0,
                    //   sectionBannerList?[index].typeId ?? 0,
                    // );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Stack(
                      alignment: AlignmentDirectional.bottomCenter,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: Dimens.homeBanner,
                          child: MyNetworkImage(
                            imageUrl: slidesList?[index].imagePath ?? "",
                            fit: BoxFit.fill,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(0),
                          width: MediaQuery.of(context).size.width,
                          height: Dimens.homeBanner,
                          alignment: Alignment.center,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            child: Consumer<SlidesProvider>(
              builder: (context, slidesProvideer, child) {
                return AnimatedSmoothIndicator(
                  count: (slidesList?.length ?? 0),
                  activeIndex: slidesProvideer.currentSlideIndex ?? 0,
                  effect: const ScrollingDotsEffect(
                    spacing: 8,
                    radius: 4,
                    activeDotColor: dotsActiveColor,
                    dotColor: dotsDefaultColor,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _webHomeBanner(
      List<SlidesModel>? slidesList, SlidesProvider provider) {
    if ((slidesList?.length ?? 0) > 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: kIsWeb ? Dimens.homeWebBanner + 120 : Dimens.homeWebBanner,
          child: CarouselSlider.builder(
            itemCount: (slidesList?.length ?? 0),
            carouselController: carouselController,
            options: CarouselOptions(
              initialPage: 0,
              height:
                  kIsWeb ? Dimens.homeWebBanner + 120 : Dimens.homeWebBanner,
              enlargeCenterPage: false,
              autoPlay: true,
              autoPlayCurve: Curves.easeInOutQuart,
              enableInfiniteScroll: true,
              autoPlayInterval: Duration(milliseconds: Constant.bannerDuration),
              autoPlayAnimationDuration:
                  Duration(milliseconds: Constant.animationDuration),
              viewportFraction: 0.94,
              onPageChanged: (val, _) async {
                await provider.setCurrentBanner(val);
              },
            ),
            itemBuilder: (BuildContext context, int index, int pageViewIndex) {
              return InkWell(
                focusColor: white,
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  log.log("Clicked on index ==> $index");
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    // clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          //  *
                          // (Dimens.webBannerImgPr),
                          height: kIsWeb
                              ? Dimens.homeWebBanner + 120
                              : Dimens.homeWebBanner,
                          child: MyNetworkImage(
                            imageUrl: slidesList?[index].imagePath ?? "",
                            fit: BoxFit.fill,
                          ),
                        ),
                        // Container(
                        //   padding: const EdgeInsets.all(0),
                        //   width: MediaQuery.of(context).size.width,
                        //   height: Dimens.homeWebBanner,
                        //   alignment: Alignment.centerLeft,
                        //   decoration: const BoxDecoration(
                        //     gradient: LinearGradient(
                        //       begin: Alignment.centerLeft,
                        //       end: Alignment.centerRight,
                        //       colors: [
                        //         lightBlack,
                        //         lightBlack,
                        //         lightBlack,
                        //         lightBlack,
                        //         transparentColor,
                        //         transparentColor,
                        //         transparentColor,
                        //         transparentColor,
                        //         transparentColor,
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // Container(
                        //   width: MediaQuery.of(context).size.width,
                        //   height: Dimens.homeWebBanner,
                        //   alignment: Alignment.centerLeft,
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     crossAxisAlignment: CrossAxisAlignment.center,
                        //     children: [
                        //       Container(
                        //         width: MediaQuery.of(context).size.width *
                        //             (1.0 - Dimens.webBannerImgPr),
                        //         constraints: const BoxConstraints(minHeight: 0),
                        //         padding:
                        //             const EdgeInsets.fromLTRB(35, 50, 55, 35),
                        //         alignment: Alignment.centerLeft,
                        //         child: const Column(
                        //           mainAxisAlignment: MainAxisAlignment.start,
                        //           crossAxisAlignment: CrossAxisAlignment.start,
                        //           children: [
                        // MyText(
                        //   color: white,
                        //   text: slidesList?[index].title ?? "",
                        //   textalign: TextAlign.start,
                        //   fontsizeNormal: 14,
                        //   fontsizeWeb: 25,
                        //   fontweight: FontWeight.w700,
                        //   multilanguage: false,
                        //   maxline: 2,
                        //   overflow: TextOverflow.ellipsis,
                        //   fontstyle: FontStyle.normal,
                        // ),
                        // const SizedBox(height: 12),
                        // MyText(
                        //   color: whiteLight,
                        //   text: sectionBannerList?[index]
                        //           .categoryName ??
                        //       "",
                        //   textalign: TextAlign.start,
                        //   fontsizeNormal: 14,
                        //   fontweight: FontWeight.w600,
                        //   fontsizeWeb: 15,
                        //   multilanguage: false,
                        //   maxline: 2,
                        //   overflow: TextOverflow.ellipsis,
                        //   fontstyle: FontStyle.normal,
                        // ),
                        // const SizedBox(height: 8),
                        // Expanded(
                        //   child: MyText(
                        //     color: whiteLight,
                        //     text:
                        //         slidesList?[index].description ?? "",
                        //     textalign: TextAlign.start,
                        //     fontsizeNormal: 14,
                        //     fontweight: FontWeight.w600,
                        //     fontsizeWeb: 15,
                        //     multilanguage: false,
                        //     maxline:
                        //         (MediaQuery.of(context).size.width <
                        //                 1000)
                        //             ? 2
                        //             : 5,
                        //     overflow: TextOverflow.ellipsis,
                        //     fontstyle: FontStyle.normal,
                        //   ),
                        // ),
                        //   ],
                        // ),
                        // ),
                        // const Expanded(child: SizedBox()),
                        // ],
                        // ),
                        // ),
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

  Widget continueWatchingLayout(bool isLiveTv) {
    int selectedIndex = 0;
    List<dynamic> list =
        isLiveTv ? homeProvider.livetVList : homeProvider.tvshowsList;
    if ((list.isNotEmpty)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: InkWell(
              focusColor: Colors.white30,
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                if (isLiveTv) {
                  Provider.of<HomeProvider>(context, listen: false)
                      .setCurrentPage(bottomView2);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const LiveTv();
                      },
                    ),
                  );
                } else {
                  Provider.of<HomeProvider>(context, listen: false)
                      .setCurrentPage(bottomView3);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const TvShows();
                      },
                    ),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  MyText(
                    color: white,
                    text: isLiveTv ? "Live Tv" : 'Tv Shows',
                    multilanguage: false,
                    textalign: TextAlign.center,
                    fontsizeNormal: 16,
                    fontsizeWeb: 16,
                    fontweight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: Dimens.heightContiLand,
            child: ListView.separated(
              itemCount: (list.length),
              shrinkWrap: true,
              padding: const EdgeInsets.only(left: 20, right: 20),
              scrollDirection: Axis.horizontal,
              physics:
                  const ClampingScrollPhysics(), //const PageScrollPhysics(parent: BouncingScrollPhysics()),
              separatorBuilder: (context, index) => const SizedBox(
                width: 5,
              ),
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onFocusChange: (value) {
                    // print(index);
                    // print(value);
                    // setState(() {
                    //   hoverIndex = i;
                    //   widget.selectedIndex = i;
                    // });
                  },
                  focusColor: Colors.white70,
                  borderRadius: BorderRadius.circular(4),
                  // autofocus: selectedIndex == index ? true : false,
                  onTap: () async {
                    final adProvider = context.read<AdventisementsProvider>();
                    final random = Random();
                    final adventisements = adProvider.filterPreviewsAd();
                    // log(adventisements.length);
                    final ad =
                        adventisements[random.nextInt(adventisements.length)];
                    if (isLiveTv) {
                      try {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return LiveTVPlayer(
                            urlLink: list[index]!.liveSource.toString(),
                            adURl:
                                'https://media9tv.com/public/storage/${ad.videoPath}',
                          );
                        }));
                        adProvider.setPreviewsAd(ad);
                      } catch (e) {
                        Utils.showSnackbar(
                            context, "", "In correct video format", true);
                      }
                    } else {
                      try {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return TvshowPlayer(
                                  urlLink: list[index]!.source.toString(),
                                  adURl:
                                      'https://media9tv.com/public/storage/${ad.videoPath}');
                            },
                          ),
                        );
                        adProvider.setPreviewsAd(ad);
                      } catch (e) {
                        Utils.showSnackbar(
                            context, "", "In correct video format", true);
                      }
                    }
                  },
                  child:
                      // Stack(
                      //   alignment: AlignmentDirectional.bottomStart,
                      //   children: [
                      Container(
                    width: Dimens.widthContiLand,
                    height: Dimens.heightContiLand,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: MyNetworkImage(
                        imageUrl: list[index]?.thumbnail ?? "",
                        fit: BoxFit.fill,
                        imgHeight: MediaQuery.of(context).size.height,
                        imgWidth: MediaQuery.of(context).size.width,
                      ),
                    ),
                  ),
                  // Column(
                  //   mainAxisSize: MainAxisSize.min,
                  //   mainAxisAlignment: MainAxisAlignment.start,
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: <Widget>[
                  //     Padding(
                  //       padding: const EdgeInsets.only(left: 10, bottom: 8),
                  //       child: InkWell(
                  //         borderRadius: BorderRadius.circular(20),
                  //         onTap: () async {
                  //           // openPlayer(
                  //           //     "ContinueWatch", index, liveTvList);
                  //         },
                  //         child: MyImage(
                  //           width: 30,
                  //           height: 30,
                  //           imagePath: "play.png",
                  //         ),
                  //       ),
                  //     ),
                  // Container(
                  //   width: Dimens.widthContiLand,
                  //   constraints: const BoxConstraints(minWidth: 0),
                  //   padding: const EdgeInsets.all(3),
                  //   child: LinearPercentIndicator(
                  //     padding: const EdgeInsets.all(0),
                  //     barRadius: const Radius.circular(2),
                  //     lineHeight: 4,
                  //     percent: Utils.getPercentage(
                  //         liveTvList?[index].videoDuration ?? 0,
                  //         continueWatchingList?[index].stopTime ?? 0),
                  //     backgroundColor: secProgressColor,
                  //     progressColor: primaryColor,
                  //   ),
                  // ),
                  // (continueWatchingList?[index].releaseTag != null &&
                  //         (continueWatchingList?[index].releaseTag ?? "")
                  //             .isNotEmpty)
                  //     ? Container(
                  //         decoration: const BoxDecoration(
                  //           color: black,
                  //           borderRadius: BorderRadius.only(
                  //             bottomLeft: Radius.circular(4),
                  //             bottomRight: Radius.circular(4),
                  //           ),
                  //           shape: BoxShape.rectangle,
                  //         ),
                  //         alignment: Alignment.center,
                  //         width: Dimens.widthContiLand,
                  //         height: 15,
                  //         child: MyText(
                  //           color: white,
                  //           multilanguage: false,
                  //           text:
                  //               continueWatchingList?[index].releaseTag ??
                  //                   "",
                  //           textalign: TextAlign.center,
                  //           fontsizeNormal: 6,
                  //           fontweight: FontWeight.w700,
                  //           fontsizeWeb: 10,
                  //           maxline: 1,
                  //           overflow: TextOverflow.ellipsis,
                  //           fontstyle: FontStyle.normal,
                  //         ),
                  //       )
                  // : const SizedBox.shrink(),
                  //   ],
                  // ),
                  // ],
                  // ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget setSectionByType(List<list.Result>? sectionList) {
    return ListView.builder(
      itemCount: sectionList?.length ?? 0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        if (sectionList?[index].data != null &&
            (sectionList?[index].data?.length ?? 0) > 0) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: MyText(
                  color: white,
                  text: sectionList?[index].title.toString() ?? "",
                  textalign: TextAlign.center,
                  fontsizeNormal: 14,
                  fontweight: FontWeight.w600,
                  fontsizeWeb: 16,
                  multilanguage: false,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: getRemainingDataHeight(
                  sectionList?[index].videoType.toString() ?? "",
                  sectionList?[index].screenLayout ?? "",
                ),
                child: setSectionData(sectionList: sectionList, index: index),
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget setSectionData(
      {required List<list.Result>? sectionList, required int index}) {
    /* video_type =>  1-video,  2-show,  3-language,  4-category */
    /* screen_layout =>  landscape, potrait, square */
    if ((sectionList?[index].videoType ?? 0) == 1) {
      if ((sectionList?[index].screenLayout ?? "") == "landscape") {
        return landscape(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else if ((sectionList?[index].screenLayout ?? "") == "potrait") {
        return portrait(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else if ((sectionList?[index].screenLayout ?? "") == "square") {
        return square(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else {
        return landscape(
            sectionList?[index].upcomingType, sectionList?[index].data);
      }
    } else if ((sectionList?[index].videoType ?? 0) == 2) {
      if ((sectionList?[index].screenLayout ?? "") == "landscape") {
        return landscape(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else if ((sectionList?[index].screenLayout ?? "") == "potrait") {
        return portrait(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else if ((sectionList?[index].screenLayout ?? "") == "square") {
        return square(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else {
        return landscape(
            sectionList?[index].upcomingType, sectionList?[index].data);
      }
    } else if ((sectionList?[index].videoType ?? 0) == 3) {
      return languageLayout(
          sectionList?[index].typeId ?? 0, sectionList?[index].data);
    } else if ((sectionList?[index].videoType ?? 0) == 4) {
      return genresLayout(
          sectionList?[index].typeId ?? 0, sectionList?[index].data);
    } else {
      if ((sectionList?[index].screenLayout ?? "") == "landscape") {
        return landscape(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else if ((sectionList?[index].screenLayout ?? "") == "potrait") {
        return portrait(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else if ((sectionList?[index].screenLayout ?? "") == "square") {
        return square(
            sectionList?[index].upcomingType, sectionList?[index].data);
      } else {
        return landscape(
            sectionList?[index].upcomingType, sectionList?[index].data);
      }
    }
  }

  double getRemainingDataHeight(String? videoType, String? layoutType) {
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

  Widget landscape(int? upcomingType, List<Datum>? sectionDataList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightLand,
      child: ListView.separated(
        itemCount: sectionDataList?.length ?? 0,
        shrinkWrap: true,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            focusColor: white,
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              log.log("Clicked on index ==> $index");
              // openDetailPage(
              //   (sectionDataList?[index].videoType ?? 0) == 2
              //       ? "showdetail"
              //       : "videodetail",
              //   sectionDataList?[index].id ?? 0,
              //   upcomingType ?? 0,
              //   sectionDataList?[index].videoType ?? 0,
              //   sectionDataList?[index].typeId ?? 0,
              // );
            },
            child: Container(
              width: Dimens.widthLand,
              height: Dimens.heightLand,
              alignment: Alignment.center,
              padding: EdgeInsets.all(Constant.isTV ? 2 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: MyNetworkImage(
                  imageUrl: sectionDataList?[index].landscape.toString() ?? "",
                  fit: BoxFit.cover,
                  imgHeight: MediaQuery.of(context).size.height,
                  imgWidth: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget portrait(int? upcomingType, List<Datum>? sectionDataList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightPort,
      child: ListView.separated(
        itemCount: sectionDataList?.length ?? 0,
        shrinkWrap: true,
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            focusColor: white,
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              log.log("Clicked on index ==> $index");
              // openDetailPage(
              //   (sectionDataList?[index].videoType ?? 0) == 2
              //       ? "showdetail"
              //       : "videodetail",
              //   sectionDataList?[index].id ?? 0,
              //   upcomingType ?? 0,
              //   sectionDataList?[index].videoType ?? 0,
              //   sectionDataList?[index].typeId ?? 0,
              // );
            },
            child: Container(
              width: Dimens.widthPort,
              height: Dimens.heightPort,
              padding: EdgeInsets.all(Constant.isTV ? 2 : 0),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: MyNetworkImage(
                  imageUrl: sectionDataList?[index].thumbnail.toString() ?? "",
                  fit: BoxFit.cover,
                  imgHeight: MediaQuery.of(context).size.height,
                  imgWidth: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget square(int? upcomingType, List<Datum>? sectionDataList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightSquare,
      child: ListView.separated(
        itemCount: sectionDataList?.length ?? 0,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(left: 20, right: 20),
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            focusColor: white,
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              log.log("Clicked on index ==> $index");
              // openDetailPage(
              //   (sectionDataList?[index].videoType ?? 0) == 2
              //       ? "showdetail"
              //       : "videodetail",
              //   sectionDataList?[index].id ?? 0,
              //   upcomingType ?? 0,
              //   sectionDataList?[index].videoType ?? 0,
              //   sectionDataList?[index].typeId ?? 0,
              // );
            },
            child: Container(
              width: Dimens.widthSquare,
              height: Dimens.heightSquare,
              alignment: Alignment.center,
              padding: EdgeInsets.all(Constant.isTV ? 2 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: MyNetworkImage(
                  imageUrl: sectionDataList?[index].thumbnail.toString() ?? "",
                  fit: BoxFit.cover,
                  imgHeight: MediaQuery.of(context).size.height,
                  imgWidth: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget languageLayout(int? typeId, List<Datum>? sectionDataList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightLangGen,
      child: ListView.separated(
        itemCount: sectionDataList?.length ?? 0,
        shrinkWrap: true,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int index) {
          return Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [
              InkWell(
                focusColor: white,
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  log.log("Clicked on index ==> $index");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return VideosByID(
                          sectionDataList?[index].id ?? 0,
                          typeId ?? 0,
                          sectionDataList?[index].name ?? "",
                          "ByLanguage",
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  width: Dimens.widthLangGen,
                  height: Dimens.heightLangGen,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(Constant.isTV ? 2 : 0),
                  child: Stack(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: MyNetworkImage(
                          imageUrl:
                              sectionDataList?[index].image.toString() ?? "",
                          fit: BoxFit.fill,
                          imgHeight: MediaQuery.of(context).size.height,
                          imgWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(0),
                        width: MediaQuery.of(context).size.width,
                        height: Dimens.heightLangGen,
                        alignment: Alignment.center,
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3),
                child: MyText(
                  color: white,
                  text: sectionDataList?[index].name.toString() ?? "",
                  textalign: TextAlign.center,
                  fontsizeNormal: 14,
                  fontweight: FontWeight.w600,
                  fontsizeWeb: 15,
                  multilanguage: false,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget genresLayout(int? typeId, List<Datum>? sectionDataList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.heightLangGen,
      child: ListView.separated(
        itemCount: sectionDataList?.length ?? 0,
        shrinkWrap: true,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(left: 20, right: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (BuildContext context, int index) {
          return Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [
              InkWell(
                focusColor: white,
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  log.log("Clicked on index ==> $index");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return VideosByID(
                          sectionDataList?[index].id ?? 0,
                          typeId ?? 0,
                          sectionDataList?[index].name ?? "",
                          "ByCategory",
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  width: Dimens.widthLangGen,
                  height: Dimens.heightLangGen,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(Constant.isTV ? 2 : 0),
                  child: Stack(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: MyNetworkImage(
                          imageUrl:
                              sectionDataList?[index].image.toString() ?? "",
                          fit: BoxFit.fill,
                          imgHeight: MediaQuery.of(context).size.height,
                          imgWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(0),
                        width: MediaQuery.of(context).size.width,
                        height: Dimens.heightLangGen,
                        alignment: Alignment.center,
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3),
                child: MyText(
                  color: white,
                  text: sectionDataList?[index].name.toString() ?? "",
                  textalign: TextAlign.center,
                  fontsizeNormal: 14,
                  fontweight: FontWeight.w600,
                  fontsizeWeb: 15,
                  multilanguage: false,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /* ========= Open Player ========= */
  openPlayer(String playType, int index,
      List<ContinueWatching>? continueWatchingList) async {
    debugPrint("index ==========> $index");
    /* Set-up Quality URLs */
    Utils.setQualityURLs(
      video320: (continueWatchingList?[index].video320 ?? ""),
      video480: (continueWatchingList?[index].video480 ?? ""),
      video720: (continueWatchingList?[index].video720 ?? ""),
      video1080: (continueWatchingList?[index].video1080 ?? ""),
    );
    var isContinues = await Utils.openPlayer(
      context: context,
      playType:
          (continueWatchingList?[index].videoType ?? 0) == 2 ? "Show" : "Video",
      videoId: (continueWatchingList?[index].videoType ?? 0) == 2
          ? (continueWatchingList?[index].showId ?? 0)
          : (continueWatchingList?[index].id ?? 0),
      videoType: continueWatchingList?[index].videoType ?? 0,
      typeId: continueWatchingList?[index].typeId ?? 0,
      otherId: continueWatchingList?[index].typeId ?? 0,
      videoUrl: continueWatchingList?[index].video320 ?? "",
      trailerUrl: continueWatchingList?[index].trailerUrl ?? "",
      uploadType: continueWatchingList?[index].videoUploadType ?? "",
      videoThumb: continueWatchingList?[index].landscape ?? "",
      vStopTime: continueWatchingList?[index].stopTime ?? 0,
    );
    if (isContinues != null && isContinues == true) {
      // getTabData(0, homeProvider.sectionTypeModel.result);
      Future.delayed(Duration.zero).then((value) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }
  /* ========= Open Player ========= */
}
