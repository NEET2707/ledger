import 'package:flutter/material.dart';
import 'package:ledger/ADD/ADD/add_transaction.dart';
import 'package:ledger/colors.dart';
import 'package:ledger/DataBase/database_helper.dart';
import 'package:ledger/settings/currencymanager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ADD/ADD/transaction_search.dart';
import 'ADD/home.dart';
import 'ADD/settings.dart';



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
      'transactions',
      where: '$transaction_accountId = ?',
      whereArgs: [int.parse(widget.id)],
      orderBy: '$transaction_date DESC',
    );

    setState(() {
      transactions = data;

      // Calculate the account balance, total credit, and total debit
      accountBalance = 0.0;
      totalCredit = 0.0;
      totalDebit = 0.0;

      for (var txn in data) {
        double amount = txn[textlink.transactionAmount] as double; // Use field constant for amount
        if (txn[textlink.transactionIsCredited] == 1) { // Use field constant for credit check
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

  Future<void> _launchUrl(String links) async {
    final Uri _url = Uri.parse(links);
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: (){
            Navigator.pop(context,true);
          },
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
                  GestureDetector(
                    onTap: () {
                      _launchUrl('tel:${widget.num}');
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.call, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          widget.num,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Current A/C:",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${CurrencyManager.cr}${accountBalance.toStringAsFixed(2)}",
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
                            "${CurrencyManager.cr}${totalCredit.toStringAsFixed(2)} Credit",
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
                            "${CurrencyManager.cr}${totalDebit.toStringAsFixed(2)} Debit",
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
            Card(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 👈 Ensures Column doesn't take full height
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: const Text(
                      "Transactions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final isCredit = transaction[textlink.transactionIsCredited] == 1;

                      return ListTile(
                        visualDensity: VisualDensity(vertical: -4),
                        leading: CircleAvatar(
                          backgroundColor: isCredit ? Colors.green : Colors.red,
                          child: Icon(
                            isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          "${CurrencyManager.cr}${transaction[textlink.transactionAmount]}",
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Txn: ${transaction[textlink.transactionDate]}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if ((transaction[textlink.transactionReminderDate] as String?)?.isNotEmpty == true)
                              Text(
                                "Due: ${transaction[textlink.transactionReminderDate]}",
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            if ((transaction[textlink.transactionNote] as String?)?.isNotEmpty == true)
                              Text(
                                "Note: ${transaction[textlink.transactionNote]}",
                                style: const TextStyle(color: Colors.black87, fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              var reesult = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddTransaction(
                                    id: widget.id,
                                    name: widget.name,
                                    flag: true,
                                    tid: transaction[textlink.transactionId].toString(),
                                  ),
                                ),
                              );
                              if(reesult == true){
                                _fetchTransactions();
                              }
                            } else if (value == 'delete') {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text('Are you sure you want to delete this transaction?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldDelete == true) {
                                final db = await DatabaseHelper.instance.database;
                                await db.delete(
                                  tableTransactions,
                                  where: '${textlink.transactionId} = ?',
                                  whereArgs: [transaction[textlink.transactionId]],
                                );
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
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Divider(
                          height: 0.2,
                          thickness: 1,
                          indent: 8,
                          endIndent: 8,
                        ),
                      );
                    },
                  ),
                ],
              ),
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
