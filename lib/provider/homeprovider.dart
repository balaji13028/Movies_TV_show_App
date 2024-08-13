import 'package:dtlive/model/live_tv_model.dart';
import 'package:dtlive/model/sectiontypemodel.dart';
import 'package:dtlive/model/tvshowmodel.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  SectionTypeModel sectionTypeModel = SectionTypeModel();
  List<TvShowModel> tvshowsList = [];
  List<LiveTvModel> livetVList = [];
  Map<String, dynamic>? listData = {};

  bool loading = false;
  int selectedIndex = 0;
  String currentPage = "";

  Future<void> gethomeScreenData() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    listData = await ApiService().getHomeScreenList();
    if (listData != null) {
      livetVList = List.from(listData?['livetv'])
          .map((item) => LiveTvModel.fromMap(item))
          .toList();
      tvshowsList = List.from(listData?['tvshows'])
          .map((item) => TvShowModel.fromMap(item))
          .toList();
    }
    debugPrint("livetv data :==> ${livetVList.length}");
    debugPrint("showtv data :==> ${tvshowsList.length}");
    loading = false;
    notifyListeners();
  }

  Future<void> getSectionType() async {
    loading = true;
    sectionTypeModel = await ApiService().sectionType();
    debugPrint("get_type status :==> ${sectionTypeModel.status}");
    debugPrint("get_type message :==> ${sectionTypeModel.message}");
    loading = false;
    notifyListeners();
  }

  setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  setSelectedTab(index) {
    selectedIndex = index;
    notifyListeners();
  }

  setCurrentPage(String pageName) {
    currentPage = pageName;
    notifyListeners();
  }

  homeNotifyProvider() {
    notifyListeners();
  }
}
