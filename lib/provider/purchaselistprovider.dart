import 'dart:developer';

import 'package:media9/model/rentmodel.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
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
