import 'package:dtlive/model/live_tv_model.dart';
import 'package:dtlive/provider/livetv_provider.dart';
import 'package:dtlive/shimmer/shimmerwidget.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
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
  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _getData() async {
    final livetvProvider = Provider.of<LivetvProvider>(context, listen: false);
    await livetvProvider.getTvShowsList();
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
        body: SafeArea(child: Consumer<LivetvProvider>(
          builder: (context, livetvProvider, child) {
            if (livetvProvider.loading) {
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
                    itemCount: (livetvProvider.liveTvlist.length ?? 0),
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 20),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int position) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {},
                        child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: primaryDarkColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: MyNetworkImage(
                              imageUrl: livetvProvider
                                  .liveTvlist[position].thumbnail
                                  .toString(),
                              fit: BoxFit.cover,
                              imgHeight:
                                  MediaQuery.of(context).size.height * 0.24,
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
