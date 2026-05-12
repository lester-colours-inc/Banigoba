import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text("Overview", style: TextStyle(color: Colors.grey, fontSize: 12)),
                _buildDrawerItem(Icons.grid_view, "My Fashion Style"),
                _buildDrawerItem(Icons.shopping_bag, "My Smart Wardrobe"),
                _buildDrawerItem(Icons.store, "Shops & Boutiques"),
                _buildDrawerItem(Icons.brush, "Fashion Designers"),
                _buildDrawerItem(Icons.people, "Agents"),
                _buildDrawerItem(Icons.work, "Curators Workspace"),
                const SizedBox(height: 20),
                const Text("Account", style: TextStyle(color: Colors.grey, fontSize: 12)),
                _buildDrawerItem(Icons.chat_bubble_outline, "Chat"),
                _buildDrawerItem(Icons.settings_outlined, "Settings"),
                _buildDrawerItem(Icons.logout, "Logout", onTap: () => FirebaseAuth.instance.signOut()),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF0D0140), child: Text("JD", style: TextStyle(color: Colors.white))),
            title: const Text("john doe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text("j.doe2541@gmail.com", style: TextStyle(fontSize: 10)),
            trailing: Switch(value: true, onChanged: (v) {}, activeTrackColor: const Color(0xFF0D0140)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
