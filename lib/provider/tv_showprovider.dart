import 'package:dtlive/model/tvshowmodel.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class TvShowprovider extends ChangeNotifier {
  List<TvShowModel> tvshows = [];
  bool loading = false;

  Future<void> getTvShowsList() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    var data = await ApiService().getTvvShowsList();
    if (data != null) {
      tvshows = data;
    }
    debugPrint("tvshows_list data :==> ${tvshows.length}");
    loading = false;
    notifyListeners();
  }
}
