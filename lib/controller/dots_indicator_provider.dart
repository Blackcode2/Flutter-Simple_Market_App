import 'package:flutter/material.dart';

class DotsIndicatorProvider with ChangeNotifier {
  double _index = 0;
  double get index => _index;
  set index(index) {
    _index = index;
    notifyListeners();
  }
}
