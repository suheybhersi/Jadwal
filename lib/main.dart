import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jadwal/firebase_options.dart';
import 'package:jadwal/pages/auth/auth_page.dart';
import 'package:jadwal/services/connectivity_service.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: "assets/.env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityService()),
        ChangeNotifierProvider(
            create: (context) => FirestoreService(
                auth: FirebaseAuth.instance,
                uid: FirebaseAuth.instance.currentUser!.uid,
                connectivityService:
                    Provider.of<ConnectivityService>(context, listen: false))),
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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
