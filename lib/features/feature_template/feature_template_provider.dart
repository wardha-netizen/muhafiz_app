import 'package:flutter/material.dart';

class FeatureTemplateProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Load feature data here (API/Firestore/local DB).
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _isLoading = false;
    notifyListeners();
  }
}
