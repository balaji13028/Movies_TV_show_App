import 'package:media9/model/live_tv_model.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
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
