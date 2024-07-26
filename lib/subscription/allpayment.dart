import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dtlive/provider/channelsectionprovider.dart';
import 'package:dtlive/provider/paymentprovider.dart';
import 'package:dtlive/provider/showdetailsprovider.dart';
import 'package:dtlive/provider/videodetailsprovider.dart';
import 'package:dtlive/subscription/consumable_store.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/sharedpre.dart';
import 'package:dtlive/utils/strings.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/widget/nodata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_web/razorpay_web.dart';

final bool _kAutoConsume = Platform.isIOS || true;

class AllPayment extends StatefulWidget {
  final String? payType,
      itemId,
      price,
      itemTitle,
      typeId,
      videoType,
      productPackage,
      currency;
  const AllPayment({
    Key? key,
    required this.payType,
    required this.itemId,
    required this.price,
    required this.itemTitle,
    required this.typeId,
    required this.videoType,
    required this.productPackage,
    required this.currency,
  }) : super(key: key);

  @override
  State<AllPayment> createState() => AllPaymentState();
}

class AllPaymentState extends State<AllPayment> {
  final couponController = TextEditingController();
  late ProgressDialog prDialog;
  late PaymentProvider paymentProvider;
  SharedPre sharedPref = SharedPre();
  String? userId, userName, userEmail, userMobileNo, paymentId;
  String? strCouponCode = "";
  bool isPaymentDone = false;

  /* Paytm */
  String paytmResult = "";

  /* InApp Purchase */
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final List<ProductDetails> _products = <ProductDetails>[];
  late List<String> _kProductIds;
  String androidPackageID = "android.test.purchased";
  final List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  List<String> _consumables = <String>[];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  /* Stripe */
  Map<String, dynamic>? paymentIntent;

