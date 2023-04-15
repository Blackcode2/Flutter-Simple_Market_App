import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:simple_market/controller/dots_indicator_provider.dart';
import 'package:provider/provider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'main_page.dart';
import 'post_page.dart';
import 'chat_room_page.dart';

class ItemDetailPage extends StatefulWidget {
  ItemDetailPage({required this.doc, super.key});

  DocumentSnapshot doc;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  late DotsIndicatorProvider _dotsIndicatorProvider;
  final _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final CarouselController controller = CarouselController();
    Size size = MediaQuery.of(context).size;
    _dotsIndicatorProvider =
        Provider.of<DotsIndicatorProvider>(context, listen: true);

    List imgsList = widget.doc['imgs'].toList();

    List imgList = [];
    for (var uri in imgsList) {
      imgList.add(Image.network(uri));
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, //색변경
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      if (_auth.currentUser!.uid == widget.doc['uid']) {
                        return DeleteEditButton(
                          imgList: imgList,
                          doc: widget.doc,
                        );
                      } else {
                        return SizedBox(
                          height: size.height * 0.2,
                          child: Column(
                            children: [
                              TextButton(
                                  onPressed: () {},
                                  child: const Text('Report')),
                              const Divider(
                                thickness: 1,
                              ),
                              TextButton(
                                child: const Text('Done!'),
                                onPressed: () => Navigator.pop(context),
                              )
                            ],
                          ),
                        );
                      }
                    });
              },
              icon: const Icon(Icons.more_vert))
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            CarouselSlider(
              carouselController: controller,
              options: CarouselOptions(
                  height: size.height * 0.5,
                  onPageChanged: ((index, reason) {
                    _dotsIndicatorProvider.index = index.toDouble();
                  })),
              items: imgList.map((img) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(color: Colors.black, child: img);
                  },
                );
              }).toList(),
            ),
            Positioned(
              top: size.height * 0.45,
              left: size.width * 0.45,
              child: DotsIndicator(
                decorator: const DotsDecorator(
                  color: Colors.white, // Inactive color
                  activeColor: Color.fromARGB(255, 192, 189, 189),
                ),
                dotsCount: imgList.length,
                position:
                    Provider.of<DotsIndicatorProvider>(context, listen: false)
                        .index
                        .toDouble(),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black,
                ),
                const SizedBox(
                  width: 12,
                ),
                // user name, location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doc['displayName'],
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(widget.doc['location']),
                  ],
                ),
              ],
            ),
          ),
          const Divider(
            height: 8,
            thickness: 1,
            color: Color.fromARGB(255, 173, 172, 172),
            indent: 20.0,
            endIndent: 20.0,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doc['title'],
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                Text(
                  widget.doc['description'],
                  style: const TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: size.height * 0.1,
          color: Colors.transparent,
          child: Row(
            children: [
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border_outlined)),
              const VerticalDivider(
                thickness: 1.0,
                color: Colors.grey,
                width: 10.0,
              ),
              const SizedBox(
                width: 10.0,
              ),
              Text(
                '\$${widget.doc['price']}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: size.width * 0.43,
              ),
              ElevatedButton(
                // Button to start chatting
                onPressed: () async {
                  late bool isChatRoomExist;
                  late String chatId;
                  await firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .collection('chats')
                      .doc(widget.doc['uid'])
                      .get()
                      .then((value) {
                    isChatRoomExist = value.exists;
                    if (value.exists) {
                      chatId = value.get('chatId');
                    }
                  });

                  if (isChatRoomExist) {
                    await firestore
                        .collection('chats')
                        .doc(chatId)
                        .get()
                        .then((value) {
                      if (!mounted) return;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatRoom(doc: value)));
                    });

                    // 기존 챗룸으로
                  } else {
                    final chatId = firestore
                        .collection('chats')
                        .doc()
                        .id; // chats 콜렉션에 새로운 랜덤 도큐멘트 생성

                    //생긴 채팅방 도큐먼트에 판매자와 구매자 정보 입력
                    await firestore.collection('chats').doc(chatId).set({
                      'sellerUid': widget.doc['uid'],
                      'sellerDisplayName': widget.doc['displayName'],
                      'buyerUid': _auth.currentUser!.uid,
                      'buyerDisplayName': _auth.currentUser!.displayName,
                    });

                    late DocumentSnapshot<Map<String, dynamic>>? doc;
                    await firestore
                        .collection('chats')
                        .doc(chatId)
                        .collection('chat')
                        .doc()
                        .get()
                        .then((value) {
                      doc = value;
                    });

                    // 구매자의 users collection에 채팅방 uid 저장
                    firestore
                        .collection('users')
                        .doc(_auth.currentUser!.uid)
                        .collection('chats')
                        .doc(widget.doc['uid'])
                        .set({
                      'chatId': chatId,
                    });

                    //판매자의 users collection에 채팅방 uid 저장
                    firestore
                        .collection('users')
                        .doc(widget.doc['uid'])
                        .collection('chats')
                        .doc(_auth.currentUser!.uid)
                        .set({
                      'chatId': chatId,
                    });

                    if (!mounted) return;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChatRoom(doc: doc)));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA83918),
                ),
                child: const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeleteEditButton extends StatefulWidget {
  DeleteEditButton({required this.imgList, required this.doc, super.key});

  late List imgList;
  DocumentSnapshot doc;

  @override
  State<DeleteEditButton> createState() => _DeleteEditButtonState();
}

class _DeleteEditButtonState extends State<DeleteEditButton> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.35,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Report',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const Divider(
              thickness: 1,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UpdatePage(imgList: widget.imgList, doc: widget.doc),
                    ));
              },
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const Divider(
              thickness: 1,
            ),
            TextButton(
              onPressed: () async {
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return const AlertDialog(
                        content: Text('Deleting...'),
                        actions: [
                          Center(
                            child: CircularProgressIndicator(),
                          )
                        ],
                      );
                    });
                await firestore
                    .collection('items')
                    .doc(widget.doc['item'])
                    .delete();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => const MainPage()),
                    (route) => false);
              },
              child: const Text('Delete'),
            ),
            const Divider(
              thickness: 1,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
