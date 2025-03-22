import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:ledger/ADD/ADD/transaction_search.dart';
import 'package:ledger/account_data.dart';
import 'package:ledger/colors.dart';
import 'package:ledger/DataBase/database_helper.dart';

import '../settings.dart';

class AddTransaction extends StatefulWidget {
  final String? name;
  final String? id;
  String? tid;
  bool? flag;

  //reminder
  bool? reminderflag;
  double? amountFromReminder;
  bool? iscredit;



  AddTransaction({super.key, this.name, this.id, this.flag, this.tid, this.reminderflag, this.amountFromReminder, this.iscredit});

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final amtcon = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final noteController = TextEditingController();
  int? _isCredit;

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

    if(widget.reminderflag == true){
      amtcon.text = widget.amountFromReminder.toString();

      if(widget.iscredit == true){
        _isCredit = 1;
      }else{
        _isCredit = 0;
      }
    }

  }

  Future<void> _fetchTransactionDetails(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'transactions',
      where: '${textlink.transactionId} = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final transaction = result.first;

      setState(() {
        _isCredit = transaction[textlink.transactionIsCredited] as int?;
        amtcon.text = (transaction[textlink.transactionAmount] as double?)?.toString() ?? '';

        _transactionDate = DateFormat('dd-MM-yyyy').parse(transaction[textlink.transactionDate] as String);

        final reminderRaw = transaction[textlink.transactionReminderDate] as String?;
        if (reminderRaw != null && reminderRaw.isNotEmpty) {
          try {
            final parsedDate = DateFormat('dd-MM-yyyy').parse(reminderRaw);
            if (parsedDate.isAfter(DateTime(1999))) {
              _reminderDate = parsedDate;
              _isReminderChecked = true;
            } else {
              _reminderDate = null;
              _isReminderChecked = false;
            }
          } catch (e) {
            _reminderDate = null;
            _isReminderChecked = false;
            print("Invalid reminder date format: $reminderRaw");
          }
        } else {
          _reminderDate = null;
          _isReminderChecked = false;
        }

        _isReminderChecked = _reminderDate != null;
        name = transaction[accountName]?.toString() ?? '';
        noteController.text = transaction[textlink.transactionNote]?.toString() ?? '';
      });
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate,
      Function(DateTime) onDateSelected) async {
    final safeInitialDate = initialDate.isBefore(DateTime(2000)) ? DateTime.now() : initialDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
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
    return DateFormat('yyyy-MM-dd').format(date); // ✅ ISO format
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
              const Text("Reminder Transaction",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isReminderChecked = !_isReminderChecked;
                        if (_isReminderChecked) {
                          _reminderDate = DateTime.now(); // set current date
                        } else {
                          _reminderDate = null;
                        }
                      });
                    },
                    child: Container(
                      height: 40,
                      width: 150,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isReminderChecked,
                            onChanged: (value) {
                              setState(() {
                                _isReminderChecked = value ?? false;
                                if (_isReminderChecked) {
                                  _reminderDate = DateTime.now(); // set current date
                                } else {
                                  _reminderDate = null;
                                }
                              });
                            },
                          ),
                          const Text("Due Reminder"),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 155,
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
                  )
                ],
              ),
              const SizedBox(height: 16),
              // Transaction Note
              const Text("Transaction Note", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: 'Note',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 32),
              // Debit and Credit Buttons
              Row(

                children: [
                  if (widget.flag == true)
                  // Show SAVE button in edit mode
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final transactionData = {
                              textlink.transactionAmount: double.parse(amtcon.text),
                              textlink.transactionDate: _formatDate(_transactionDate),
                              textlink.transactionReminderDate:
                              _reminderDate != null ? _formatDate(_reminderDate!) : null,
                              textlink.transactionNote: _isCredit == 1 ? 'Credit Note' : 'Debit Note',
                              textlink.transactionIsCredited: _isCredit ?? 0,
                              transaction_accountId: accountId,
                              textlink.transactionNote: noteController.text,
                            };

                            DatabaseHelper.instance.updateTransaction(
                                transactionData, int.parse(widget.tid.toString()));

                            print("Updated transaction: $transactionData");
                            Navigator.pop(context, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: themecolor),
                        child: const Text("SAVE", style: TextStyle(color: Colors.white),),
                      ),
                    )
                  else if (widget.reminderflag == true)
                  // Show SAVE button in edit mode
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final transactionData = {
                              textlink.transactionAmount: double.parse(amtcon.text),
                              textlink.transactionDate: _formatDate(_transactionDate),
                              textlink.transactionReminderDate:
                              _reminderDate != null ? _formatDate(_reminderDate!) : null,
                              textlink.transactionNote: widget.iscredit == true ? 'Debit Note' : 'Credit Note',
                              textlink.transactionIsCredited: _isCredit ?? 0,
                              transaction_accountId: accountId,
                              textlink.transactionNote: noteController.text,
                            };

                            DatabaseHelper.instance.insertTransaction(
                                transactionData);

                            print("Updated transaction: $transactionData");
                            Navigator.pop(context, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: themecolor),
                        child: const Text("SAVE", style: TextStyle(color: Colors.white),),
                      ),
                    )

                  else ...[
                      // Show both DEBIT and CREDIT buttons in add mode
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              final transactionData = {
                                textlink.transactionAmount: double.parse(amtcon.text),
                                textlink.transactionDate: _formatDate(_transactionDate),
                                textlink.transactionReminderDate:
                                _reminderDate != null ? _formatDate(_reminderDate!) : null,
                                // textlink.transactionNote: 'Debit Note',
                                textlink.transactionIsCredited: 0,
                                transaction_accountId: accountId,
                                textlink.transactionNote: noteController.text,
                              };

                              DatabaseHelper.instance.insertTransaction(transactionData);
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("DEBIT", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              final transactionData = {
                                textlink.transactionAmount: double.parse(amtcon.text),
                                textlink.transactionDate: _formatDate(_transactionDate),
                                textlink.transactionReminderDate:
                                _reminderDate != null ? _formatDate(_reminderDate!) : null,
                                // textlink.transactionNote: 'Credit Note',
                                textlink.transactionIsCredited: 1,
                                transaction_accountId: accountId,
                                textlink.transactionNote: noteController.text,
                              };

                              DatabaseHelper.instance.insertTransaction(transactionData);
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("CREDIT", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                    ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}