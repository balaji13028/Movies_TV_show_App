import 'package:media9/model/live_tv_model.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class LivetvProvider extends ChangeNotifier {
  List<LiveTvModel> liveTvList = [];
  List<LiveTvModel> searchTvList = [];
  bool loading = false;
  final searchController = TextEditingController();

  Future<void> getTvShowsList() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    var data = await ApiService().getLiveTvList();
    if (data != null) {
      liveTvList = data.reversed.toList();
    }
    debugPrint("livetv_list data :==> ${liveTvList.length}");
    loading = false;
    notifyListeners();
  }

  Future<void> onRefresh() async {
    loading = true;
    liveTvList = [];
    notifyListeners();

    var data = await ApiService().getLiveTvList();
    if (data != null) {
      liveTvList = data.reversed.toList();
    }
    debugPrint("livetv_list data :==> ${liveTvList.length}");
    loading = false;
    notifyListeners();
  }

  /// filtering the liveTvList based on name or channel_no;
  void filterLiveTvData(String? searchText){
    searchTvList.clear();
    if(searchText!=null){
      liveTvList.forEach((tv){
        if(tv.channelName.toString().toLowerCase().contains(searchText.toLowerCase().trim()) || tv.channelNo.toString().contains(searchText)){
          if(!searchTvList.contains(tv)) {
            searchTvList.add(tv);
          }
        }
      });
    }
    notifyListeners();
  }

  void clearSearchList(){
    searchController.clear();
    searchTvList.clear();
    notifyListeners();

  }
}
