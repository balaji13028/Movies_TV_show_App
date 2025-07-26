import 'package:media9/model/menulist_model.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class MenulistProvider extends ChangeNotifier {
  List<MenulistModel> menulist = [];
  bool loading = false;

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
}
