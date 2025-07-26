import 'package:media9/model/avatarmodel.dart';
import 'package:media9/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class AvatarProvider extends ChangeNotifier {
  AvatarModel avatarModel = AvatarModel();

  bool loading = false;

  Future<void> getAvatar() async {
    loading = true;
    avatarModel = await ApiService().getAvatar();
    debugPrint("getAvatar status :==> ${avatarModel.status}");
    loading = false;
    notifyListeners();
  }

  clearProvider() {
    avatarModel = AvatarModel();
  }
}
