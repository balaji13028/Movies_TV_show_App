import 'package:dtlive/provider/tv_showprovider.dart';
import 'package:dtlive/shimmer/shimmerwidget.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class TvShows extends StatefulWidget {
  const TvShows({super.key});

  @override
  State<TvShows> createState() => _TvShowsState();
}

class _TvShowsState extends State<TvShows> {
  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _getData() async {
    final rentStoreProvider =
        Provider.of<TvShowprovider>(context, listen: false);
    await rentStoreProvider.getTvShowsList();
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
        appBar: Utils.myAppBar(context, "Tv Show", false),
        body: SafeArea(child: Consumer<TvShowprovider>(
          builder: (context, tvShowprovider, child) {
            if (tvShowprovider.loading) {
              return AlignedGridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  itemCount: 10,
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int position) {
                    return ShimmerWidget.roundrectborder(
                      height: MediaQuery.of(context).size.height * 0.25,
                      width: MediaQuery.of(context).size.width,
                      shimmerBgColor: shimmerItemColor,
                      shapeBorder: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                    );
                  });
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  AlignedGridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    itemCount: (tvShowprovider.tvshows.length ?? 0),
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 20),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int position) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () async {
                          try {
                            await Utils.openPlayer(
                              context: context,
                              playType: "Video",
                              // videoId: ,
                              // typeId: vTypeID,
                              otherId: 0,
                              videoUrl: tvShowprovider.tvshows[position].source
                                  .toString(),
                              // trailerUrl: vUrl,
                              uploadType: 'youtube',
                              // videoThumb: videoThumb,
                              // vStopTime: stopTime,
                            );
                          } catch (e) {
                            Utils.showSnackbar(
                                context, "", "In correct video format", true);
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
                              imageUrl: tvShowprovider
                                  .tvshows[position].thumbnail
                                  .toString(),
                              fit: BoxFit.fill,
                              imgHeight:
                                  MediaQuery.of(context).size.height * 0.18,
                              imgWidth: MediaQuery.of(context).size.width,
                            )),
                      );
                    },
                  ),
                  /* Browse by END */
                  const SizedBox(height: 22),
                ],
              ),
            );
          },
        )),
      );
    }
  }
}