  @override
  void initState() {
    prDialog = ProgressDialog(context);
    _getData();

    /* In-App Purchase */
    if (!kIsWeb) {
      _kProductIds = <String>[androidPackageID];
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;
      _subscription =
          purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _subscription.cancel();
      }, onError: (Object error) {
        // handle error here.
        log("onError ============> ${error.toString()}");
      });
      initStoreInfo();
    }
    super.initState();
  }

  _getData() async {
    paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    await paymentProvider.getPaymentOption();
    await paymentProvider.setFinalAmount(widget.price ?? "");

    /* PaymentID */
    paymentId = Utils.generateRandomOrderID();
    log('paymentId =====================> $paymentId');

    userId = await sharedPref.read("userid");
    userName = await sharedPref.read("username");
    userEmail = await sharedPref.read("useremail");
    userMobileNo = await sharedPref.read("usermobile");
    log('getUserData userId ==> $userId');
    log('getUserData userName ==> $userName');
    log('getUserData userEmail ==> $userEmail');
    log('getUserData userMobileNo ==> $userMobileNo');

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    paymentProvider.clearProvider();
    if (!kIsWeb) {
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        iosPlatformAddition.setDelegate(null);
      }
      _subscription.cancel();
    }
    couponController.dispose();
    super.dispose();
  }

  /* add_transaction API */
  Future addTransaction(
      packageId, description, amount, paymentId, currencyCode) async {
    final videoDetailsProvider =
        Provider.of<VideoDetailsProvider>(context, listen: false);
    final showDetailsProvider =
        Provider.of<ShowDetailsProvider>(context, listen: false);
    final channelSectionProvider =
        Provider.of<ChannelSectionProvider>(context, listen: false);

    Utils.showProgress(context, prDialog);
    await paymentProvider.addTransaction(
        packageId, description, amount, paymentId, currencyCode, strCouponCode);

    if (!paymentProvider.payLoading) {
      await prDialog.hide();

      if (paymentProvider.successModel.status == 200) {
        isPaymentDone = true;
        await videoDetailsProvider.updatePrimiumPurchase();
        await showDetailsProvider.updatePrimiumPurchase();
        await channelSectionProvider.updatePrimiumPurchase();
        await videoDetailsProvider.updateRentPurchase();
        await showDetailsProvider.updateRentPurchase();

        if (!mounted) return;
        Navigator.pop(context, isPaymentDone);
      } else {
        isPaymentDone = false;
        if (!mounted) return;
        Utils.showSnackbar(
            context, "info", paymentProvider.successModel.message ?? "", false);
      }
    }
  }

  /* add_rent_transaction API */
  Future addRentTransaction(videoId, amount, typeId, videoType) async {
    final videoDetailsProvider =
        Provider.of<VideoDetailsProvider>(context, listen: false);
    final showDetailsProvider =
        Provider.of<ShowDetailsProvider>(context, listen: false);

    Utils.showProgress(context, prDialog);
    await paymentProvider.addRentTransaction(
        videoId, amount, typeId, videoType, strCouponCode);

    if (!paymentProvider.payLoading) {
      await prDialog.hide();

      if (paymentProvider.successModel.status == 200) {
        isPaymentDone = true;
        if (videoType == "1") {
          await videoDetailsProvider.updateRentPurchase();
        } else if (videoType == "2") {
          await showDetailsProvider.updateRentPurchase();
        }

        if (!mounted) return;
        Navigator.pop(context, isPaymentDone);
      } else {
        isPaymentDone = false;
        if (!mounted) return;
        Utils.showSnackbar(
            context, "info", paymentProvider.successModel.message ?? "", true);
      }
    }
  }

  /* apply_coupon API */
  Future applyCoupon() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Utils.showProgress(context, prDialog);
    if (widget.payType == "Package") {
      /* Package Coupon */
      await paymentProvider.applyPackageCouponCode(
          strCouponCode, widget.itemId);

      if (!paymentProvider.couponLoading) {
        await prDialog.hide();
        if (paymentProvider.couponModel.status == 200) {
          couponController.clear();
          await paymentProvider.setFinalAmount(
              paymentProvider.couponModel.result?.discountAmount.toString());
          strCouponCode =
              paymentProvider.couponModel.result?.uniqueId.toString();
          log("strCouponCode =============> $strCouponCode");
          log("finalAmount =============> ${paymentProvider.finalAmount}");
          if (!mounted) return;
          Utils.showSnackbar(context, "success",
              paymentProvider.couponModel.message ?? "", false);
        } else {
          if (!mounted) return;
          Utils.showSnackbar(context, "fail",
              paymentProvider.couponModel.message ?? "", false);
        }
      }
    } else if (widget.payType == "Rent") {
      /* Rent Coupon */
      await paymentProvider.applyRentCouponCode(strCouponCode, widget.itemId,
          widget.typeId, widget.videoType, widget.price);

      if (!paymentProvider.couponLoading) {
        await prDialog.hide();
        if (paymentProvider.couponModel.status == 200) {
          couponController.clear();
          await paymentProvider.setFinalAmount(
              paymentProvider.couponModel.result?.discountAmount.toString());
          strCouponCode =
              paymentProvider.couponModel.result?.uniqueId.toString();
          log("strCouponCode =============> $strCouponCode");
          log("finalAmount =============> ${paymentProvider.finalAmount}");
          if (!mounted) return;
          Utils.showSnackbar(context, "success",
              paymentProvider.couponModel.message ?? "", false);
        } else {
          if (!mounted) return;
          Utils.showSnackbar(context, "fail",
              paymentProvider.couponModel.message ?? "", false);
        }
      }
    } else {
      await prDialog.hide();
    }
  }

  openPayment({required String pgName}) async {
    debugPrint("finalAmount =============> ${paymentProvider.finalAmount}");
    if (paymentProvider.finalAmount != "0") {
      if (pgName == "inapppurchage") {
        _initInAppPurchase();
      } else if (pgName == "paypal") {
        _paypalInit();
      } else if (pgName == "razorpay") {
        _initializeRazorpay();
      } else if (pgName == "flutterwave") {
      } else if (pgName == "payumoney") {
      } else if (pgName == "paytm") {
        _paytmInit();
      } else if (pgName == "stripe") {
        _stripeInit();
      } else if (pgName == "cash") {
        if (!mounted) return;
        Utils.showSnackbar(context, "info", "cash_payment_msg", true);
      }
    } else {
      if (widget.payType == "Package") {
        addTransaction(widget.itemId, widget.itemTitle,
            paymentProvider.finalAmount, paymentId, widget.currency);
      } else if (widget.payType == "Rent") {
        addRentTransaction(widget.itemId, paymentProvider.finalAmount,
            widget.typeId, widget.videoType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPressed,
      child: _buildPage(),
    );
  }

  Widget _buildPage() {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: (kIsWeb || Constant.isTV)
          ? null
          : Utils.myAppBarWithBack(context, "payment_details", true),
      body: SafeArea(
        child: Center(
          child: _buildMobilePage(),
        ),
      ),
    );
  }

  Widget _buildMobilePage() {
    return Container(
      width:
          ((kIsWeb || Constant.isTV) && MediaQuery.of(context).size.width > 720)
              ? MediaQuery.of(context).size.width * 0.5
              : MediaQuery.of(context).size.width,
      margin: (kIsWeb || Constant.isTV)
          ? const EdgeInsets.fromLTRB(50, 0, 50, 50)
          : const EdgeInsets.all(0),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: (kIsWeb || Constant.isTV) ? 40 : 0),
          /* Coupon Code Box & Total Amount */
          Container(
            margin: const EdgeInsets.all(8.0),
            child: Card(
              semanticContainer: true,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              elevation: 5,
              color: lightBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                constraints: const BoxConstraints(minHeight: 50),
                alignment: Alignment.centerLeft,
                child: Column(
                  children: [
                    _buildCouponBox(),
                    const SizedBox(height: 20),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      constraints: const BoxConstraints(minHeight: 50),
                      decoration: Utils.setBackground(primaryColor, 0),
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                      alignment: Alignment.centerLeft,
                      child: Consumer<PaymentProvider>(
                        builder: (context, paymentProvider, child) {
                          return RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              text: payableAmountIs,
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  color: lightBlack,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text:
                                      "${Constant.currencySymbol}${paymentProvider.finalAmount ?? ""}",
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.normal,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /* PGs */
          Expanded(
            child: SingleChildScrollView(
              child: paymentProvider.loading
                  ? Container(
                      height: 230,
                      padding: const EdgeInsets.all(20),
                      child: Utils.pageLoader(),
                    )
                  : paymentProvider.paymentOptionModel.status == 200
                      ? paymentProvider.paymentOptionModel.result != null
                          ? ((kIsWeb) ? _buildWebPayments() : _buildPayments())
                          : const NoData(
                              title: 'no_payment', subTitle: 'no_payment_desc')
                      : const NoData(
                          title: 'no_payment', subTitle: 'no_payment_desc'),
            ),
          ),
        ],
      ),
    );
  }

  /* NOT USED */
  Widget buildWebTVPage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /* Coupon Code Box & Total Amount */
        Container(
          margin: const EdgeInsets.all(8.0),
          width: MediaQuery.of(context).size.height * 0.7,
          constraints: const BoxConstraints(minHeight: 0),
          child: Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            elevation: 5,
            color: lightBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width,
              constraints: const BoxConstraints(minHeight: 50),
              alignment: Alignment.centerLeft,
              child: Column(
                children: [
                  _buildCouponBox(),
                  const SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    constraints: const BoxConstraints(minHeight: 50),
                    decoration: Utils.setBackground(primaryColor, 0),
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                    alignment: Alignment.centerLeft,
                    child: Consumer<PaymentProvider>(
                      builder: (context, paymentProvider, child) {
                        return RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            text: payableAmountIs,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: lightBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.normal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text:
                                    "${Constant.currencySymbol}${paymentProvider.finalAmount ?? ""}",
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.normal,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /* PGs */
        Expanded(
          child: SingleChildScrollView(
            child: paymentProvider.loading
                ? Container(
                    height: 230,
                    padding: const EdgeInsets.all(20),
                    child: Utils.pageLoader(),
                  )
                : paymentProvider.paymentOptionModel.status == 200
                    ? paymentProvider.paymentOptionModel.result != null
                        ? ((kIsWeb) ? _buildWebPayments() : _buildPayments())
                        : const NoData(
                            title: 'no_payment', subTitle: 'no_payment_desc')
                    : const NoData(
                        title: 'no_payment', subTitle: 'no_payment_desc'),
          ),
        ),
      ],
    );
  }
  /* NOT USED */

  Widget _buildCouponBox() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: Border.all(color: primaryDark, width: 0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: TextField(
                onSubmitted: (value) async {
                  if (value.isNotEmpty) {
                    strCouponCode = value.toString();
                    applyCoupon();
                  } else {
                    strCouponCode = "";
                  }
                  log("strCouponCode ===========> $strCouponCode");
                },
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    strCouponCode = value.toString();
                  } else {
                    strCouponCode = "";
                  }
                  log("strCouponCode ===========> $strCouponCode");
                },
                textInputAction: TextInputAction.done,
                obscureText: false,
                controller: couponController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                style: const TextStyle(
                  color: white,
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: transparentColor,
                  hintStyle: TextStyle(
                    color: otherColor,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: couponAddHint,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () async {
              debugPrint("Click on Apply!");
              log("strCouponCode ===========> $strCouponCode");
              if (strCouponCode != null && (strCouponCode ?? "").isNotEmpty) {
                applyCoupon();
              } else {
                Utils.showSnackbar(context, "info", emptyCouponMsg, false);
              }
            },
            child: Container(
              height: 30,
              constraints: const BoxConstraints(minWidth: 50),
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              decoration: Utils.setBackground(white, 5),
              alignment: Alignment.center,
              child: MyText(
                color: black,
                text: "apply",
                multilanguage: true,
                fontsizeNormal: 13,
                fontsizeWeb: 14,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontweight: FontWeight.w600,
                textalign: TextAlign.end,
                fontstyle: FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayments() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MyText(
            color: whiteLight,
            text: "payment_methods",
            fontsizeNormal: 15,
            fontsizeWeb: 17,
            maxline: 1,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w600,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 5),
          MyText(
            color: otherColor,
            text: "choose_a_payment_methods_to_pay",
            multilanguage: true,
            fontsizeNormal: 13,
            fontsizeWeb: 15,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w500,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 15),
          MyText(
            color: complimentryColor,
            text: "pay_with",
            multilanguage: true,
            fontsizeNormal: 16,
            fontsizeWeb: 16,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w700,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 20),

          /* /* Payments */ */
          /* In-App purchase */
          paymentProvider.paymentOptionModel.result?.inAppPurchage != null
              ? paymentProvider.paymentOptionModel.result?.inAppPurchage
                          ?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("inapp");
                          openPayment(pgName: "inapppurchage");
                        },
                        child: _buildPGButton(
                            "pg_inapp.png", "InApp Purchase", 35, 110),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          const SizedBox(height: 5),

          /* Paypal */
          paymentProvider.paymentOptionModel.result?.paypal != null
              ? paymentProvider.paymentOptionModel.result?.paypal?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("paypal");
                          openPayment(pgName: "paypal");
                        },
                        child:
                            _buildPGButton("pg_paypal.png", "Paypal", 35, 130),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          const SizedBox(height: 5),

          /* Razorpay */
          paymentProvider.paymentOptionModel.result?.razorpay != null
              ? paymentProvider
                          .paymentOptionModel.result?.razorpay?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("razorpay");
                          openPayment(pgName: "razorpay");
                        },
                        child: _buildPGButton(
                            "pg_razorpay.png", "Razorpay", 35, 130),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          const SizedBox(height: 5),

          /* Paytm */
          paymentProvider.paymentOptionModel.result?.payTm != null
              ? paymentProvider.paymentOptionModel.result?.payTm?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("paytm");
                          openPayment(pgName: "paytm");
                        },
                        child: _buildPGButton("pg_paytm.png", "Paytm", 30, 90),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          const SizedBox(height: 5),

          /* Flutterwave */
          paymentProvider.paymentOptionModel.result?.flutterWave != null
              ? paymentProvider
                          .paymentOptionModel.result?.flutterWave?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider
                              .setCurrentPayment("flutterwave");
                          openPayment(pgName: "flutterwave");
                        },
                        child: _buildPGButton(
                            "pg_flutterwave.png", "Flutterwave", 35, 130),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          const SizedBox(height: 5),

          /* Stripe */
          paymentProvider.paymentOptionModel.result?.stripe != null
              ? paymentProvider.paymentOptionModel.result?.stripe?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("stripe");
                          openPayment(pgName: "stripe");
                        },
                        child:
                            _buildPGButton("pg_stripe.png", "Stripe", 35, 100),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          const SizedBox(height: 5),

          /* PayUMoney */
          paymentProvider.paymentOptionModel.result?.payUMoney != null
              ? paymentProvider
                          .paymentOptionModel.result?.payUMoney?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("payumoney");
                          openPayment(pgName: "payumoney");
                        },
                        child: _buildPGButton(
                            "pg_payumoney.png", "PayU Money", 35, 130),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),

          /* Cash */
          paymentProvider.paymentOptionModel.result?.cash != null
              ? paymentProvider.paymentOptionModel.result?.cash?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("cash");
                          openPayment(pgName: "cash");
                        },
                        child: _buildPGButton("pg_cash.png", "Cash", 50, 50),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildWebPayments() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MyText(
            color: whiteLight,
            text: "payment_methods",
            fontsizeNormal: 15,
            fontsizeWeb: 17,
            maxline: 1,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w600,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 5),
          MyText(
            color: otherColor,
            text: "choose_a_payment_methods_to_pay",
            multilanguage: true,
            fontsizeNormal: 13,
            fontsizeWeb: 15,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w500,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 15),
          MyText(
            color: complimentryColor,
            text: "pay_with",
            multilanguage: true,
            fontsizeNormal: 16,
            fontsizeWeb: 16,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w700,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 20),

          /* Razorpay */
          paymentProvider.paymentOptionModel.result?.razorpay != null
              ? paymentProvider
                          .paymentOptionModel.result?.razorpay?.visibility ==
                      "1"
                  ? Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      elevation: 5,
                      color: lightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await paymentProvider.setCurrentPayment("razorpay");
                          openPayment(pgName: "razorpay");
                        },
                        child: _buildPGButton(
                            "pg_razorpay.png", "Razorpay", 35, 130),
                      ),
                    )
                  : const SizedBox.shrink()
              : const NoData(title: 'no_payment', subTitle: 'no_payment_desc'),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildPGButton(
      String imageName, String pgName, double imgHeight, double imgWidth) {
    return Container(
      constraints: const BoxConstraints(minHeight: 85),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          MyImage(
            imagePath: imageName,
            fit: BoxFit.fill,
            height: imgHeight,
            width: imgWidth,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: MyText(
              color: primaryColor,
              text: pgName,
              multilanguage: false,
              fontsizeNormal: 14,
              fontsizeWeb: 15,
              maxline: 2,
              overflow: TextOverflow.ellipsis,
              fontweight: FontWeight.w600,
              textalign: TextAlign.end,
              fontstyle: FontStyle.normal,
            ),
          ),
          const SizedBox(width: 15),
          MyImage(
            imagePath: "ic_arrow_right.png",
            fit: BoxFit.fill,
            height: 22,
            width: 20,
            color: white,
          ),
        ],
      ),
    );
  }

  /* ********* InApp purchase START ********* */
  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    final List<String> consumables = await ConsumableStore.load();
    log("consumables ======> ${consumables.length}");
    setState(() {
      _isAvailable = isAvailable;
      _consumables = consumables;
      _purchasePending = false;
      _loading = false;
    });
  }

  _initInAppPurchase() async {
    log("_initInAppPurchase _kProductIds ============> ${_kProductIds[0].toString()}");
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(_kProductIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      Utils.showToast("Please check SKU");
      return;
    }
    log("productID ============> ${response.productDetails[0].id}");
    late PurchaseParam purchaseParam;
    if (Platform.isAndroid) {
      purchaseParam =
          GooglePlayPurchaseParam(productDetails: response.productDetails[0]);
    } else {
      purchaseParam = PurchaseParam(productDetails: response.productDetails[0]);
    }
    _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam, autoConsume: false);
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          log("purchaseDetails ============> ${purchaseDetails.error.toString()}");
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          log("===> status ${purchaseDetails.status}");
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (Platform.isAndroid) {
          if (!_kAutoConsume && purchaseDetails.productID == androidPackageID) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
                _inAppPurchase.getPlatformAddition<
                    InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          log("===> pendingCompletePurchase ${purchaseDetails.pendingCompletePurchase}");
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> deliverProduct(PurchaseDetails purchaseDetails) async {
    log("===> productID ${purchaseDetails.productID}");
    if (purchaseDetails.productID == androidPackageID) {
      await ConsumableStore.save(purchaseDetails.purchaseID!);
      final List<String> consumables = await ConsumableStore.load();
      log("===> consumables $consumables");
      if (widget.payType == "Package") {
        addTransaction(widget.itemId, widget.itemTitle,
            paymentProvider.finalAmount, paymentId, widget.currency);
      } else if (widget.payType == "Rent") {
        addRentTransaction(widget.itemId, paymentProvider.finalAmount,
            widget.typeId, widget.videoType);
      }
      setState(() {
        _purchasePending = false;
        _consumables = consumables;
      });
    } else {
      log("===> consumables else $purchaseDetails");
      setState(() {
        _purchases.add(purchaseDetails);
        _purchasePending = false;
      });
    }
  }

  void showPendingUI() {
    setState(() {});
  }

  void handleError(IAPError error) {
    setState(() {});
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    return Future<bool>.value(true);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    log("invalid Purchase ===> $purchaseDetails");
  }
  /* ********* InApp purchase END ********* */

  /* ********* Razorpay START ********* */
  void _initializeRazorpay() {
    if (paymentProvider.paymentOptionModel.result?.razorpay != null) {
      Razorpay razorpay = Razorpay();
      var options = {
        'key':
            paymentProvider.paymentOptionModel.result?.razorpay?.isLive == "1"
                ? paymentProvider
                        .paymentOptionModel.result?.razorpay?.liveKey1 ??
                    ""
                : paymentProvider
                        .paymentOptionModel.result?.razorpay?.testKey1 ??
                    "",
        'currency': Constant.currency,
        'amount': (double.parse(paymentProvider.finalAmount ?? "") * 100),
        'name': widget.itemTitle ?? "",
        'description': widget.itemTitle ?? "",
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {'contact': userMobileNo, 'email': userEmail},
        'external': {
          'wallets': ['paytm']
        }
      };
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);

      try {
        razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay Error :=========> $e');
      }
    } else {
      Utils.showSnackbar(context, "", "payment_not_processed", true);
    }
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) async {
    /*
    * PaymentFailureResponse contains three values:
    * 1. Error Code
    * 2. Error Description
    * 3. Metadata
    * */
    Utils.showSnackbar(context, "fail", "payment_fail", true);
    await paymentProvider.setCurrentPayment("");
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    /*
    * Payment Success Response contains three values:
    * 1. Order ID
    * 2. Payment ID
    * 3. Signature
    * */
    // paymentId = response.paymentId;
    debugPrint("paymentId ========> $paymentId");
    Utils.showSnackbar(context, "success", "payment_success", true);
    if (widget.payType == "Package") {
      addTransaction(widget.itemId, widget.itemTitle,
          paymentProvider.finalAmount, paymentId, widget.currency);
    } else if (widget.payType == "Rent") {
      addRentTransaction(widget.itemId, paymentProvider.finalAmount,
          widget.typeId, widget.videoType);
    }
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    debugPrint("============ External Wallet Selected ============");
  }
  /* ********* Razorpay END ********* */

  /* ********* Paytm START ********* */
  Future<void> _paytmInit() async {
    if (paymentProvider.paymentOptionModel.result?.payTm != null) {
      bool payTmIsStaging;
      String payTmMerchantID,
          payTmOrderId,
          payTmCustmoreID,
          payTmChannelID,
          payTmTxnAmount,
          payTmWebsite,
          payTmCallbackURL,
          payTmIndustryTypeID;

      payTmOrderId = paymentId ?? "";
      payTmCustmoreID = "${Constant.userID}_$paymentId";
      payTmChannelID = "WAP";
      payTmTxnAmount = "${(paymentProvider.finalAmount ?? "")}.00";
      payTmIndustryTypeID = "Retail";

      if (paymentProvider.paymentOptionModel.result?.payTm?.isLive == "1") {
        payTmMerchantID =
            paymentProvider.paymentOptionModel.result?.payTm?.liveKey1 ?? "";
        payTmIsStaging = false;
        payTmWebsite = "DEFAULT";
        payTmCallbackURL =
            "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$payTmOrderId";
      } else {
        payTmMerchantID =
            paymentProvider.paymentOptionModel.result?.payTm?.testKey1 ?? "";
        payTmIsStaging = true;
        payTmWebsite = "WEBSTAGING";
        payTmCallbackURL =
            "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$payTmOrderId";
      }
      var sendMap = <String, dynamic>{
        "mid": payTmMerchantID,
        "orderId": payTmOrderId,
        "amount": payTmTxnAmount,
        "txnToken": paymentProvider.payTmModel.result?.paytmChecksum ?? "",
        "callbackUrl": payTmCallbackURL,
        "isStaging": payTmIsStaging,
        "restrictAppInvoke": true,
        "enableAssist": true,
      };
      debugPrint("sendMap ===> $sendMap");

      /* Generate CheckSum from Backend */
      await paymentProvider.getPaytmToken(
        payTmMerchantID,
        payTmOrderId,
        payTmCustmoreID,
        payTmChannelID,
        payTmTxnAmount,
        payTmWebsite,
        payTmCallbackURL,
        payTmIndustryTypeID,
      );

      if (!paymentProvider.loading) {
        if (paymentProvider.payTmModel.result != null) {
          if (paymentProvider.payTmModel.result?.paytmChecksum != null) {
            try {
              var response = AllInOneSdk.startTransaction(
                payTmMerchantID,
                payTmOrderId,
                payTmTxnAmount,
                paymentProvider.payTmModel.result?.paytmChecksum ?? "",
                payTmCallbackURL,
                payTmIsStaging,
                true,
                true,
              );
              response.then((value) {
                debugPrint("value ====> $value");
                setState(() {
                  paytmResult = value.toString();
                });
              }).catchError((onError) {
                if (onError is PlatformException) {
                  setState(() {
                    paytmResult = "${onError.message} \n  ${onError.details}";
                  });
                } else {
                  setState(() {
                    paytmResult = onError.toString();
                  });
                }
              });
            } catch (err) {
              paytmResult = err.toString();
            }
          } else {
            if (!mounted) return;
            Utils.showSnackbar(context, "", "payment_not_processed", true);
          }
        } else {
          if (!mounted) return;
          Utils.showSnackbar(context, "", "payment_not_processed", true);
        }
      }
    } else {
      Utils.showSnackbar(context, "", "payment_not_processed", true);
    }
  }
  /* ********* Paytm END ********* */

  /* ********* Paypal START ********* */
  Future<void> _paypalInit() async {
    if (paymentProvider.paymentOptionModel.result?.paypal != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => UsePaypal(
              sandboxMode: (paymentProvider
                              .paymentOptionModel.result?.paypal?.isLive ??
                          "") ==
                      "1"
                  ? false
                  : true,
              clientId:
                  paymentProvider.paymentOptionModel.result?.paypal?.isLive ==
                          "1"
                      ? paymentProvider
                              .paymentOptionModel.result?.paypal?.liveKey1 ??
                          ""
                      : paymentProvider
                              .paymentOptionModel.result?.paypal?.testKey1 ??
                          "",
              secretKey: paymentProvider
                          .paymentOptionModel.result?.paypal?.isLive ==
                      "1"
                  ? paymentProvider
                          .paymentOptionModel.result?.paypal?.liveKey2 ??
                      ""
                  : paymentProvider
                          .paymentOptionModel.result?.paypal?.testKey2 ??
                      "",
              returnURL: "return.example.com",
              cancelURL: "cancel.example.com",
              transactions: [
                {
                  "amount": {
                    "total": '${paymentProvider.finalAmount}',
                    "currency": "USD" /* Constant.currency */,
                    "details": {
                      "subtotal": '${paymentProvider.finalAmount}',
                      "shipping": '0',
                      "shipping_discount": 0
                    }
                  },
                  "description": "The payment transaction description.",
                  "item_list": {
                    "items": [
                      {
                        "name": "${widget.itemTitle}",
                        "quantity": 1,
                        "price": '${paymentProvider.finalAmount}',
                        "currency": "USD" /* Constant.currency */
                      }
                    ],
                  }
                }
              ],
              note: "Contact us for any questions on your order.",
              onSuccess: (params) async {
                debugPrint("onSuccess: ${params["paymentId"]}");
                if (widget.payType == "Package") {
                  addTransaction(
                      widget.itemId,
                      widget.itemTitle,
                      paymentProvider.finalAmount,
                      params["paymentId"],
                      widget.currency);
                } else if (widget.payType == "Rent") {
                  addRentTransaction(widget.itemId, paymentProvider.finalAmount,
                      widget.typeId, widget.videoType);
                }
              },
              onError: (params) {
                debugPrint("onError: ${params["message"]}");
                Utils.showSnackbar(
                    context, "fail", params["message"].toString(), false);
              },
              onCancel: (params) {
                debugPrint('cancelled: $params');
                Utils.showSnackbar(context, "fail", params.toString(), false);
              }),
        ),
      );
    } else {
      Utils.showSnackbar(context, "", "payment_not_processed", true);
    }
  }
  /* ********* Paypal END ********* */

  /* ********* Stripe START ********* */
  Future<void> _stripeInit() async {
    if (paymentProvider.paymentOptionModel.result?.stripe != null) {
      stripe.Stripe.publishableKey = paymentProvider
                  .paymentOptionModel.result?.stripe?.isLive ==
              "1"
          ? paymentProvider.paymentOptionModel.result?.stripe?.liveKey1 ?? ""
          : paymentProvider.paymentOptionModel.result?.stripe?.testKey1 ?? "";
      try {
        //STEP 1: Create Payment Intent
        paymentIntent = await createPaymentIntent(
            paymentProvider.finalAmount ?? "", Constant.currency);

        //STEP 2: Initialize Payment Sheet
        await stripe.Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: stripe.SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntent?['client_secret'],
              style: ThemeMode.light,
              merchantDisplayName: Constant.appName,
            ))
            .then((value) {});

        //STEP 3: Display Payment sheet
        displayPaymentSheet();
      } catch (err) {
        throw Exception(err);
      }
    } else {
      Utils.showSnackbar(context, "", "payment_not_processed", true);
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'description': widget.itemTitle,
      };

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer ${paymentProvider.paymentOptionModel.result?.stripe?.isLive == "1" ? paymentProvider.paymentOptionModel.result?.stripe?.liveKey2 ?? "" : paymentProvider.paymentOptionModel.result?.stripe?.testKey2 ?? ""}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  calculateAmount(String amount) {
    final calculatedAmout = (int.parse(amount)) * 100;
    return calculatedAmout.toString();
  }

  displayPaymentSheet() async {
    try {
      await stripe.Stripe.instance.presentPaymentSheet().then((value) {
        Utils.showSnackbar(context, "success", "payment_success", true);
        if (widget.payType == "Package") {
          addTransaction(widget.itemId, widget.itemTitle,
              paymentProvider.finalAmount, paymentId, widget.currency);
        } else if (widget.payType == "Rent") {
          addRentTransaction(widget.itemId, paymentProvider.finalAmount,
              widget.typeId, widget.videoType);
        }

        paymentIntent = null;
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on stripe.StripeException catch (e) {
      debugPrint('Error is:---> $e');
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('$e');
    }
  }
  /* ********* Stripe END ********* */

  Future<bool> onBackPressed() async {
    if (!mounted) return Future.value(false);
    Navigator.pop(context, isPaymentDone);
    return Future.value(isPaymentDone == true ? true : false);
  }
}

class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
