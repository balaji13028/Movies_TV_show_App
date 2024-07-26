import 'package:dtlive/model/historymodel.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class SubHistoryProvider extends ChangeNotifier {
  HistoryModel historyModel = HistoryModel();

  bool loading = false;

  Future<void> getSubscriptionList() async {
    loading = true;
    historyModel = await ApiService().subscriptionList();
    debugPrint("subscription_list status :==> ${historyModel.status}");
    debugPrint("subscription_list message :==> ${historyModel.message}");
    loading = false;
    notifyListeners();
  }

  clearProvider() {
    debugPrint("============ clearSearchProvider ============");
    historyModel = HistoryModel();
  }
}
