import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:media9/model/tvshowmodel.dart';
import 'package:media9/pages/tvshow_player.dart';
import 'package:media9/provider/adventisements_provider.dart';
import 'package:media9/provider/tv_showprovider.dart';
import 'package:media9/shimmer/shimmerwidget.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/dimens.dart';
import 'package:media9/utils/utils.dart';
import 'package:media9/webwidget/commonappbar.dart';
import 'package:media9/widget/mynetworkimg.dart';
import 'package:media9/widget/nodata.dart';
import 'package:provider/provider.dart';

class TvShows extends StatefulWidget {
  const TvShows({super.key});

  @override
  State<TvShows> createState() => _TvShowsState();
}

class _TvShowsState extends State<TvShows> {
  late TvShowprovider tvshowsprovider;
  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _getData() async {
    tvshowsprovider = Provider.of<TvShowprovider>(context, listen: false);
    if (tvshowsprovider.tvshows.isEmpty) {
      await tvshowsprovider.getTvShowsList();
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
    // if (kIsWeb || Constant.isTV) {
    //   return const Scaffold(
    //       backgroundColor: appBgColor,
    //       body: SafeArea(
    //         child: Column(
    //           children: [],
    //         ),
    //       ));
    // } else {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: (kIsWeb || Constant.isTV)
          ? null
          : Utils.myAppBar(context, "Tv Show", false),
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: tvshowsprovider.onRefresh,
        child: Stack(
          children: [
            Column(
              children: [
                Visibility(
                    visible: (kIsWeb || Constant.isTV) ? true : false,
                    child: SizedBox(height: Dimens.homeTabHeight)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Consumer<TvShowprovider>(
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
                        } else if (provider.tvshows.isEmpty) {
                          return const NoData(title: '', subTitle: '');
                        }
                        return Column(
                          children: [
                            if (kIsWeb) ...[
                              tvShowsWidget(provider.tvshows
                                  .where((item) => item.website == true)
                                  .toList()),
                            ] else if (Constant.isTV) ...[
                              tvShowsWidget(provider.tvshows
                                  .where((item) => item.smartTv == true)
                                  .toList()),
                            ] else if (Platform.isAndroid ||
                                Platform.isIOS) ...[
                              tvShowsWidget(provider.tvshows
                                  .where((item) => item.mobile == true)
                                  .toList()),
                            ] else ...[
                              tvShowsWidget(provider.tvshows),
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

  Widget tvShowsWidget(List<TvShowModel> list) {
    // print(MediaQuery.of(context).size.width > 700);
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount:
          ((kIsWeb || Constant.isTV) && MediaQuery.of(context).size.width > 700)
              ? 5
              : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 12,
      itemCount: (list.length),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        return InkWell(
          focusColor: Colors.white,
          borderRadius: BorderRadius.circular(4),
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
              // await Utils.openPlayer(
              //   context: context,
              //   playType: "Video",
              //   // videoId: ,
              //   // typeId: vTypeID,
              //   otherId: 0,
              //   videoUrl: list[position].source.toString(),
              //   // trailerUrl: vUrl,
              //   uploadType: 'youtube',
              //   // videoThumb: videoThumb,
              //   // vStopTime: stopTime,
              // );
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
              child: MyNetworkImage(
                imageUrl: list[position].thumbnail.toString(),
                fit: BoxFit.fill,
                imgHeight: (kIsWeb || Constant.isTV) &&
                        MediaQuery.of(context).size.width > 700
                    ? MediaQuery.of(context).size.width * 0.11
                    : (kIsWeb || Constant.isTV)
                        ? MediaQuery.of(context).size.height * 0.15
                        : MediaQuery.of(context).size.height * 0.125,
                imgWidth: MediaQuery.of(context).size.width,
              )),
        );
      },
    );
  }
}
