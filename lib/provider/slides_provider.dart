import 'package:media9/model/slides_model.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class SlidesProvider extends ChangeNotifier {
  List<SlidesModel> slides = [];
  bool loading = false;
  int? currentSlideIndex = 0;

  Future<void> getSlides() async {
    debugPrint("slides userID :==> ${Constant.userID}");
    loading = true;
    var data = await ApiService().getSlidesList();
    if (data != null) {
      slides = data;
    }
    debugPrint("slides data :==> ${slides.length}");
    loading = false;
    notifyListeners();
  }

  setCurrentBanner(index) {
    currentSlideIndex = index;
    notifyListeners();
  }
}
