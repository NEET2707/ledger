import 'package:flutter/material.dart';
import 'package:ledger/account_data.dart';
import 'package:ledger/colors.dart';
import '../../DataBase/database_helper.dart'; // Adjust the import according to your project structure


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
                textCapitalization: TextCapitalization.words,
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
                  textCapitalization: TextCapitalization.words
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      Map<String, dynamic> accountData = {
                        accountName: _accountNameController.text,
                        accountContact: _accountContactController.text,
                        accountEmail: _accountEmailController.text.isEmpty ? null : _accountEmailController.text,
                        accountDescription: _accountDescriptionController.text.isEmpty ? null : _accountDescriptionController.text,
                      };

                      int id;
                      if (widget.id == '0') {
                        id = await DatabaseHelper.instance.insertAccount(accountData);

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountData(
                              name: _accountNameController.text,
                              num: _accountContactController.text,
                              id: id.toString(),
                            ),
                          ),
                        );

                        if (result == true) {
                          Navigator.pop(context, true);
                        }

                      } else {
                        accountData[accountId] = int.parse(widget.id);
                        await DatabaseHelper.instance.updateAccount(accountData);
                        Navigator.pop(context, true);
                      }

                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: themecolor, // Set the background color to the theme color
                  ),
                  child: Text(
                    widget.id == '0' ? 'Add' : 'Update',
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
