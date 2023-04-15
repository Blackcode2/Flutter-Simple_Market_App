import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'color_schemes.g.dart';
import 'ui/login_page.dart';
import 'package:provider/provider.dart';
import 'controller/dots_indicator_provider.dart';
import 'controller/image_picker_provider.dart';
import 'controller/text_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (BuildContext context) => DotsIndicatorProvider()),
        ChangeNotifierProvider(
            create: (BuildContext context) => ImagePickerProvider()),
        ChangeNotifierProvider(create: (context) {
          return TextPorvider();
        })
      ],
      child: MaterialApp(
          title: 'Simple Market',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
          ),
          themeMode: ThemeMode.system,
          home: const LoginPage()),
    );
  }
}
