import 'dart:io';
import 'dart:math';

import 'package:dtlive/model/live_tv_model.dart';
import 'package:dtlive/pages/livetv_player.dart';
import 'package:dtlive/provider/adventisements_provider.dart';
import 'package:dtlive/provider/livetv_provider.dart';
import 'package:dtlive/shimmer/shimmerwidget.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

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
    if (livetvprovider.liveTvlist.isEmpty) {
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
    if (kIsWeb || Constant.isTV) {
      return const Scaffold(
          backgroundColor: appBgColor,
          body: SafeArea(
            child: Column(
              children: [],
            ),
          ));
    } else {
      return Scaffold(
        backgroundColor: appBgColor,
        appBar: Utils.myAppBar(context, "Live Tv", false),
        body: SafeArea(
            child: RefreshIndicator(
          onRefresh: livetvprovider.onRefresh,
          child: Consumer<LivetvProvider>(
            builder: (context, provider, child) {
              if (provider.loading) {
                return AlignedGridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    itemCount: 25,
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 0),
                    // physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int position) {
                      return ShimmerWidget.roundrectborder(
                        height: MediaQuery.of(context).size.height * 0.125,
                        width: MediaQuery.of(context).size.width,
                        shimmerBgColor: shimmerItemColor,
                        shapeBorder: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                      );
                    });
              } else if (provider.liveTvlist.isEmpty) {
                return const NoData(title: '', subTitle: '');
              }
              return Column(
                children: [
                  if (kIsWeb) ...[
                    liveTvWidget(provider.liveTvlist
                        .where((item) => item.website == 1)
                        .toList()),
                  ] else if (Constant.isTV) ...[
                    liveTvWidget(provider.liveTvlist
                        .where((item) => item.smartTv == 1)
                        .toList()),
                  ] else if (Platform.isAndroid || Platform.isIOS) ...[
                    liveTvWidget(provider.liveTvlist
                        .where((item) => item.mobile == 1)
                        .toList()),
                  ] else ...[
                    liveTvWidget(provider.liveTvlist),
                  ],
                  /* Browse by END */
                  const SizedBox(height: 22),
                ],
              );
            },
          ),
        )),
      );
    }
  }

  AlignedGridView liveTvWidget(List<LiveTvModel> list) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      itemCount: (list.length),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 4),
      // physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        return InkWell(
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
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: primaryDarkColor,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: MyNetworkImage(
                imageUrl: list[position].thumbnail.toString(),
                fit: BoxFit.fill,
                imgHeight: MediaQuery.of(context).size.height * 0.125,
                imgWidth: MediaQuery.of(context).size.width,
              )),
        );
      },
    );
  }
}
