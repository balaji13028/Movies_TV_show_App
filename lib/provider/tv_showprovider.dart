import 'package:media9/model/tvshowmodel.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class TvShowprovider extends ChangeNotifier {
  List<TvShowModel> tvshows = [];
  bool loading = false;

  Future<void> getTvShowsList() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    var data = await ApiService().getTvvShowsList();
    if (data != null) {
      tvshows = data.reversed.toList();
    }
    debugPrint("tvshows_list data :==> ${tvshows.length}");
    loading = false;
    notifyListeners();
  }

  Future<void> onRefresh() async {
    loading = true;
    tvshows = [];
    notifyListeners();
    var data = await ApiService().getTvvShowsList();
    if (data != null) {
      tvshows = data.reversed.toList();
    }
    debugPrint("tvshows_list data :==> ${tvshows.length}");
    loading = false;
    notifyListeners();
  }
}
