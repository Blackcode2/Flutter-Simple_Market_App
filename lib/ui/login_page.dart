import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'main_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Authentication(),
    );
  }
}

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SignInScreen(
              providers: [
                EmailAuthProvider(),
              ],
              footerBuilder: (context, action) {
                return ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  const MainPage()),
                          (route) => false);
                    },
                    child: const Text('Guest'));
              },
            );
          }
          return const MainPage();
        });
  }
}
