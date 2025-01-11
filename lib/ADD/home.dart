import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ledger/ADD/ADD/add_account.dart';
import 'package:ledger/ADD/ADD/add_transaction.dart';
import 'package:ledger/ADD/reminder.dart';
import 'package:ledger/ADD/settings.dart';
import '../account_data.dart';
import '../colors.dart';
import '../database_helper.dart'; // Import your database helper


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


class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _AllAccountsState();
}

class _AllAccountsState extends State<Home> {
  String selectedTab = "ALL";
  String tbalance = "balance";
  late Future<List<Map<String, dynamic>>> accounts;

  @override
  void initState() {
    super.initState();
    accounts = _getFilteredAccounts();
  }

  Future<List<Map<String, dynamic>>> _getFilteredAccounts() async {
    final allAccounts = await DatabaseHelper.instance.fetchAccountsWithBalance();
    if (selectedTab == "ALL") {
      return allAccounts; // Show all accounts
    } else if (selectedTab == "DEBIT") {
      // Filter for debit accounts (negative balance means debit)
      return allAccounts.where((account) => account[tbalance] < 0).toList();
    } else if (selectedTab == "CREDIT") {
      // Filter for credit accounts (positive balance means credit)
      return allAccounts.where((account) => account[tbalance] > 0).toList();
    }
    return []; // Return an empty list if no matching tab
  }

  Future<Map<String, double>> _calculateTotals() async {
    final accountList = await DatabaseHelper.instance.fetchAccountsWithBalance();

    double totalBalance = 0;
    double totalCredits = 0;
    double totalDebits = 0;

    for (var account in accountList) {
      print(account);
      final balance = account[tbalance] ?? 0.0;
      final credit = account[tbalance] > 0.0 ? account[tbalance] : 0.0;
      final debit = account[tbalance] < 0.0 ? account[tbalance] : 0.0;

      totalBalance += balance;
      totalCredits += credit;
      totalDebits += debit;
    }

    return {
      'totalBalance': totalBalance,
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themecolor,
        title: Text(
          "Ledger book",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Reminder()));
            },
            icon: Icon(Icons.notification_add, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.contact_page, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Settings()));
            },
            icon: Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        icon: Icons.add,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: Icon(Icons.account_balance_wallet, color: Colors.black),
            backgroundColor: Colors.white,
            label: 'Add Transaction',
            labelStyle: TextStyle(fontSize: 16),
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTransaction()), // Ensure TransactionPage is defined
              );

              if (shouldRefresh == true) {
                setState(() {
                  accounts = _getFilteredAccounts(); // Refresh the accounts list
                });
              }
            },
          ),

          SpeedDialChild(
            child: Icon(Icons.person_add, color: Colors.black),
            backgroundColor: Colors.white,
            label: 'Add Account',
            labelStyle: TextStyle(fontSize: 16),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddAccount()));
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current A/C Section
          FutureBuilder<Map<String, double>>(
            future: _calculateTotals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Container(
                  color: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              } else {
                final totals = snapshot.data!;
                final totalBalance = totals['totalBalance']!;
                final totalCredits = totals['totalCredits']!;
                final totalDebits = totals['totalDebits']!;

                return Container(
                  color: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Current A/C:",
                        style: TextStyle(
                            fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "₹ ${totalBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  color: Colors.white,
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.blueAccent,
                                    size: 24,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                "₹ ${totalCredits.toStringAsFixed(2)} Credit",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  color: Colors.white,
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Colors.blueAccent,
                                    size: 24,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                "₹ ${totalDebits.toStringAsFixed(2)} Debit",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          Container(
            color: Colors.blueAccent,
            child: Row(
              children: [
                _buildTabButton("ALL", selectedTab == "ALL"),
                _buildTabButton("DEBIT", selectedTab == "DEBIT"),
                _buildTabButton("CREDIT", selectedTab == "CREDIT"),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getFilteredAccounts(), // Fetch filtered accounts based on selected tab
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No accounts found'));
                } else {
                  final accountList = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ListView.separated(
                      separatorBuilder: (context, index) {
                        return Container(color: Colors.white,child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Divider(),
                        ));
                      },
                      itemCount: accountList.length,
                      itemBuilder: (context, index) {
                        final account = accountList[index];
                        final balance = account['balance'] ?? 0.0;

                        print("accccccc id _>> $account");

                        return Container(
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8), // Comfortable padding
                            leading: CircleAvatar(
                              radius: 24.0, // Larger circle avatar for emphasis
                              backgroundColor: themecolor,
                              child: Text(
                                account['account_name'][0].toUpperCase(),
                                style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  account['account_name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0, // Slightly larger font for the name
                                  ),
                                ),
                                Text(
                                  "₹ ${balance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: balance >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0, // Match font size for uniformity
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${account['account_contact']}',
                                style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.arrow_forward_ios, color: Colors.black, size: 18,), // Icon is white
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AccountData(
                                      name: account['account_name'],
                                      id: account['account_id'].toString(),
                                      num: account['account_contact'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = title;
            accounts = _getFilteredAccounts(); // Update accounts based on selected tab
          });
        },
        child: Container(
          height: 50,
          color: isSelected ? Colors.white : Colors.blueAccent,
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
