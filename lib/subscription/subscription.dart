import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dtlive/model/subscriptionmodel.dart';
import 'package:dtlive/pages/loginsocial.dart';
import 'package:dtlive/shimmer/shimmerutils.dart';
import 'package:dtlive/subscription/allpayment.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/webwidget/footerweb.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:dtlive/provider/subscriptionprovider.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class Subscription extends StatefulWidget {
  const Subscription({
    Key? key,
  }) : super(key: key);

  @override
  State<Subscription> createState() => SubscriptionState();
}

class SubscriptionState extends State<Subscription> {
  late SubscriptionProvider subscriptionProvider;
  CarouselController pageController = CarouselController();

  @override
  void initState() {
    subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    super.initState();
    _getData();
  }

  _getData() async {
    Utils.getCurrencySymbol();
    await subscriptionProvider.getPackages();
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _checkAndPay(List<Result>? packageList, int index) async {
    if (Constant.userID != null) {
      for (var i = 0; i < (packageList?.length ?? 0); i++) {
        if (packageList?[i].isBuy == 1) {
          debugPrint("<============= Purchaged =============>");
          Utils.showSnackbar(context, "info", "already_purchased", true);
          return;
        }
      }
      if (packageList?[index].isBuy == 0) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return AllPayment(
                payType: 'Package',
                itemId: packageList?[index].id.toString() ?? '',
                price: packageList?[index].price.toString() ?? '',
                itemTitle: packageList?[index].name.toString() ?? '',
                typeId: '',
                videoType: '',
                productPackage: '',
                currency: '',
              );
            },
          ),
        );
      }
    } else {
      if ((kIsWeb || Constant.isTV)) {
        Utils.buildWebAlertDialog(context, "login", "");
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const LoginSocial();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: subscriptionBG,
        body: SingleChildScrollView(
          child: _buildSubscription(),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: subscriptionBG,
        appBar: Utils.myAppBarWithBack(context, "subsciption", true),
        body: SingleChildScrollView(
          child: _buildSubscription(),
        ),
      );
    }
  }

  Widget _buildSubscription() {
    if (subscriptionProvider.loading) {
      if ((kIsWeb || Constant.isTV) &&
          MediaQuery.of(context).size.width > 720) {
        return ShimmerUtils.buildSubscribeWebShimmer(context);
      } else {
        return ShimmerUtils.buildSubscribeShimmer(context);
      }
    } else {
      if (subscriptionProvider.subscriptionModel.status == 200) {
        return Column(
          children: [
            SizedBox(
                height: ((kIsWeb || Constant.isTV) &&
                        MediaQuery.of(context).size.width > 720)
                    ? 40
                    : 12),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 20, right: 20),
              alignment: Alignment.center,
              child: MyText(
                color: otherColor,
                text: "subscriptiondesc",
                multilanguage: true,
                textalign: TextAlign.center,
                fontsizeNormal: 16,
                fontsizeWeb: 18,
                maxline: 2,
                fontweight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
            ),
            SizedBox(
                height: ((kIsWeb || Constant.isTV) &&
                        MediaQuery.of(context).size.width > 720)
                    ? 40
                    : 12),

            /* Remaining Data */
            _buildItems(subscriptionProvider.subscriptionModel.result),
            const SizedBox(height: 20),

            /* Web Footer */
            kIsWeb ? const FooterWeb() : const SizedBox.shrink(),
          ],
        );
      } else {
        return const NoData(title: '', subTitle: '');
      }
    }
  }

  Widget _buildItems(List<Result>? packageList) {
    if ((kIsWeb || Constant.isTV) && MediaQuery.of(context).size.width > 800) {
      return buildWebItem(packageList);
    } else {
      return buildMobileItem(packageList);
    }
  }

  Widget buildMobileItem(List<Result>? packageList) {
    if (packageList != null) {
      return CarouselSlider.builder(
        itemCount: packageList.length,
        carouselController: pageController,
        options: CarouselOptions(
          initialPage: 0,
          height: MediaQuery.of(context).size.height,
          enlargeCenterPage: packageList.length > 1 ? true : false,
          enlargeFactor: 0.18,
          autoPlay: false,
          autoPlayCurve: Curves.easeInOutQuart,
          enableInfiniteScroll: packageList.length > 1 ? true : false,
          viewportFraction: packageList.length > 1 ? 0.8 : 0.9,
        ),
        itemBuilder: (BuildContext context, int index, int pageViewIndex) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                elevation: 3,
                color: (packageList[index].isBuy == 1 ? primaryColor : black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(left: 18, right: 18),
                      constraints: const BoxConstraints(minHeight: 55),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: MyText(
                              color: (packageList[index].isBuy == 1
                                  ? black
                                  : primaryColor),
                              text: packageList[index].name ?? "",
                              textalign: TextAlign.start,
                              fontsizeNormal: 18,
                              fontsizeWeb: 24,
                              maxline: 1,
                              multilanguage: false,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w700,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                          const SizedBox(width: 5),
                          MyText(
                            color: (packageList[index].isBuy == 1
                                ? black
                                : primaryColor),
                            text:
                                "${Constant.currencySymbol} ${packageList[index].price.toString()} / ${packageList[index].time.toString()} ${packageList[index].type.toString()}",
                            textalign: TextAlign.center,
                            fontsizeNormal: 16,
                            fontsizeWeb: 22,
                            maxline: 1,
                            multilanguage: false,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w600,
                            fontstyle: FontStyle.normal,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 0.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: otherColor,
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(1, 9, 1, 9),
                      constraints: const BoxConstraints(minHeight: 0),
                      child: SingleChildScrollView(
                        child: _buildBenefits(packageList, index),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /* Choose Plan */
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(5),
                        onTap: () async {
                          _checkAndPay(packageList, index);
                        },
                        child: Container(
                          height: 45,
                          width: MediaQuery.of(context).size.width * 0.5,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          decoration: BoxDecoration(
                            color: (packageList[index].isBuy == 1
                                ? white
                                : primaryColor),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Consumer<SubscriptionProvider>(
                            builder: (context, subscriptionProvider, child) {
                              return MyText(
                                color: black,
                                text: (packageList[index].isBuy == 1)
                                    ? "current"
                                    : "chooseplan",
                                textalign: TextAlign.center,
                                fontsizeNormal: 16,
                                fontsizeWeb: 20,
                                fontweight: FontWeight.w700,
                                multilanguage: true,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontstyle: FontStyle.normal,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildWebItem(List<Result>? packageList) {
    if (packageList != null) {
      return Container(
        padding: const EdgeInsets.only(left: 30, right: 30, bottom: 15),
        child: ResponsiveGridList(
          minItemWidth: (MediaQuery.of(context).size.width > 720)
              ? Dimens.widthPackageWeb
              : Dimens.widthPackage,
          verticalGridSpacing: 8,
          horizontalGridSpacing: 6,
          minItemsPerRow: 1,
          maxItemsPerRow: 3,
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: List.generate(
            (packageList.length),
            (index) {
              return Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                elevation: 3,
                color: (packageList[index].isBuy == 1 ? primaryColor : black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(left: 18, right: 18),
                      constraints: const BoxConstraints(minHeight: 55),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: MyText(
                              color: (packageList[index].isBuy == 1
                                  ? black
                                  : primaryColor),
                              text: packageList[index].name ?? "",
                              textalign: TextAlign.start,
                              fontsizeNormal: 18,
                              fontsizeWeb: 24,
                              maxline: 1,
                              multilanguage: false,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w700,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                          const SizedBox(width: 5),
                          MyText(
                            color: (packageList[index].isBuy == 1
                                ? black
                                : primaryColor),
                            text:
                                "${Constant.currencySymbol} ${packageList[index].price.toString()} / ${packageList[index].time.toString()} ${packageList[index].type.toString()}",
                            textalign: TextAlign.center,
                            fontsizeNormal: 16,
                            fontsizeWeb: 22,
                            maxline: 1,
                            multilanguage: false,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w600,
                            fontstyle: FontStyle.normal,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 0.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: otherColor,
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(1, 9, 1, 9),
                      height: 300,
                      child: SingleChildScrollView(
                        child: _buildBenefits(packageList, index),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /* Choose Plan */
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            _checkAndPay(packageList, index);
                          },
                          child: Container(
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            decoration: BoxDecoration(
                              color: (packageList[index].isBuy == 1
                                  ? white
                                  : primaryColor),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.center,
                            child: Consumer<SubscriptionProvider>(
                              builder: (context, subscriptionProvider, child) {
                                return MyText(
                                  color: black,
                                  text: (packageList[index].isBuy == 1)
                                      ? "current"
                                      : "chooseplan",
                                  textalign: TextAlign.center,
                                  fontsizeNormal: 16,
                                  fontsizeWeb: 20,
                                  fontweight: FontWeight.w700,
                                  multilanguage: true,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
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

  Widget _buildBenefits(List<Result>? packageList, int? index) {
    if (packageList?[index ?? 0].data != null &&
        (packageList?[index ?? 0].data?.length ?? 0) > 0) {
      return AlignedGridView.count(
        shrinkWrap: true,
        crossAxisCount: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 25,
        padding: const EdgeInsets.fromLTRB(15, 2, 15, 5),
        itemCount: (packageList?[index ?? 0].data?.length ?? 0),
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        itemBuilder: (BuildContext context, int position) {
          return Container(
            constraints: const BoxConstraints(minHeight: 15),
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Expanded(
                  child: MyText(
                    color: (packageList?[index ?? 0].isBuy == 1
                        ? black
                        : otherColor),
                    text: packageList?[index ?? 0].data?[position].packageKey ??
                        "",
                    textalign: TextAlign.start,
                    multilanguage: false,
                    fontsizeNormal: 15,
                    fontsizeWeb: 18,
                    maxline: 3,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w600,
                    fontstyle: FontStyle.normal,
                  ),
                ),
                const SizedBox(width: 20),
                ((packageList?[index ?? 0].data?[position].packageValue ??
                                "") ==
                            "1" ||
                        (packageList?[index ?? 0]
                                    .data?[position]
                                    .packageValue ??
                                "") ==
                            "0")
                    ? MyImage(
                        width: 23,
                        height: 23,
                        color: (packageList?[index ?? 0]
                                        .data?[position]
                                        .packageValue ??
                                    "") ==
                                "1"
                            ? (packageList?[index ?? 0].isBuy == 1
                                ? black
                                : primaryColor)
                            : redColor,
                        imagePath: (packageList?[index ?? 0]
                                        .data?[position]
                                        .packageValue ??
                                    "") ==
                                "1"
                            ? "tick_mark.png"
                            : "cross_mark.png",
                      )
                    : MyText(
                        color: (packageList?[index ?? 0].isBuy == 1
                            ? black
                            : otherColor),
                        text: packageList?[index ?? 0]
                                .data?[position]
                                .packageValue ??
                            "",
                        textalign: TextAlign.center,
                        fontsizeNormal: 16,
                        fontsizeWeb: 24,
                        multilanguage: false,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        fontweight: FontWeight.bold,
                        fontstyle: FontStyle.normal,
                      ),
              ],
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
