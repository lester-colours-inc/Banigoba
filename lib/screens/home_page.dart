import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_drawer.dart';
import '../main.dart';
import '../services/notification_service.dart';
import 'notifications_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          StreamBuilder<int>(
            stream: notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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

