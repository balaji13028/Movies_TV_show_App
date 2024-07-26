import 'dart:developer';

import 'package:dtlive/provider/purchaselistprovider.dart';
import 'package:dtlive/shimmer/shimmerutils.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class MyPurchaselist extends StatefulWidget {
  const MyPurchaselist({Key? key}) : super(key: key);

  @override
  State<MyPurchaselist> createState() => _MyPurchaselistState();
}

class _MyPurchaselistState extends State<MyPurchaselist> {
  late PurchaselistProvider purchaselistProvider;

  @override
  void initState() {
    purchaselistProvider =
        Provider.of<PurchaselistProvider>(context, listen: false);
    _getData();
    super.initState();
  }

  _getData() async {
    await purchaselistProvider.getUserRentVideoList();
  }

  @override
  void dispose() {
    purchaselistProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, "purchases", true),
      body: SafeArea(
        child: Consumer<PurchaselistProvider>(
          builder: (context, purchaselistProvider, child) {
            if (purchaselistProvider.loading) {
              return SingleChildScrollView(
                child: ShimmerUtils.buildRentShimmer(
                    context, Dimens.heightLand, Dimens.widthLand),
              );
            } else {
              if (purchaselistProvider.rentModel.status == 200) {
                if ((purchaselistProvider.rentModel.video?.length ?? 0) == 0 &&
                    (purchaselistProvider.rentModel.tvshow?.length ?? 0) == 0) {
                  return const NoData(
                    title: 'rent_and_buy_your_favorites',
                    subTitle: 'no_purchases_note',
                  );
                } else {
                  if (purchaselistProvider.rentModel.video != null ||
                      purchaselistProvider.rentModel.tvshow != null) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildPurchasedVideo(),
                          const SizedBox(height: 22),
                          _buildPurchasedShow(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  } else {
                    return const NoData(
                      title: 'rent_and_buy_your_favorites',
                      subTitle: 'no_purchases_note',
                    );
                  }
                }
              } else {
                return const NoData(
                  title: 'rent_and_buy_your_favorites',
                  subTitle: 'no_purchases_note',
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildPurchasedVideo() {
    if ((purchaselistProvider.rentModel.video?.length ?? 0) > 0) {
      return Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 30,
            padding: const EdgeInsets.only(left: 20, right: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                MyText(
                  color: white,
                  text: "purchasvideo",
                  multilanguage: true,
                  textalign: TextAlign.center,
                  fontsizeNormal: 16,
                  maxline: 1,
                  fontweight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(width: 5),
                MyText(
                  color: otherColor,
                  text: (purchaselistProvider.rentModel.video?.length ?? 0) > 1
                      ? "(${(purchaselistProvider.rentModel.video?.length ?? 0)} videos)"
                      : "(${(purchaselistProvider.rentModel.video?.length ?? 0)} video)",
                  textalign: TextAlign.center,
                  fontsizeNormal: 13,
                  maxline: 1,
                  fontweight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: (purchaselistProvider.rentModel.video?.length ?? 0) == 1
                ? Dimens.heightLand
                : ((purchaselistProvider.rentModel.video?.length ?? 0) > 1 &&
                        (purchaselistProvider.rentModel.video?.length ?? 0) < 7)
                    ? (Dimens.heightLand * 2)
                    : (purchaselistProvider.rentModel.video?.length ?? 0) > 6
                        ? (Dimens.heightLand * 3)
                        : (Dimens.heightLand * 2),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: AlignedGridView.count(
                shrinkWrap: true,
                crossAxisCount:
                    (purchaselistProvider.rentModel.video?.length ?? 0) == 1
                        ? 1
                        : ((purchaselistProvider.rentModel.video?.length ?? 0) >
                                    1 &&
                                (purchaselistProvider.rentModel.video?.length ??
                                        0) <
                                    7)
                            ? 2
                            : (purchaselistProvider.rentModel.video?.length ??
                                        0) >
                                    6
                                ? 3
                                : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                itemCount: (purchaselistProvider.rentModel.video?.length ?? 0),
                padding: const EdgeInsets.only(left: 20, right: 20),
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int position) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      log("Clicked on position ==> $position");
                      Utils.openDetails(
                        context: context,
                        videoId: purchaselistProvider
                                .rentModel.video?[position].id ??
                            0,
                        upcomingType: 0,
                        videoType: purchaselistProvider
                                .rentModel.video?[position].videoType ??
                            0,
                        typeId: purchaselistProvider
                                .rentModel.video?[position].typeId ??
                            0,
                      );
                    },
                    child: Container(
                      width: Dimens.widthLand,
                      height: Dimens.heightLand,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: MyNetworkImage(
                          imageUrl: purchaselistProvider
                                  .rentModel.video?[position].landscape
                                  .toString() ??
                              "",
                          fit: BoxFit.cover,
                          imgHeight: MediaQuery.of(context).size.height,
                          imgWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPurchasedShow() {
    if ((purchaselistProvider.rentModel.tvshow?.length ?? 0) > 0) {
      return Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 30,
            padding: const EdgeInsets.only(left: 20, right: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                MyText(
                  color: white,
                  text: "purchaschow",
                  textalign: TextAlign.center,
                  multilanguage: true,
                  fontsizeNormal: 16,
                  maxline: 1,
                  fontweight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(
                  width: 5,
                ),
                MyText(
                  color: otherColor,
                  text: (purchaselistProvider.rentModel.tvshow?.length ?? 0) > 1
                      ? "(${(purchaselistProvider.rentModel.tvshow?.length ?? 0)} shows)"
                      : "(${(purchaselistProvider.rentModel.tvshow?.length ?? 0)} show)",
                  textalign: TextAlign.center,
                  fontsizeNormal: 13,
                  maxline: 1,
                  fontweight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: (purchaselistProvider.rentModel.tvshow?.length ?? 0) == 1
                ? Dimens.heightLand
                : ((purchaselistProvider.rentModel.tvshow?.length ?? 0) > 1 &&
                        (purchaselistProvider.rentModel.tvshow?.length ?? 0) <
                            7)
                    ? (Dimens.heightLand * 2)
                    : (purchaselistProvider.rentModel.tvshow?.length ?? 0) > 6
                        ? (Dimens.heightLand * 3)
                        : (Dimens.heightLand * 2),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: AlignedGridView.count(
                shrinkWrap: true,
                crossAxisCount: (purchaselistProvider
                                .rentModel.tvshow?.length ??
                            0) ==
                        1
                    ? 1
                    : ((purchaselistProvider.rentModel.tvshow?.length ?? 0) >
                                1 &&
                            (purchaselistProvider.rentModel.tvshow?.length ??
                                    0) <
                                7)
                        ? 2
                        : (purchaselistProvider.rentModel.tvshow?.length ?? 0) >
                                6
                            ? 3
                            : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                itemCount: (purchaselistProvider.rentModel.tvshow?.length ?? 0),
                padding: const EdgeInsets.only(left: 20, right: 20),
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int position) {
                  return Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        log("Clicked on position ==> $position");
                        Utils.openDetails(
                          context: context,
                          videoId: purchaselistProvider
                                  .rentModel.tvshow?[position].id ??
                              0,
                          upcomingType: 0,
                          videoType: purchaselistProvider
                                  .rentModel.tvshow?[position].videoType ??
                              0,
                          typeId: purchaselistProvider
                                  .rentModel.tvshow?[position].typeId ??
                              0,
                        );
                      },
                      child: Container(
                        width: Dimens.widthLand,
                        height: Dimens.heightLand,
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: MyNetworkImage(
                            imageUrl: purchaselistProvider
                                    .rentModel.tvshow?[position].landscape
                                    .toString() ??
                                "",
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
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
