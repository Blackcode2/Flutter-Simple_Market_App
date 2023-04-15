import 'package:flutter/material.dart';

class TextPorvider with ChangeNotifier {
  List<String>? _text = ['a'];
  List<String>? get text => _text;
  set text(text) {
    _text = text;
    notifyListeners();
  }
}
