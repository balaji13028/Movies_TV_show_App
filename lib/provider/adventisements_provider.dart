import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:media9/model/adventisement_model.dart';
import 'package:media9/webservice/apiservices.dart';

class AdvertisementsProvider extends ChangeNotifier {
  List<AdvertisementModel> advertisements = [];
  bool loading = false;
  AdvertisementModel? previewsad;

  int _currentAdIndex = 0;


  Future<void> getAdvertisementsList() async {
    loading = true;
    notifyListeners();

    try {
      final data = await ApiService().getAdvenmtisementsList();

      if (data != null) {
        advertisements = List<AdvertisementModel>.from(data)
          ..sort((a, b) =>
              (a.sequence ?? 0).compareTo(b.sequence ?? 0));
      }

      _currentAdIndex = 0;

      debugPrint('Advertisements length: ${advertisements.length}');
    } catch (e) {
      debugPrint('Failed to load advertisements: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Returns the next advertisement in sequence order.
  /// Loops back to the first advertisement after the last one.
  AdvertisementModel? getNextPreviewsAd() {
    if (advertisements.isEmpty) {
      return null;
    }

    final ad = advertisements[_currentAdIndex];

    _currentAdIndex = (_currentAdIndex + 1) % advertisements.length;

    previewsad = ad;
    notifyListeners();

    return ad;
  }
}
