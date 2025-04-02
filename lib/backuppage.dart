import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'DataBase/sharedpreferences.dart';
import 'color/colors.dart';
import 'DataBase/database_helper.dart';

class BackupPage extends StatefulWidget {
  @override
  _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String storageBackupStatus = "";
  String lastBackupTime = "";


  void backupDatabase() async {
    bool success = await DatabaseHelper.backupDatabase();
    if (success) {
      await _saveLastBackupTime();
    }
  }

  void restoreDatabase() async {
    bool success = await DatabaseHelper.restoreDatabase();
    if (success) {
      // await _saveLastRestoreTime();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLastBackupRestoreTimes();
  }


  Future<void> _loadLastBackupRestoreTimes() async {
    String? saveddate = await SharedPreferenceHelper.get(prefKey: PrefKey.password);
    if (saveddate != null && saveddate.isNotEmpty) {
      setState(() {
        lastBackupTime = DateFormat("dd MMMM yyyy hh:mm a").format(DateTime.parse(saveddate));
      });
    }
  }


  Future<void> _saveLastBackupTime() async {
    String currentTime = DateTime.now().toString();
    await SharedPreferenceHelper.save(value: currentTime, prefKey: PrefKey.password);
    setState(() {
      lastBackupTime = currentTime;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(
        foregroundColor: Colors.white,
          backgroundColor: themecolor,
          title: Text("Backup And Restore")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Storage Backup & Restore", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Back up your Accounts and Ledger Book to your Internal storage. You can restore it from Backup file."),
                    SizedBox(height: 8),
                    Text("$storageBackupStatus", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                        lastBackupTime == ""
                            ? ""
                            : "Last Backup: $lastBackupTime",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: backupDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themecolor, // Set custom background color
                        ),
                        child: Text("Backup",style: TextStyle(color: Colors.white),),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: restoreDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themecolor, // Set custom background color
                        ),
                        child: Text("Restore",style: TextStyle(color: Colors.white),),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
