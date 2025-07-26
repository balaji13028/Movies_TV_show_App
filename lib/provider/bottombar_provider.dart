import 'package:flutter/material.dart';

class BottombarProvider extends ChangeNotifier {
  int selectdindex = 0;

  void onItemTapped(int index) {
    selectdindex = index;
    notifyListeners();
  }
}
