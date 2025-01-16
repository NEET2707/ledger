import 'package:flutter/material.dart';
import 'package:ledger/ADD/ADD/add_transaction.dart';
import 'package:ledger/colors.dart';
import 'package:ledger/database_helper.dart';

import 'ADD/ADD/transaction_search.dart';
import 'ADD/home.dart';

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

class AccountData extends StatefulWidget {
  final String name;
  final String num;
  final String id;

  AccountData({super.key, required this.name, required this.num, required this.id});

  @override
  State<AccountData> createState() => _AccountDataState();
}

class _AccountDataState extends State<AccountData> {
  double accountBalance = 0.0;
  double totalCredit = 0.0;
  double totalDebit = 0.0;
  List<Map<String, dynamic>> transactions = [];

  Color backgroundColor = themecolor;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query(
      tableTransactions, // Use table name constant
      where: '$transactionAccountId = ?', // Use field constant
      whereArgs: [int.parse(widget.id)],
      orderBy: '$transactionDate DESC', // Use field constant for date
    );

    setState(() {
      transactions = data;

      // Calculate the account balance, total credit, and total debit
      accountBalance = 0.0;
      totalCredit = 0.0;
      totalDebit = 0.0;

      for (var txn in data) {
        double amount = txn[transactionAmount] as double; // Use field constant for amount
        if (txn[transactionIsCredited] == 1) { // Use field constant for credit check
          accountBalance += amount;
          totalCredit += amount;
        } else {
          accountBalance -= amount;
          totalDebit += amount;
        }
      }

      // Update the background color based on account balance
      backgroundColor = transactions.isEmpty
          ? themecolor // If no transactions, use `themecolor`
          : (accountBalance >= 0 ? Colors.green : Colors.red);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: backgroundColor, // Dynamic AppBar color
        title: Text(
          widget.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: backgroundColor, // Dynamic background color for balance section
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.call, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(widget.num, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Current A/C:",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹ ${accountBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Credit and Debit Totals
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
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "₹ ${totalCredit.toStringAsFixed(2)} Credit",
                            style: const TextStyle(fontSize: 14, color: Colors.white),
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
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "₹ ${totalDebit.toStringAsFixed(2)} Debit",
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Transactions List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: const Text(
                "Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isCredit = transaction[transactionIsCredited] == 1; // Use field constant for credit check
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? Colors.green : Colors.red,
                      child: Icon(
                        isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      "₹ ${transaction[transactionAmount]}",
                      style: TextStyle(
                        color: isCredit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      transaction[transactionDate], // Use field constant for date
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          print('Edit action');
                          // Get the current transaction details
                          final transaction = transactions[index]; // Assuming you have an 'index' variable
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTransaction(
                                id: widget.id, // Pass the ID for editing
                                name: widget.name,
                                flag: true,
                                tid: transaction[transactionId].toString(), // Use field constant for transaction ID
                              ),
                            ),
                          );
                        } else if (value == 'delete') {
                          // Confirmation dialog before deletion
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text('Are you sure you want to delete this transaction?'),
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
                            // Proceed with deletion
                            final db = await DatabaseHelper.instance.database;
                            await db.delete(
                              tableTransactions, // Use table name constant
                              where: '$transactionId = ?', // Use field constant
                              whereArgs: [transactions[index][transactionId]], // Pass the transaction ID
                            );

                            // Refresh the transactions list
                            _fetchTransactions();
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransaction(
                name: widget.name,
                id: widget.id.toString(),
              ),
            ),
          );
          // Refresh the transaction data after adding a transaction
          _fetchTransactions();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

