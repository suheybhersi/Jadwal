import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/firebase_options.dart';
import 'package:hifdh_planner_app/pages/first_page.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:hifdh_planner_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FirestoreService()),
        ChangeNotifierProvider(create: ((context) => ThemeProvider())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FirstPage(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
