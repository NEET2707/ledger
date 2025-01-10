import 'package:flutter/material.dart';

import '../colors.dart'; // Import your custom colors file.

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        title: Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSettingsCard(
            icon: Icons.account_circle,
            title: "All Account",
            subtitle: "Manage All Account - Edit/Delete",
          ),
          _buildSettingsCard(
            icon: Icons.payment,
            title: "All Payment",
            subtitle: "Manage All Payment - Filter/Edit/Delete",
          ),
          _buildSettingsCard(
            icon: Icons.lock,
            title: "Password Setting",
            subtitle: "Set/Reset Password",
          ),
          _buildSettingsCard(
            icon: Icons.cloud_upload,
            title: "Ledger Book Backup",
            subtitle: "Backup/Restore Your Ledger Book Entries",
          ),
          _buildSettingsCard(
            icon: Icons.currency_exchange,
            title: "Change Currency",
            subtitle: "Select Currency",
          ),
          _buildSettingsCard(
            icon: Icons.phone,
            title: "Contact Us",
            subtitle: "Communication Details",
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {
          // Add navigation or functionality here
        },
      ),
    );
  }
}
