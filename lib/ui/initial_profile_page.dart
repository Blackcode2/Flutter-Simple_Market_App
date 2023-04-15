import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_market/controller/image_picker_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:simple_market/ui/main_page.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InitialUserNamePage extends StatelessWidget {
  InitialUserNamePage({super.key});

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late ImagePickerProvider _imagePickerProvider;
  XFile? image;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  Future<void> setName(String name, XFile? image) async {
    await firestore
        .collection('users')
        .doc("displayedName")
        .update({_auth.currentUser!.uid: name});
    await _auth.currentUser!.updateDisplayName(name);

    if (image != null) {
      final refImage = FirebaseStorage.instance
          .ref()
          .child("profileImages")
          .child("${_auth.currentUser!.uid}.png");
      await refImage.putFile(File(image.path));
      final uri = await refImage.getDownloadURL();
      await _auth.currentUser!.updatePhotoURL(uri);
    } else {
      final refImage = FirebaseStorage.instance
          .ref()
          .child("profileImages")
          .child('basicProfileImage.png');
      final uri = await refImage.getDownloadURL();
      await _auth.currentUser!.updatePhotoURL(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    _imagePickerProvider = Provider.of<ImagePickerProvider>(context);

    late bool isAlready;
    String? name = '';

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 30, 12, 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50.0,
                backgroundColor: const Color.fromARGB(255, 218, 214, 214),
                child: _imagePickerProvider.image != null
                    ? Image.file(File(_imagePickerProvider.image!.path))
                    : const Icon(
                        Icons.account_circle_outlined,
                        size: 100,
                      ),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed: () async {
                  image = await _picker.pickImage(source: ImageSource.gallery);
                  _imagePickerProvider.image = image;
                },
                style: ButtonStyle(
                  enableFeedback: false,
                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0))),
                ),
                child: const Text('Image'),
              ),
              const SizedBox(
                height: 30,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                          label: Text('Create your Nickname.'),
                          hintText: 'User Name',
                          border: OutlineInputBorder()),
                      onSaved: (value) {
                        name = value;
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'must create your nick name';
                        } else if (value.isNotEmpty && isAlready == true) {
                          return 'this name already exists';
                        } else if (value.isNotEmpty && isAlready == false) {
                          setName(value, _imagePickerProvider.image).then(
                            (value) {
                              firestore
                                  .collection('users')
                                  .doc(_auth.currentUser!.uid);
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          const MainPage()),
                                  (route) => false);
                            },
                          );
                        }
                        return null;

                        // 서버로 보내고 중복 닉네임이 있는지 확인
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
                onPressed: () {
                  firestore
                      .collection('users')
                      .doc("displayedName")
                      .get()
                      .then((value) {
                    _formKey.currentState!.save();
                    isAlready = value.data()!.containsValue(name);
                    _formKey.currentState!.validate();
                  });
                },
                child: const Text("OK"))
          ],
        ),
      ),
    );
  }
}
