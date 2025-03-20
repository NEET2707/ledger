import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ledger/ADD/ADD/add_account.dart';
import 'package:ledger/ADD/ADD/add_transaction.dart';
import 'package:ledger/ADD/reminder.dart';
import 'package:ledger/ADD/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../account_data.dart';
import '../colors.dart';
import '../DataBase/database_helper.dart';
import '../settings/currencymanager.dart'; // Import your database helper



class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _AllAccountsState();
}

class _AllAccountsState extends State<Home> {
  String selectedTab = "ALL";
  String tbalance = "balance";
  late Future<List<Map<String, dynamic>>> accounts;
  String a = "";
  String b = "";

  late Future<Map<String, double>> _futureTotals;

  @override
  void initState() {
    super.initState();
    _futureTotals = _calculateTotals(); // Only called once when page is opened
    accounts = _getFilteredAccounts();
  }

  Future<List<Map<String, dynamic>>> _getFilteredAccounts() async {
    final allAccounts =
        await DatabaseHelper.instance.fetchAccountsWithBalance();


    if (selectedTab == "ALL") {
      return allAccounts; // Show all accounts
    } else if (selectedTab == "DEBIT") {
      return allAccounts.where((account) => account[tbalance] < 0).toList();
    } else if (selectedTab == "CREDIT") {
      return allAccounts.where((account) => account[tbalance] > 0).toList();
    }
    return []; // Return an empty list if no matching tab
  }

