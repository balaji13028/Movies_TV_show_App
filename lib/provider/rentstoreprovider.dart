import 'dart:developer';

import 'package:media9/model/rentmodel.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class RentStoreProvider extends ChangeNotifier {
  RentModel rentModel = RentModel();

  bool loading = false;

  Future<void> getRentVideoList() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    rentModel = await ApiService().rentVideoList();
    debugPrint("rent_video_list status :==> ${rentModel.status}");
    debugPrint("rent_video_list message :==> ${rentModel.message}");
    loading = false;
    notifyListeners();
  }

  clearRentStoreProvider() {
    log("<================ clearRentStoreProvider ================>");
    rentModel = RentModel();
  }
}
