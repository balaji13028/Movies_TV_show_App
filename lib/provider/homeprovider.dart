import 'package:dtlive/model/sectiontypemodel.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  SectionTypeModel sectionTypeModel = SectionTypeModel();

  bool loading = false;
  int selectedIndex = 0;
  String currentPage = "";

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
