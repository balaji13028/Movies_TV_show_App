import 'dart:developer';

import 'package:dtlive/model/adventisement_model.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class AdventisementsProvider extends ChangeNotifier {
  List<AdventisementModel> adventisements = [];
  bool loading = false;
  AdventisementModel? previewsad;

  Future<void> getAdvenmtisementsList() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    var data = await ApiService().getAdvenmtisementsList();
    if (data != null) {
      adventisements = data;
    }
    debugPrint("adventisements length :==> ${adventisements.length}");
    loading = false;
    notifyListeners();
  }

  setPreviewsAd(currentAd) {
    previewsad = currentAd;
    notifyListeners();
  }

  List<AdventisementModel> filterPreviewsAd() {
    // log(previewsad?.sequence.toString());
    final adlist = adventisements.where((ad) => ad != previewsad).toList();
    notifyListeners();
    return adlist;
  }
}
