import 'package:flutter/material.dart';
import 'package:ledger/account_data.dart';
import 'package:ledger/colors.dart';
import '../../database_helper.dart'; // Adjust the import according to your project structure


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



class AddAccount extends StatefulWidget {
  final String name;
  final String contact;
  final String id;
  final String? email;  // Make email optional
  final String? description;  // Make description optional

  // Add a constructor to accept these values as parameters
  const AddAccount({
    super.key,
    required this.name,
    required this.contact,
    required this.id,
    this.email,
    this.description,
  });

  @override
  State<AddAccount> createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> {
  final _formKey = GlobalKey<FormState>(); // Key to validate the form
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountContactController = TextEditingController();
  final TextEditingController _accountEmailController = TextEditingController();
  final TextEditingController _accountDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    print(widget.name);

    if(widget.name=="none" && widget.contact=="none" && widget.id=='0'){
      _accountContactController.text = "";
      _accountNameController.text = "";
    }else{
      _accountNameController.text = widget.name;
      _accountContactController.text = widget.contact;
    }
    if (widget.email != null) _accountEmailController.text = widget.email!;
    if (widget.description != null) _accountDescriptionController.text = widget.description!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        title: Text(
          "Create Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Form( // Wrap the fields in a Form widget
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Name *', // Add asterisk to indicate required field
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account name'; // Validation message for empty Name field
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _accountContactController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *', // Add asterisk to indicate required field
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account contact number'; // Validation message for empty Mobile field
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _accountEmailController,
                decoration: InputDecoration(
                  labelText: 'Email', // No asterisk as it is optional
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _accountDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Description', // No asterisk as it is optional
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      // If the form is valid, insert the data into the database
                      Map<String, dynamic> accountData = {
                        accountName: _accountNameController.text,
                        accountContact: _accountContactController.text,
                        accountEmail: _accountEmailController.text,
                        accountDescription: _accountDescriptionController.text,
                      };
                      int id = await DatabaseHelper.instance.insertAccount(accountData);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountData(
                            name: _accountNameController.text,
                            num: _accountContactController.text,
                            id: id.toString(),
                          ),
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account added with ID: $id')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themecolor, // Set the background color to the theme color
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
