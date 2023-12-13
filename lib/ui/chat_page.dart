import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_market/ui/chat_room_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // to know how mayn chat rooms are open for current usr and chat room IDs.
    return StreamBuilder(
        stream: firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('chats')
            .snapshots(),
        builder: (context, snapshot1) {
          List<DocumentSnapshot>? docs = snapshot1.data?.docs;

          return ListView.builder(
              itemCount: docs?.length ?? 0,
              itemBuilder: (BuildContext ctx, int idx) {
                if (docs == null || docs.isEmpty) {
                  const Text('There no chat room yet!');
                }
                // text message data for preview
                return StreamBuilder(
                    stream: firestore
                        .collection('chats')
                        .doc(docs![idx].get('chatId'))
                        .collection('chat')
                        .orderBy('timeStamp', descending: true)
                        .limit(1) // load only one document data
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
                        chatId: docs[idx].get('chatId'),
                        chat: snapshot2.data?.docs,
                      );
                    });
              });
        });
  }
}

class ChatPreview extends StatelessWidget {
  ChatPreview({required this.chatId, required this.chat, super.key});

  late String chatId;
  late List<QueryDocumentSnapshot<Map<String, dynamic>>>? chat;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late DocumentSnapshot<Map<String, dynamic>>? doc;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: firestore
            .collection('chats')
            .doc(chatId)
            .get(), // chat room users information
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          doc = snapshot.data;
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
                            doc!.get('buyerDisplayName') ==
                                    _auth.currentUser!.displayName
                                ? Text(doc!.get('sellerDisplayName'))
                                : Text(doc!.get('buyerDisplayName')),
                            chat == null || chat!.isEmpty
                                ? const Text('')
                                : Text(chat!.first['text'] ?? ''),
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
        });
  }
}
