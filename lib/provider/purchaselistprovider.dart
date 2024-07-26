import 'dart:developer';

import 'package:dtlive/model/rentmodel.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class PurchaselistProvider extends ChangeNotifier {
  RentModel rentModel = RentModel();
  bool loading = false;

  Future<void> getUserRentVideoList() async {
    debugPrint("getUserRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    rentModel = await ApiService().userRentVideoList();
    debugPrint("user_rent_video_list status :==> ${rentModel.status}");
    debugPrint("user_rent_video_list message :==> ${rentModel.message}");
    loading = false;
    notifyListeners();
  }

  clearProvider() {
    log("<================ clearProvider ================>");
    rentModel = RentModel();
  }
}
