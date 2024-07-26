import 'package:dtlive/model/castdetailmodel.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class CastDetailsProvider extends ChangeNotifier {
  CastDetailModel castDetailModel = CastDetailModel();

  bool loading = false;

  Future<void> getCastDetails(castID) async {
    loading = true;
    castDetailModel = await ApiService().getCastDetails(castID);
    debugPrint("getCastDetails status :==> ${castDetailModel.status}");
    loading = false;
    notifyListeners();
  }

  clearProvider() {
    castDetailModel = CastDetailModel();
  }
}
