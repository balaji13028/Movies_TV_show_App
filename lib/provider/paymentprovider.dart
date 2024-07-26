import 'dart:developer';

import 'package:dtlive/model/couponmodel.dart';
import 'package:dtlive/model/paymentoptionmodel.dart';
import 'package:dtlive/model/paytmmodel.dart';
import 'package:dtlive/model/successmodel.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentOptionModel paymentOptionModel = PaymentOptionModel();
  PayTmModel payTmModel = PayTmModel();
  SuccessModel successModel = SuccessModel();
  CouponModel couponModel = CouponModel();

  bool loading = false, payLoading = false, couponLoading = false;
  String? currentPayment = "", finalAmount = "";

  Future<void> getPaymentOption() async {
    loading = true;
    paymentOptionModel = await ApiService().getPaymentOption();
    debugPrint("getPaymentOption status :==> ${paymentOptionModel.status}");
    debugPrint("getPaymentOption message :==> ${paymentOptionModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> applyPackageCouponCode(couponCode, packageId) async {
    debugPrint("applyPackageCouponCode couponCode :==> $couponCode");
    debugPrint("applyPackageCouponCode packageId :==> $packageId");
    couponLoading = true;
    couponModel = await ApiService().applyPackageCoupon(couponCode, packageId);
    debugPrint("applyPackageCouponCode status :==> ${couponModel.status}");
    debugPrint("applyPackageCouponCode message :==> ${couponModel.message}");
    couponLoading = false;
    notifyListeners();
  }

  Future<void> applyRentCouponCode(
      couponCode, videoId, typeId, videoType, price) async {
    debugPrint("applyRentCouponCode couponCode :==> $couponCode");
    debugPrint("applyRentCouponCode videoId :==> $videoId");
    debugPrint("applyRentCouponCode typeId :==> $typeId");
    debugPrint("applyRentCouponCode videoType :==> $videoType");
    debugPrint("applyRentCouponCode price :==> $price");
    couponLoading = true;
    couponModel = await ApiService()
        .applyRentCoupon(couponCode, videoId, typeId, videoType, price);
    debugPrint("applyRentCouponCode status :==> ${couponModel.status}");
    debugPrint("applyRentCouponCode message :==> ${couponModel.message}");
    couponLoading = false;
    notifyListeners();
  }

  setFinalAmount(String? amount) {
    finalAmount = amount;
    debugPrint("setFinalAmount finalAmount :==> $finalAmount");
    notifyListeners();
  }

  Future<void> getPaytmToken(merchantID, orderId, custmoreID, channelID,
      txnAmount, website, callbackURL, industryTypeID) async {
    debugPrint("getPaytmToken merchantID :=======> $merchantID");
    debugPrint("getPaytmToken orderId :==========> $orderId");
    debugPrint("getPaytmToken custmoreID :=======> $custmoreID");
    debugPrint("getPaytmToken channelID :========> $channelID");
    debugPrint("getPaytmToken txnAmount :========> $txnAmount");
    debugPrint("getPaytmToken website :==========> $merchantID");
    debugPrint("getPaytmToken callbackURL :======> $merchantID");
    debugPrint("getPaytmToken industryTypeID :===> $industryTypeID");
    loading = true;
    payTmModel = await ApiService().getPaytmToken(merchantID, orderId,
        custmoreID, channelID, txnAmount, website, callbackURL, industryTypeID);
    debugPrint("getPaytmToken status :===> ${payTmModel.status}");
    debugPrint("getPaytmToken message :==> ${payTmModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> addTransaction(packageId, description, amount, paymentId,
      currencyCode, couponCode) async {
    debugPrint("addTransaction userID :==> ${Constant.userID}");
    debugPrint("addTransaction packageId :==> $packageId");
    debugPrint("addTransaction couponCode :==> $couponCode");
    payLoading = true;
    successModel = await ApiService().addTransaction(
        packageId, description, amount, paymentId, currencyCode, couponCode);
    debugPrint("addTransaction status :==> ${successModel.status}");
    debugPrint("addTransaction message :==> ${successModel.message}");
    payLoading = false;
    notifyListeners();
  }

  Future<void> addRentTransaction(
      videoId, amount, typeId, videoType, couponCode) async {
    debugPrint("addRentTransaction userID :==> ${Constant.userID}");
    debugPrint("addRentTransaction videoId :==> $videoId");
    debugPrint("addRentTransaction couponCode :==> $couponCode");
    payLoading = true;
    successModel = await ApiService()
        .addRentTransaction(videoId, amount, typeId, videoType, couponCode);
    debugPrint("addRentTransaction status :==> ${successModel.status}");
    debugPrint("addRentTransaction message :==> ${successModel.message}");
    payLoading = false;
    notifyListeners();
  }

  setCurrentPayment(String? payment) {
    currentPayment = payment;
    notifyListeners();
  }

  clearProvider() {
    log("<================ clearProvider ================>");
    currentPayment = "";
    finalAmount = "";
    paymentOptionModel = PaymentOptionModel();
    successModel = SuccessModel();
  }
}