  Future<Map<String, double>> _calculateTotals() async {
    final accountList =
        await DatabaseHelper.instance.fetchAccountsWithBalance();

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

  Future<void> _showContacts() async {
    // Ask the OS for permission first
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
    }

    print("Contact permission granted: ${status.isGranted}");

    if (status.isGranted) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        String a = contact.displayName;
        String b = contact.phones.first.number;

        await addData(a, b, "", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: $a, $b')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No phone number found for the selected contact.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission denied to access contacts.")),
      );
    }
  }

  Future<void> addData(
      String name, String contact, String email, String description) async {
    if (name.isEmpty || contact.isEmpty) return;

    int newId = await DatabaseHelper.instance.insertAccount({
      accountName: name,
      accountContact: contact,
      accountEmail: email,
      accountDescription: description,
      // accountImage: "",
      // accountTotal: 0.0,
      // accountDateAdded: DateTime.now().toIso8601String(),
      // accountDateModified: DateTime.now().toIso8601String(),
      // accountIsDelete: 0,
    });

    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountData(
          name: name,
          id: newId.toString(),
          num: contact,
        ),
      ),
    );

    print("sddsddddddddddddddddddd $shouldRefresh");
    if (shouldRefresh == true) {
      print("Refreshing totals...");
      setState(() {
        accounts = _getFilteredAccounts();
        _futureTotals = _calculateTotals(); // Refresh only if changes were made
      });
    }

  }

  Future<int> getNextId() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
        'SELECT MAX($accountId) as maxId FROM accounts'
    );

    if (result.isNotEmpty && result.first['maxId'] != null) {
      return (result.first['maxId'] as int) + 1;
    } else {
      return 1; // Start from 1 if no accounts exist
    }
  }

  void _onTabSelected(String tab) {
    if (selectedTab != tab) {
      setState(() {
        selectedTab = tab;
        accounts = _getFilteredAccounts(); // Just update filtered accounts
      });
    }
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
                  context, MaterialPageRoute(builder: (context) => ReminderPage()));
            },
            icon: Icon(Icons.notification_add, color: Colors.white),
          ),
          GestureDetector(
            onTap: _showContacts,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(Icons.contact_page, color: Colors.white),
            ),
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
                MaterialPageRoute(
                    builder: (context) =>
                        AddTransaction()), // Ensure TransactionPage is defined
              );

              if (shouldRefresh == true) {
                setState(() {
                  accounts =
                      _getFilteredAccounts();
                  print("8888888888888888888888888888888");
                  print(accounts);
                });
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.person_add, color: Colors.black),
            backgroundColor: Colors.white,
            label: 'Add Account',
            labelStyle: TextStyle(fontSize: 16),
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAccount(
                    name: 'none',
                    contact: 'none',
                    id: '0',
                  ),
                ),
              );

              if (shouldRefresh == true) {
                setState(() {
                  accounts = _getFilteredAccounts();
                  _futureTotals = _calculateTotals();
                });
              }
            },

          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current A/C Section
          FutureBuilder<Map<String, double>>(
            future: _futureTotals,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: Colors.blueAccent,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Container(
                  color: Colors.blueAccent,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                final currency = Provider.of<CurrencyManager>(context).currentCurrency;

                return Container(
                  color: Colors.blueAccent,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Current A/C:",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "$currency ${totalBalance.toStringAsFixed(2)} ${totalBalance >= 0 ? 'CR' : 'DR'}",
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
                                "$currency${totalCredits.toStringAsFixed(2)} Credit",
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
                                "$currency${totalDebits.toStringAsFixed(2)} Debit",
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
                _buildTabButton("ALL", selectedTab == "ALL", () => _onTabSelected("ALL")),
                _buildTabButton("DEBIT", selectedTab == "DEBIT", () => _onTabSelected("DEBIT")),
                _buildTabButton("CREDIT", selectedTab == "CREDIT", () => _onTabSelected("CREDIT")),
              ],
            ),
          ),

          Expanded(
            child: Card(
              color: Colors.white,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future:
                accounts, // Fetch filtered accounts based on selected tab
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No accounts found'));
                  } else {
                    final accountList = snapshot.data!;
                    return ListView.separated(
                      separatorBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Divider( height: 1,
                            thickness: 1,
                            indent: 8,
                            endIndent: 8,),
                        );
                      },
                      itemCount: accountList.length,
                      itemBuilder: (context, index) {
                        final account = accountList[index];
                        final balance = account['balance'] ?? 0.0;
                        final currency = Provider.of<CurrencyManager>(context).currentCurrency;

                        print("Account ID: $account");

                        return ListTile(
                            visualDensity: VisualDensity(vertical: -4),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          leading: CircleAvatar(
                            radius: 24.0, // Larger circle avatar for emphasis
                            backgroundColor: themecolor,
                            child: Text(
                              account[accountName][0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    account[accountName],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                    overflow: TextOverflow.ellipsis, // Prevent overflow
                                  ),
                                ),
                                SizedBox(width: 8), // Add spacing between text and amount
                                Text(
                                  "$currency ${balance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: balance >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ],
                            ),

                            subtitle: Text(
                              '${account[accountContact]}',
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.grey[600]),
                            ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final shouldRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddAccount(
                                      name: account[accountName],
                                      contact: account[accountContact],
                                      id: account[accountId].toString(),
                                      email: account[accountEmail],
                                      description: account[accountDescription],
                                    ),
                                  ),
                                );

                                if (shouldRefresh == true) {
                                  setState(() {
                                    accounts = _getFilteredAccounts(); // Refresh accounts after editing
                                  });
                                }
                              } else if (value == 'delete') {
                                // Show confirmation dialog before deleting
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text('Are you sure you want to delete this account?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false), // Cancel
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true), // Confirm
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldDelete == true) {
                                  // Proceed with the deletion
                                  final db = await DatabaseHelper.instance.database;

                                  // Delete the account from the database
                                  await db.delete(
                                    'accounts', // Table name
                                    where: '$accountId = ?', // Account ID field name
                                    whereArgs: [account[accountId]], // Pass the account ID
                                  );

                                  // Refresh the account list after deletion
                                  setState(() {
                                    accounts = _getFilteredAccounts();
                                    _futureTotals = _calculateTotals();
                                  });
                                }
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: const [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Edit', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: const [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),


                            onTap: () async {
                              final shouldRefresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AccountData(
                                    name: account[accountName],
                                    id: account[accountId].toString(),
                                    num: account[accountContact],
                                  ),
                                ),
                              );

                              print("ooooooooooooooooooooooo $shouldRefresh");
                              if (shouldRefresh == true) {
                                print("Refreshing totals...");
                                setState(() {
                                  accounts = _getFilteredAccounts();
                                  _futureTotals = _calculateTotals(); // this should trigger refresh
                                });
                              }
                            }
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
