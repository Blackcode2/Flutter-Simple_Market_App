import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

class ChatRoom extends StatelessWidget {
  ChatRoom({required this.doc, super.key});

  late DocumentSnapshot? doc;
  final String _userEnterMessage = '';
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: doc!['buyerDisplayName'] == _auth.currentUser!.displayName
            ? Text(doc!['sellerDisplayName'])
            : Text(doc!['buyerDisplayName']),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Message(
            doc: doc!,
          ),
          MessageTextField(
            doc: doc!,
          ),
        ],
      ),
    );
  }
}

class Message extends StatelessWidget {
  Message({required this.doc, super.key});

  late DocumentSnapshot doc;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder(
          stream: firestore
              .collection('chats')
              .doc(doc.id)
              .collection('chat')
              .orderBy('timeStamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.none) {
              return const Center(
                child: Text('Connection problem'),
              );
            }

            final chatDocs = snapshot.data?.docs;
            return ListView.builder(
                reverse: true,
                itemCount: chatDocs == null ? 0 : chatDocs.length,
                itemBuilder: (context, index) {
                  return ChatBubble(
                    message: chatDocs![index].get('text'),
                    isMe: chatDocs[index]['userUid'].toString() ==
                        _auth.currentUser!.uid,
                  );
                });
          }),
    );
  }
}

class MessageTextField extends StatelessWidget {
  MessageTextField({required this.doc, super.key});

  late DocumentSnapshot doc;

  final _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String _userEnterMessage = '';
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: Colors.grey)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              maxLines: null,
              controller: _controller,
              onChanged: (value) {
                _userEnterMessage = value;
              },
            ),
          ),
          IconButton(
              onPressed: () {
                if (_userEnterMessage.trim().isEmpty) {
                } else {
                  firestore
                      .collection('chats')
                      .doc(doc.id)
                      .collection('chat')
                      .add({
                    'text': _userEnterMessage,
                    'timeStamp': Timestamp.now(),
                    'userUid': _auth.currentUser!.uid,
                  });
                  _userEnterMessage =
                      ''; //delate what user wrote in the variable
                  _controller.clear(); // remove text from the text field
                }
              },
              icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, required this.isMe, super.key});

  final String message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.grey[300] : Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          width: MediaQuery.of(context).size.width * 0.4,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            message,
            style: TextStyle(
              color: isMe ? Colors.black : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
