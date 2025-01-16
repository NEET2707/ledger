import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:ledger/ADD/ADD/transaction_search.dart';
import 'package:ledger/account_data.dart';
import 'package:ledger/colors.dart';
import 'package:ledger/database_helper.dart';



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

class AddTransaction extends StatefulWidget {
  final String? name;
  final String? id;
  String? tid;
  bool? flag;

  AddTransaction({super.key, this.name, this.id, this.flag, this.tid});

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final amtcon = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _transactionDate = DateTime.now();
  DateTime? _reminderDate;
  bool _isReminderChecked = false;
  int tid = 0; // Ensure id is defined as int
  String name = ""; // Ensure name is defined as String
  int accountId = 0;

  @override
  void initState() {
    super.initState();
    name = widget.name ?? ""; // Initialize name safely
    if (widget.id != null) {
      accountId = int.parse(widget.id.toString());
    }
    if(widget.flag == true){
      tid = int.tryParse(widget.tid ?? '') ?? 0;  // Safely parse the id as int
      _fetchTransactionDetails(tid);
    }
  }

  Future<void> _fetchTransactionDetails(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'transactions',
      where: '$transactionId = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final transaction = result.first;
      setState(() {
        amtcon.text = (transaction[transactionAmount] as double?)?.toString() ?? '';  // Cast to double
        _transactionDate = DateTime.parse(transaction[transactionDate] as String);  // Cast to String, then parse
        _reminderDate = transaction[transactionReminderDate] != null
            ? DateTime.parse(transaction[transactionReminderDate] as String)  // Cast to String, then parse
            : null;
        _isReminderChecked = _reminderDate != null;
        // Ensure the account name is set correctly
        name = transaction[accountName]?.toString() ?? '';  // Use null-aware operators to handle null values
      });
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate,
      Function(DateTime) onDateSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themecolor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: themecolor,
        title: const Text(
          "New Transaction",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Account Name Dropdown
              const Text("Account Name", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (name.isNotEmpty)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () async {
                    var result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionSearch(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        accountId = int.tryParse(result["accid"]?.toString() ?? '0') ?? 0;  // Safely parse the id
                        name = result["accname"]?.toString() ?? '';  // Safely handle null name
                      });

                      print("==========> $result");
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name.isNotEmpty ? name : 'Select Account',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Transaction Amount
              const Text("Transaction", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: amtcon,
                      decoration: const InputDecoration(
                        hintText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _selectDate(context, _transactionDate, (pickedDate) {
                          setState(() {
                            _transactionDate = pickedDate;
                          });
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_formatDate(_transactionDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reminder Transaction
              const Text("Reminder Transaction", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isReminderChecked,
                    onChanged: (value) {
                      setState(() {
                        _isReminderChecked = value ?? false;
                      });
                    },
                  ),
                  const Text("Due Reminder"),
                  const Spacer(),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isReminderChecked
                          ? () {
                        _selectDate(
                          context,
                          _reminderDate ?? DateTime.now(),
                              (pickedDate) {
                            setState(() {
                              _reminderDate = pickedDate;
                            });
                          },
                        );
                      }
                          : null,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _reminderDate != null
                              ? _formatDate(_reminderDate!)
                              : "Select Date",
                          style: TextStyle(
                            color: _isReminderChecked ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Transaction Note
              const Text("Transaction Note", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              // Debit and Credit Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final transactionData = {
                            transactionAmount: double.parse(amtcon.text),
                            transactionDate: _formatDate(_transactionDate),
                            transactionReminderDate: _reminderDate != null ? _formatDate(_reminderDate!) : null,
                            transactionNote: 'Debit Note',
                            transactionIsCredited: false,
                            transaction_accountId: accountId,
                          };

                          // Print the data before inserting
                          print("Inserting transaction data (DEBIT): $transactionData");

                          if(widget.flag == true){
                            DatabaseHelper.instance.updateTransaction(transactionData, int.parse(widget.tid.toString()));
                            print("doneeeeeeeee");
                          }
                          else{
                            DatabaseHelper.instance.insertTransaction(transactionData);
                            print("doneeeeeeeee");
                          }
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("DEBIT"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final transactionData = {
                            transactionAmount: double.parse(amtcon.text),
                            transactionDate: _formatDate(_transactionDate),
                            transactionReminderDate: _reminderDate != null ? _formatDate(_reminderDate!) : null,
                            transactionNote: 'Credit Note',
                            transactionIsCredited: true,
                            transaction_accountId: accountId,
                          };

                          // Print the data before inserting
                          print("Inserting transaction data (CREDIT): $transactionData");

                          if(widget.flag == true){
                            setState(() {
                              DatabaseHelper.instance.updateTransaction(transactionData, int.parse(widget.tid.toString()));
                            });

                            print("doneeeeeeeee");
                          }else {
                            setState(() {
                              DatabaseHelper.instance.insertTransaction(transactionData);
                            });
                          }
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("CREDIT"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
