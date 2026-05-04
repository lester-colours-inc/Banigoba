import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_drawer.dart';
import '../main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(themeProvider: themeProvider),
      body: Center(
        child: ElevatedButton(
          child: const Text("Open AR Glasses"),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.camera);
          },
        ),
      ),
    );
  }
}

