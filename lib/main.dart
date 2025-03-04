import 'package:mpl_lab/auth/login_page.dart';
import 'package:mpl_lab/splash.dart';
import 'package:mpl_lab/pages/home_page.dart';
import 'package:mpl_lab/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MPL Lab',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Montserrat',
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const Home(),
      },
    );
  }
}
