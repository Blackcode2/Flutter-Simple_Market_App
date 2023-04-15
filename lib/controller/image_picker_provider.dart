import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerProvider with ChangeNotifier {
  XFile? _image;
  XFile? get image => _image;
  set image(image) {
    _image = image;
    notifyListeners();
  }

  List<XFile>? _pickedImgs = [];
  List<XFile>? get pickedImgs => _pickedImgs;
  set pickedImgs(pickedImgs) {
    _pickedImgs = pickedImgs;
    notifyListeners();
  }
}
