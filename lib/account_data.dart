import 'package:flutter/material.dart';
import 'package:ledger/ADD/ADD/add_transaction.dart';
import 'package:ledger/color/colors.dart';
import 'package:ledger/settings/currencymanager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ADD/ADD/add_account.dart';
import 'ADD/ADD/transaction_search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'ADD/settings.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'dataBase/database_helper.dart';

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
    // Ensure widget.id is valid and can be parsed as an integer
    int accountId;
    try {
      accountId = int.parse(widget.id);
    } catch (e) {
      // Handle the error case (widget.id cannot be parsed as an integer)
      print("Invalid account ID: ${widget.id}");
      return;  // Exit the method if the ID is invalid
    }

    final db = await DatabaseHelper.instance.database;
    final data = await db.query(
      'transactions',
      where: '$transaction_accountId = ?',
      whereArgs: [accountId],
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
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (BuildContext context) {
                  return Wrap(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Ledger Book",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text("Share Transaction"),
                        onTap: () {
                          Navigator.pop(context); // Close the bottom sheet

                          String message =
                              "Account Name: ${widget.name}\n"
                              "Account Balance: ${accountBalance.toStringAsFixed(2)}\n"
                              "Total Credit: ${totalCredit.toStringAsFixed(2)}\n"
                              "Total Debit: ${totalDebit.toStringAsFixed(2)}\n";

                          Share.share(message);
                        }
                      ),
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text("Download Transaction Pdf"),
                        onTap: () async {
                          final pdf = pw.Document();

                          final db = await DatabaseHelper.instance.database;
                          List<Map<String, dynamic>> transactions = await db.query(
                            'transactions',
                            where: '$transaction_accountId = ?',
                            whereArgs: [widget.id],
                            orderBy: '$transaction_date DESC',
                          );

                          List<pw.Widget> transactionWidgets = [];

                          for (var doc in transactions) {
                            String date = doc['transaction_date'] ?? "Unknown Date";
                            double amount = double.parse(doc['transaction_amount'].toString());
                            bool isCredit = doc['is_credited'] == 1; // SQLite stores booleans as 0 or 1
                            String transactionType = isCredit ? "Credit" : "Debit";

                            transactionWidgets.add(
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(date, style: pw.TextStyle(fontSize: 12)),
                                    pw.Text("$amount", style: pw.TextStyle(fontSize: 12)),
                                    pw.Text(transactionType, style: pw.TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          }

                          pdf.addPage(
                            pw.Page(
                              pageFormat: PdfPageFormat.a4,
                              build: (pw.Context context) {
                                return pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                        "Account Name: ${widget.name}",
                                        style: pw.TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            pw.FontWeight.bold)),
                                    pw.Text(
                                        "Account Balance: ${accountBalance.toStringAsFixed(2)}",
                                        style:
                                        pw.TextStyle(fontSize: 14)),
                                    pw.SizedBox(height: 10),
                                    pw.Divider(),
                                    pw.Text("Transactions:",
                                        style: pw.TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                            pw.FontWeight.bold)),
                                    pw.SizedBox(height: 10),
                                    ...transactionWidgets, // Display transactions
                                  ],
                                );
                              },
                            ),
                          );

                          // Display PDF preview
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async =>
                                pdf.save(),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.clear_outlined),
                        title: const Text("Clear Account"),
                        onTap: () async {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm Delete"),
                                content: const Text(
                                    "Are you sure you want to delete all account data? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context); // Close the dialog

                                      try {
                                        DatabaseHelper dbHelper = DatabaseHelper.instance;

                                        int deletedRows = await dbHelper.deleteTransactions(int.parse(widget.id));

                                        print("Deleted $deletedRows transactions for account ${widget.id}");

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("$deletedRows transactions deleted")),
                                          );
                                        }
                                      } catch (e) {
                                        print("Error deleting transactions: $e");

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Error deleting transactions")),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text("Edit Account Detail"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAccount(
                                name: widget.name,
                                contact: widget.num,
                                id: widget.id.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text("Delete Account"),
                        onTap: () async {
                          final db = await DatabaseHelper.instance.database;

                          // Check if transactions exist for the given account_id
                          List<Map<String, dynamic>> transactions = await db.query(
                            'transactions',
                            where: 'account_id = ?',
                            whereArgs: [widget.id],
                          );

                          if (transactions.isNotEmpty) {
                            for (var transaction in transactions) {
                              print("Found transaction: ${transaction['transaction_id']}");
                              await db.delete(
                                'transactions',
                                where: 'transaction_id = ?',
                                whereArgs: [transaction['transaction_id']],
                              );
                              print("Deleted transaction: ${transaction['transaction_id']}");
                            }
                          }

                          // Now delete the account from the accounts table
                          await db.delete(
                            'accounts',
                            where: 'account_id = ?',
                            whereArgs: [widget.id],
                          );

                          print("Deleted Account ID: ${widget.id}");

                          setState(() {}); // Update UI
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
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
                    "${CurrencyManager.cr}${accountBalance.abs().toStringAsFixed(2)}",
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
                  // If no transactions, show "Add Transaction" centered button
                  if (transactions.isEmpty)
                    Center(
                      child:
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.wallet,
                              size: 60,
                              color: Colors.grey.shade200,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
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
                              child: const Text("Add Transaction"),
                            ),
                          ],
                        ),
                      )
                    )
                  else
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
                                if (reesult == true) {
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
      floatingActionButton: transactions.isNotEmpty
          ? FloatingActionButton(
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
      )
          : null, // Hide floating action button if no transactions
    );
  }
}



