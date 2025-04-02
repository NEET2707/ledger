import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledger/account_data.dart';
import 'package:url_launcher/url_launcher.dart';
import '../DataBase/database_helper.dart';
import 'ADD/add_transaction.dart';
import 'notification_service.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({Key? key}) : super(key: key);

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> todayReminders = [];
  List<Map<String, dynamic>> upcomingReminders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadReminders();
  }


  Future<void> loadReminders() async {
    final db = DatabaseHelper.instance;
    List<Map<String, dynamic>> allReminders = await db.getReminderTransactions();
    final today = DateTime.now();

    todayReminders = allReminders.where((tx) {
      final rawDate = tx['reminder_date'];
      if (rawDate == null || rawDate.toString().trim().isEmpty) return false;

      try {
        final date = DateTime.parse(rawDate);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      } catch (e) {
        print("Invalid reminder_date: $rawDate");
        return false;
      }
    }).toList();

    // **Filter upcoming reminders**
    upcomingReminders = allReminders.where((tx) {
      final rawDate = tx['reminder_date'];
      if (rawDate == null || rawDate.toString().trim().isEmpty) return false;

      try {
        final date = DateTime.parse(rawDate);
        return date.isAfter(today); // ✅ Shows future reminders
      } catch (e) {
        print("Invalid reminder_date: $rawDate");
        return false;
      }
    }).toList();

    setState(() {});
    await NotificationService.scheduleDailyReminderNotification(todayReminders);
  }


  Future<void> _launchUrl(String links) async {
    final Uri _url = Uri.parse(links);
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  Widget buildReminderCard(Map<String, dynamic> tx) {
    final isCredited = tx['is_credited'] == 1;
    final amount = tx['transaction_amount'];
    final name = tx['account_name'] ?? '';
    final phone = tx['account_contact'] ?? '';
    final date = DateFormat('dd MMM yyyy').format(DateTime.parse(tx['reminder_date']));

    print("credittttttttttttttttttt");
    print(isCredited);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredited ? Colors.green : Colors.red,
              child: Icon(Icons.swap_horiz, color: Colors.white),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(date, style: const TextStyle(color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 4),
                if (phone.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _launchUrl('tel:$phone');
                    },
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Amount: ₹$amount',
                  style: TextStyle(color: isCredited ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () async {
                  final name = tx['account_name'] ?? '';
                  final num = tx['account_contact'] ?? '';
                  final id = tx['account_id'].toString();
                  final tid = tx['transaction_id'].toString();

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransaction(
                        name: name,
                        // num: num,
                        id: id,
                        tid: tid,
                        reminderflag: true,
                        amountFromReminder: amount,
                        iscredit: isCredited,
                      ),
                    ),
                  );

                  if (result == true) {
                    // Delete the old reminder transaction
                    final db = await DatabaseHelper.instance.database;
                    await db.delete(
                      'transactions',
                      where: 'transaction_id = ?',
                      whereArgs: [int.parse(tid)],
                    );

                    // Insert opposite (credit) transaction
                    final newTx = {
                      'transaction_amount': tx['transaction_amount'],
                      'transaction_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'is_credited': tx['is_credited'] == 1 ? 0 : 1, // ✅ CORRECT KEY
                      'transaction_note': 'From Reminder',
                      'reminder_date': null, // ✅ Correct key
                      'is_due_reminder': 0,
                      'account_id': tx['account_id'],
                    };
                    await db.insert('transactions', newTx);

                    // Refresh reminders
                    await loadReminders();
                  }
                },
                child: const Text("Receive"),
              ),

              TextButton(
                onPressed: () {
                  final name = tx['account_name'] ?? '';
                  final num = tx['account_contact'] ?? '';
                  final id = tx['account_id'].toString();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountData(
                        name: name,
                        num: num,
                        id: id,
                      ),
                    ),
                  );
                },
                child: const Text("View"),
              ),

            ],
          )
        ],
      ),
    );
  }

  Widget buildReminderList(List<Map<String, dynamic>> reminders) {
    if (reminders.isEmpty) {
      return const Center(child: Text("No reminders."));
    }
    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        return buildReminderCard(reminders[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: (){
            Navigator.pop(context,true);
          },

        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TODAY'),
            Tab(text: 'UPCOMING'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildReminderList(todayReminders),
          buildReminderList(upcomingReminders),
        ],
      ),
    );
  }
}