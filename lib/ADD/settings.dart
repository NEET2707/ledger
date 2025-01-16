import 'package:flutter/material.dart';

import '../colors.dart'; // Import your custom colors file.



// Account table field names
const String accountId = "account_id";
const String accountName = "account_name";
const String accountContact = "account_contact";
const String accountEmail = "account_email";
const String accountDescription = "account_description";
const String accountImage = "image";
const String accountTotal = "account_total";
const String accountDateAdded = "date_added";
const String accountDateModified = "date_modified";
const String accountIsDelete = "is_delete";

// Transaction table field names
const String transactionAccountId = "account_id";
const String transactionId = "transaction_id";
const String transactionAmount = "transaction_amount";
const String transactionDate = "transaction_date";
const String transactionIsDueReminder = "is_due_reminder";
const String transactionReminderDate = "reminder_date";
const String transactionIsCredited = "is_credited";
const String transactionNote = "transaction_note";
const String transactionDateAdded = "date_added";
const String transactionDateModified = "date_modified";
const String transactionIsDelete = "is_delete";


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
