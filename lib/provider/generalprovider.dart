import 'dart:io';

import 'package:dtlive/model/generalsettingmodel.dart';
import 'package:dtlive/model/loginregistermodel.dart';
import 'package:dtlive/model/pagesmodel.dart';
import 'package:dtlive/model/sociallinkmodel.dart';
import 'package:dtlive/utils/sharedpre.dart';
import 'package:dtlive/webservice/apiservices.dart';
import 'package:flutter/material.dart';

class GeneralProvider extends ChangeNotifier {
  GeneralSettingModel generalSettingModel = GeneralSettingModel();
  PagesModel pagesModel = PagesModel();
  SocialLinkModel socialLinkModel = SocialLinkModel();
  LoginRegisterModel loginSocialModel = LoginRegisterModel();
  LoginRegisterModel loginOTPModel = LoginRegisterModel();
  LoginRegisterModel loginTVModel = LoginRegisterModel();

  bool loading = false;

  SharedPre sharedPre = SharedPre();

  Future<void> getGeneralsetting() async {
    loading = true;
    generalSettingModel = await ApiService().genaralSetting();
    debugPrint("genaral_setting status :==> ${generalSettingModel.status}");
    loading = false;
    debugPrint('generalSettingData status ==> ${generalSettingModel.status}');
    if (generalSettingModel.status == 200) {
      if (generalSettingModel.result != null) {
        for (var i = 0; i < (generalSettingModel.result?.length ?? 0); i++) {
          await sharedPre.save(
            generalSettingModel.result?[i].key.toString() ?? "",
            generalSettingModel.result?[i].value.toString() ?? "",
          );
          debugPrint(
              '${generalSettingModel.result?[i].key.toString()} ==> ${generalSettingModel.result?[i].value.toString()}');
        }
      }
    }
  }

  Future<void> getPages() async {
    loading = true;
    pagesModel = await ApiService().getPages();
    debugPrint("getPages status :==> ${pagesModel.status}");
    loading = false;
    notifyListeners();
  }

  Future<void> getSocialLinks() async {
    loading = true;
    socialLinkModel = await ApiService().getSocialLink();
    debugPrint("getSocialLinks status :==> ${socialLinkModel.status}");
    loading = false;
    notifyListeners();
  }

  Future<void> loginWithSocial(email, name, type, File? profileImg) async {
    debugPrint("loginWithSocial email :==> $email");
    debugPrint("loginWithSocial name :==> $name");
    debugPrint("loginWithSocial type :==> $type");
    debugPrint("loginWithSocial profileImg :==> ${profileImg?.path}");

    loading = true;
    loginSocialModel =
        await ApiService().loginWithSocial(email, name, type, profileImg);
    debugPrint("loginWithSocial status :==> ${loginSocialModel.status}");
    debugPrint("loginWithSocial message :==> ${loginSocialModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> loginWithOTP(mobile) async {
    debugPrint("getLoginOTP mobile :==> $mobile");

    loading = true;
    loginOTPModel = await ApiService().loginWithOTP(mobile);
    debugPrint("login status :==> ${loginOTPModel.status}");
    debugPrint("login message :==> ${loginOTPModel.message}");
    loading = false;
    notifyListeners();
  }

  Future<void> loginWithTV(strOTP) async {
    debugPrint("loginWithTV strOTP :==> $strOTP");

    loading = true;
    loginTVModel = await ApiService().tvLogin(strOTP);
    debugPrint("loginWithTV status :===> ${loginTVModel.status}");
    debugPrint("loginWithTV message :==> ${loginTVModel.message}");
    loading = false;
    notifyListeners();
  }
}
