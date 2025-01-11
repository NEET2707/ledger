import 'package:flutter/material.dart';
import 'package:ledger/account_data.dart';
import 'package:ledger/colors.dart';

import '../../database_helper.dart'; // Adjust the import according to your project structure

class AddAccount extends StatefulWidget {
  const AddAccount({super.key});

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
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _accountDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
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
