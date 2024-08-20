import 'dart:developer';

import 'package:media9/model/subscriptionmodel.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel subscriptionModel = SubscriptionModel();

  bool loading = false;

  Future<void> getPackages() async {
    debugPrint("getPackages userID :==> ${Constant.userID}");
    loading = true;
    subscriptionModel = await ApiService().subscriptionPackage();
    debugPrint("get_package status :==> ${subscriptionModel.status}");
    debugPrint("get_package message :==> ${subscriptionModel.message}");
    loading = false;
    notifyListeners();
  }

  clearProvider() {
    log("<================ clearSubscriptionProvider ================>");
    subscriptionModel = SubscriptionModel();
  }
}
