import 'package:flutter/material.dart';
import 'item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'initial_profile_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    if ((_auth.currentUser != null && _auth.currentUser!.displayName == null) ||
        (_auth.currentUser != null &&
            _auth.currentUser!.displayName!.isEmpty)) {
      Future.delayed(Duration.zero, () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => InitialUserNamePage()),
            (route) => false);
      });
      //"setState() or markNeedsBuild() called during build" error.
      //This error happens when you try to show a snack bar or alert dialog before the completion of the widget build.
    }

    return StreamBuilder(
      stream: firestore.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        List<DocumentSnapshot>? docs = snapshot.data?.docs;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
              itemCount: docs?.length ?? 0,
              itemBuilder: (BuildContext ctx, int idx) {
                return Item(
                  doc: docs![idx],
                );
              }),
        );
      },
    );
  }
}
