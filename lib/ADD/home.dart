import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ledger/ADD/ADD/add_account.dart';
import 'package:ledger/ADD/ADD/add_transaction.dart';
import 'package:ledger/ADD/reminder.dart';
import 'package:ledger/ADD/settings.dart';
import '../account_data.dart';
import '../colors.dart';
import '../database_helper.dart'; // Import your database helper

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _AllAccountsState();
}

class _AllAccountsState extends State<Home> {
  String selectedTab = "ALL";
  late Future<List<Map<String, dynamic>>> accounts;

  @override
  void initState() {
    super.initState();
// Fetch all accounts initially
  }

// Filter accounts based on selected tab
  Future<List<Map<String, dynamic>>> _getFilteredAccounts() async {
    final allAccounts = await accounts;
    if (selectedTab == "ALL") {
      return allAccounts; // Show all accounts
    } else if (selectedTab == "DEBIT") {
// Filter for debit accounts (assuming 'type' field distinguishes debit transactions)
      return allAccounts
          .where((account) => account['type'] == 'DEBIT')
          .toList();
    } else if (selectedTab == "CREDIT") {
// Filter for credit accounts (assuming 'type' field distinguishes credit transactions)
      return allAccounts
          .where((account) => account['type'] == 'CREDIT')
          .toList();
    }
    return []; // Return an empty list if no matching tab
  }

  @override
  Widget build(BuildContext context) {
    accounts = DatabaseHelper.instance.fetchAccounts();
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
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddTransaction()));
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
          Container(
            color: Colors.blueAccent,
            padding: EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 8.0), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Current A/C:",
                  style: TextStyle(
                      fontSize: 16, color: Colors.white), // Reduced font size
                ),
                SizedBox(height: 4), // Reduced spacing
                Text(
                  "₹ 0",
                  style: TextStyle(
                    fontSize: 20, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4), // Reduced spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              16), // Reduced border radius
                          child: Container(
                            height: 32, // Reduced height
                            width: 32, // Reduced width
                            color: Colors.white,
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.blueAccent,
                              size: 24, // Reduced icon size
                            ),
                          ),
                        ),
                        SizedBox(width: 6), // Reduced spacing
                        Text(
                          "₹ 0 Credit",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white), // Reduced font size
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              16), // Reduced border radius
                          child: Container(
                            height: 32, // Reduced height
                            width: 32, // Reduced width
                            color: Colors.white,
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.blueAccent,
                              size: 24, // Reduced icon size
                            ),
                          ),
                        ),
                        SizedBox(width: 6), // Reduced spacing
                        Text(
                          "₹ 0 Debit",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white), // Reduced font size
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
// Filter Buttons Section
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
// Tab Content Section
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future:
                  _getFilteredAccounts(), // Fetch filtered accounts based on selected tab
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No accounts found'));
                } else {
                  final accountList = snapshot.data!;
                  return ListView.builder(
                    itemCount: accountList.length,
                    itemBuilder: (context, index) {
                      final account = accountList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(4.0),
                          leading: CircleAvatar(
                            radius: 24, // Adjust the size as needed
                            backgroundColor:
                                Colors.blueAccent, // You can change the color
                            child: Text(
                              account['name'][0]
                                  .toUpperCase(), // First letter of the name
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Adjust font size if needed
                              ),
                            ),
                          ),
                          title: Text(account['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mobile: ${account['mobile_number']}'),
// Uncomment or modify these lines if needed
// Text('Email: ${account['email']}'),
// Text('Description: ${account['description']}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AccountData(
                                          name: account['name'],
                                          id: account['id'].toString(),
                                          num: account['mobile_number'],
                                        )));
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.arrow_forward),
                            onPressed: () {
// Navigate to AccountData screen with selected account details
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AccountData(
                                    name: account['name'],
                                    num: account['mobile_number'],
                                    id: account['id'].toString(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
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

  String _getTabContent() {
    switch (selectedTab) {
      case "ALL":
        return "No Accounts Found (All Transactions)";
      case "DEBIT":
        return "No Accounts Found (Debit Transactions)";
      case "CREDIT":
        return "No Accounts Found (Credit Transactions)";
      default:
        return "No Accounts Found";
    }
  }
}
