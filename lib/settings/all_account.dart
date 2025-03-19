import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../ADD/ADD/add_account.dart';
import '../account_data.dart';
import '../database_helper.dart';
import 'currencymanager.dart';

class AllAccountsPage extends StatefulWidget {
  @override
  _AllAccountsPageState createState() => _AllAccountsPageState();
}

class _AllAccountsPageState extends State<AllAccountsPage> {
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _filteredAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await DatabaseHelper.instance.getAllAccountsWithBalance();
    setState(() {
      _accounts = accounts;
      _filteredAccounts = accounts;
    });
  }

  void _filterAccounts(String query) {
    setState(() {
      _filteredAccounts = _accounts
          .where((account) =>
      account['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
          account['phone'].toString().contains(query))
          .toList();
    });
  }

  void _openContactPicker() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        String name = contact.name.first;
        String phone = contact.phones.first.number;

        // Insert into DB
        int newId = await DatabaseHelper.instance.insertAccount({
          accountName: name,
          accountContact: phone,
          accountEmail: '',
          accountDescription: '',
          accountImage: '',
          accountTotal: 0.0,
          accountDateAdded: DateTime.now().toIso8601String(),
          accountDateModified: DateTime.now().toIso8601String(),
          accountIsDelete: 0,
        });

        // Navigate directly to AccountData page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountData(
              name: name,
              num: phone,
              id: newId.toString(),
            ),
          ),
        ).then((_) => _loadAccounts()); // Optional reload
      }
    }
  }


  Widget _buildAccountTile(Map<String, dynamic> account) {
    final balance = account['balance'] ?? 0.0;
    final isCredit = balance >= 0;
    final balanceText = balance == 0
        ? '${CurrencyManager.cr} 0'
        : '${CurrencyManager.cr} ${balance.abs().toStringAsFixed(0)} ${isCredit ? 'Cr' : 'Dr'}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade700,
        child: Text(account['name'][0].toUpperCase(), style: TextStyle(color: Colors.white)),
      ),
      title: Text(account['name'], style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(account['phone']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (balance != 0)
            Icon(
              isCredit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isCredit ? Colors.green : Colors.red,
              size: 18,
            ),
          SizedBox(width: 4),
          Text(balanceText),
          // Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, '/accountDetails', arguments: account);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Accounts"),
        actions: [
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddAccount(
                    name: 'none',
                    contact: 'none',
                    id: '0',
                  ),
                ),
              ).then((_) => _loadAccounts()); // Optional: refresh accounts after return
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add_alt_1),
            onPressed: _openContactPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _filterAccounts,
            ),
          ),
          Expanded(
            child: _filteredAccounts.isEmpty
                ? Center(child: Text("No accounts found"))
                : ListView.builder(
              itemCount: _filteredAccounts.length,
              itemBuilder: (context, index) =>
                  _buildAccountTile(_filteredAccounts[index]),
            ),
          ),
        ],
      ),
    );
  }
}
