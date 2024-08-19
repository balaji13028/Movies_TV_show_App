import 'package:dtlive/model/live_tv_model.dart';
import 'package:dtlive/model/menulist_model.dart';
import 'package:dtlive/model/sectiontypemodel.dart';
import 'package:dtlive/model/tvshowmodel.dart';
import 'package:dtlive/provider/adventisements_provider.dart';
import 'package:dtlive/provider/slides_provider.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> onRfresh(context) async {
    loading = true;
    listData?.clear();
    livetVList = [];
    tvshowsList = [];
    notifyListeners();
    final slidesProvider = Provider.of<SlidesProvider>(context, listen: false);
    final adeventisementProvider =
        Provider.of<AdventisementsProvider>(context, listen: false);
    // await homeProvider.getMenuList();
    if (adeventisementProvider.adventisements.isEmpty) {
      await adeventisementProvider.getAdvenmtisementsList();
    }
    if (slidesProvider.slides.isEmpty) {
      await slidesProvider.getSlides();
    }
    await gethomeScreenData();
  }

  List<MenulistModel> menulist = [];

  Future<void> getMenuList() async {
    debugPrint("getRentVideoList userID :==> ${Constant.userID}");
    loading = true;
    var data = await ApiService().getMenuList();
    if (data != null) {
      menulist = data;
    }
    debugPrint("menulist length :==> ${menulist.length}");
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
