// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui;
//import 'package:simple_app/screens/main_screen.dart';
//import 'package:simple_app/screens/login_screen.dart';
import 'firebase_options.dart';
import 'core/app_routes.dart';
import 'core/theme_provider.dart';

void main() async {
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
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Banigoba',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primarySwatch: Colors.indigo,
          ),
          initialRoute: AppRoutes.root,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
