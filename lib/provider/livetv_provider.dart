import 'package:dtlive/model/live_tv_model.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class LivetvProvider extends ChangeNotifier {
  List<LiveTvModel> liveTvlist = [];
  bool loading = false;

  Future<void> getTvShowsList() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    var data = await ApiService().getLiveTvList();
    if (data != null) {
      liveTvlist = data.reversed.toList();
    }
    debugPrint("livetv_list data :==> ${liveTvlist.length}");
    loading = false;
    notifyListeners();
  }

  Future<void> onRefresh() async {
    loading = true;
    liveTvlist = [];
    notifyListeners();

    var data = await ApiService().getLiveTvList();
    if (data != null) {
      liveTvlist = data.reversed.toList();
    }
    debugPrint("livetv_list data :==> ${liveTvlist.length}");
    loading = false;
    notifyListeners();
  }
}
