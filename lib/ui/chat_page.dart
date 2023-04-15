import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_market/ui/chat_room_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: firestore.collection('chats').snapshots(),
        builder: (context, snapshot1) {
          List<DocumentSnapshot>? docs = snapshot1.data?.docs;
          return ListView.builder(
              itemCount: docs?.length ?? 0,
              itemBuilder: (BuildContext ctx, int idx) {
                if (docs == null || docs.isEmpty) {
                  const Text('There no chat room yet!');
                }
                return StreamBuilder(
                    stream: firestore
                        .collection('chats')
                        .doc(docs![idx].id)
                        .collection('chat')
                        .orderBy('timeStamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot2) {
                      if (snapshot1.connectionState ==
                              ConnectionState.waiting ||
                          snapshot2.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return ChatPreview(
                        doc: docs[idx],
                        chat: snapshot2.data?.docs,
                      );
                    });
              });
        });
  }
}

class ChatPreview extends StatelessWidget {
  ChatPreview({required this.doc, required this.chat, super.key});

  late DocumentSnapshot doc;
  late List<QueryDocumentSnapshot<Map<String, dynamic>>>? chat;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Future<Stream>? getChat() async {
  //   final snapshot = firestore
  //       .collection('chats')
  //       .doc(doc.id)
  //       .collection('chat')
  //       .snapshots();
  //   print(snapshot.first.then((value) {
  //     // snapshot의 first가 무엇을 의미하는지 알아야함
  //     print(value.docs.last['text']);
  //   }));
  //   return snapshot;
  // }

  // Future getChat() async {
  //   final chat = firestore.collection('chats').doc(doc.id).collection('chat');
  //   chat.get().then((value) {
  //     print(value.docs.last['text']);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // getChat();

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatRoom(
                      doc: doc,
                    )));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        margin: const EdgeInsets.all(8.0),
        width: MediaQuery.of(context).size.height * 1,
        color: Colors.transparent,
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 35.0,
                  backgroundColor: Color.fromARGB(255, 218, 214, 214),
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 30,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      doc['buyerDisplayName'] == _auth.currentUser!.displayName
                          ? Text(doc['sellerDisplayName'])
                          : Text(doc['buyerDisplayName']),
                      chat == null || chat!.isEmpty
                          ? const Text('')
                          : Text(chat!.first['text'] ?? ''), // 순서대로 보이게 수정 필요
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 6,
            ),
            const Divider(
              color: Colors.black,
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}
