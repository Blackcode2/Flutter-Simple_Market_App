import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_market/controller/image_picker_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'main_page.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late ImagePickerProvider _imagePickerProvider;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  Future<void> uploadImg(String formatDate) async {
    List<String> uriList = [];
    for (int i = 0; i < _imagePickerProvider.pickedImgs!.length; i++) {
      final refImage = FirebaseStorage.instance
          .ref()
          .child("productImg")
          .child(_auth.currentUser!.uid + formatDate)
          .child("product$i.png");
      await refImage.putFile(File(_imagePickerProvider.pickedImgs![i].path));
      final uri = await refImage.getDownloadURL();
      uriList.add(uri);
    }
    await firestore
        .collection('items')
        .doc(_auth.currentUser!.uid + formatDate)
        .update({'imgs': uriList});
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    _imagePickerProvider = Provider.of<ImagePickerProvider>(context);

    late DateTime now;
    late String formatDate;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (_imagePickerProvider.pickedImgs!.isEmpty) {
                    // when there are no pictures uploaed, warn it.
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please, upload picture of your product.'),
                      duration: Duration(seconds: 4),
                    ));
                  } else {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return const AlertDialog(
                            content: Text('uploading...'),
                            actions: [
                              Center(
                                child: CircularProgressIndicator(),
                              )
                            ],
                          );
                        });
                    // Set the name of the Firestore document
                    // by combining the user's displayed name with the current time
                    // for effective and unique document identification.
                    now = DateTime.now();
                    formatDate = DateFormat('yyyMMMdHmms').format(now);
                    await firestore
                        .collection('items')
                        .doc(_auth.currentUser!.uid + formatDate)
                        .set({
                      'uid': _auth.currentUser!.uid,
                      'displayName': _auth.currentUser!.displayName,
                      'item': _auth.currentUser!.uid + formatDate,
                    }).then((value) async {
                      await uploadImg(formatDate);
                      _formKey.currentState!.save();
                      _imagePickerProvider.pickedImgs?.clear();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  const MainPage()),
                          (route) => false);
                    });
                  }
                }
              },
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 16.0),
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(children: [
            SizedBox(
              height: size.height * 0.11,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final List<XFile> images = await _picker.pickMultiImage();
                      _imagePickerProvider.pickedImgs = images;
                    },
                    child: Container(
                      height: size.height,
                      width: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.grey,
                        ),
                      ),
                      child: const Icon(Icons.photo_camera, size: 40),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePickerProvider.pickedImgs!.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            height: 90,
                            width: 90,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(File(_imagePickerProvider
                                  .pickedImgs![index].path)),
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        hintText: 'Title', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write your title.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(_auth.currentUser!.uid + formatDate)
                          .update({'title': newValue});
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        hintText: '\$ Price', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write price of the product.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(_auth.currentUser!.uid + formatDate)
                          .update({'price': newValue});
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        hintText: 'Location', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write your loacation where you want to exchange.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(_auth.currentUser!.uid + formatDate)
                          .update({'location': newValue});
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        hintText: 'Description', border: OutlineInputBorder()),
                    maxLines: 10,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write decsription of the product.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(_auth.currentUser!.uid + formatDate)
                          .update({'description': newValue});
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// for update
class UpdatePage extends StatefulWidget {
  UpdatePage({required this.imgList, required this.doc, super.key});

  late List imgList;
  DocumentSnapshot doc;

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  late ImagePickerProvider _imagePickerProvider;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  XFile? image;

  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  Future<void> uploadImg() async {
    List<String> uriList = [];
    for (int i = 0; i < _imagePickerProvider.pickedImgs!.length; i++) {
      final refImage = FirebaseStorage.instance
          .ref()
          .child("productImg")
          .child(widget.doc['item'])
          .child("product$i.png");
      await refImage.putFile(File(_imagePickerProvider.pickedImgs![i].path));
      final uri = await refImage.getDownloadURL();
      uriList.add(uri);
    }
    await firestore
        .collection('items')
        .doc(widget.doc['item'])
        .update({'imgs': uriList});
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    _imagePickerProvider = Provider.of<ImagePickerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (_imagePickerProvider.pickedImgs!.isEmpty &&
                      widget.imgList.isEmpty) {
                    // when there are no pictures uploaed, warn it.
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please, upload picture of your product.'),
                      duration: Duration(seconds: 4),
                    ));
                  } else {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return const AlertDialog(
                            content: Text('uploading...'),
                            actions: [
                              Center(
                                child: CircularProgressIndicator(),
                              )
                            ],
                          );
                        });
                    if (_imagePickerProvider.pickedImgs!.isNotEmpty) {
                      await uploadImg();
                    }
                    _formKey.currentState!.save();
                    _imagePickerProvider.pickedImgs?.clear();
                    if (!mounted) return;

                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                const MainPage()),
                        (route) => false);
                  }
                }
              },
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 16.0),
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(children: [
            SizedBox(
              height: size.height * 0.11,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final List<XFile> images = await _picker.pickMultiImage();
                      _imagePickerProvider.pickedImgs = images;
                    },
                    child: Container(
                      height: size.height,
                      width: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.grey,
                        ),
                      ),
                      child: const Icon(Icons.photo_camera, size: 40),
                    ),
                  ),
                  // showing picked pictures
                  Expanded(
                    flex: 1,
                    // showing already saved pictures
                    child: _imagePickerProvider.pickedImgs!.isEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.imgList.length,
                            itemBuilder: (context, index) {
                              return SizedBox(
                                height: 90,
                                width: 90,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: widget.imgList[index],
                                ),
                              );
                            })
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagePickerProvider.pickedImgs!.length,
                            itemBuilder: (context, index) {
                              return SizedBox(
                                height: 90,
                                width: 90,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(File(_imagePickerProvider
                                      .pickedImgs![index].path)),
                                ),
                              );
                            }),
                  ),
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    initialValue: widget.doc['title'],
                    decoration: const InputDecoration(
                        hintText: 'Title', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write your title.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(widget.doc['item'])
                          .update({'title': newValue});
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    initialValue: widget.doc['price'],
                    decoration: const InputDecoration(
                        hintText: '\$ Price', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write price of the product.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(widget.doc['item'])
                          .update({'price': newValue});
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    initialValue: widget.doc['location'],
                    decoration: const InputDecoration(
                        hintText: 'Location', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write your loacation where you want to exchange.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(widget.doc['item'])
                          .update({'location': newValue});
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    initialValue: widget.doc['description'],
                    decoration: const InputDecoration(
                        hintText: 'Description', border: OutlineInputBorder()),
                    maxLines: 10,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please, write decsription of the product.';
                      }
                      return null;
                    },
                    onSaved: (newValue) async {
                      await firestore
                          .collection('items')
                          .doc(widget.doc['item'])
                          .update({'description': newValue});
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
