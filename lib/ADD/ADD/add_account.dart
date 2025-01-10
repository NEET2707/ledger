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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *', // Add asterisk to indicate required field
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name'; // Validation message for empty Name field
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *', // Add asterisk to indicate required field
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number'; // Validation message for empty Mobile field
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      // If the form is valid, insert the data into the database
                      Map<String, dynamic> accountData = {
                        'name': _nameController.text,
                        'mobile_number': _mobileController.text,
                        'email': _emailController.text,
                        'description': _descriptionController.text,
                      };
                      int id = await DatabaseHelper.instance.insertAccount(accountData);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AccountData(name: _nameController.text, num: _mobileController.text,id: id.toString(),)));

                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Account added with ID: $id'))
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
