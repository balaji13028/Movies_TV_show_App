import 'package:flutter/material.dart';
import 'package:media9/model/adventisement_model.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/webservice/apiservices.dart';

import '../model/poster_ads_model.dart';
import '../utils/sharedpre.dart';

class PosterAdsProvider extends ChangeNotifier {
  List<PosterAdsModel> posterAds = [];
  bool loading = false;
  PosterAdsModel? previewsAd;
  SharedPre sharedPref = SharedPre();

  Future<void> getPosterAdsList() async {
    loading = true;
    var data = await ApiService().getPosterAdsList();
    if (data != null) {
      posterAds = data;
    }
    debugPrint("posterAds length :==> ${posterAds.length}");
    loading = false;
    notifyListeners();
  }

  Future<PosterAdsModel?> getDisplayAd() async {
    // 1. Read last shown sequence
    int lastSeq = await sharedPref.readInt('posterAd') ?? 0;

    // 2. Sort ads by sequence to make sure order is correct
    posterAds.sort((a, b) => a.sequence!.compareTo(b.sequence!));

    // 3. Find the next ad
    PosterAdsModel nextAd = posterAds.firstWhere(
          (ad) => ad.sequence! > lastSeq,
      orElse: () => posterAds.first, // restart from first ad if no next ad found
    );

    // 4. Save the new sequence to shared pref for next session
    await sharedPref.saveInt('posterAd', nextAd.sequence!);

    return nextAd;
  }

  void setPreviewsAd(currentAd) {
    previewsAd = currentAd;
    notifyListeners();
  }

  List<PosterAdsModel> filterPreviewsAd() {
    // log(previewsad?.sequence.toString());
    final adlist = posterAds.where((ad) => ad != previewsAd).toList();
    notifyListeners();
    return adlist;
  }
}
