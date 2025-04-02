import 'package:flutter/material.dart';
import 'package:ledger/DataBase/database_helper.dart';

// Table names
const String tableAccounts = "accounts";
const String tableTransactions = "transactions";



class TransactionSearch extends StatefulWidget {
  const TransactionSearch({super.key});

  @override
  State<TransactionSearch> createState() => _TransactionSearchState();
}

class _TransactionSearchState extends State<TransactionSearch> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> filteredAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    final data = await DatabaseHelper.instance.fetchAccounts();
    setState(() {
      accounts = data;
      filteredAccounts = data;
    });
  }

  void _filterAccounts(String query) {
    final results = accounts.where((account) {
      final name = account[accountName]?.toLowerCase() ?? '';
      final mobile = account[accountContact]?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) || mobile.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredAccounts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Accounts', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      _filterAccounts('');
                    },
                  ),
                ),
                onChanged: _filterAccounts,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.separated(
                itemCount: filteredAccounts.length,
                separatorBuilder: (context, index) => SizedBox(height: 0), // Space between items
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), // Adjust padding
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        account[accountName][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(account[accountName] ?? ''),
                    subtitle: Text(account[accountContact] ?? ''),
                    onTap: () {
                      print("====> $account");
                      Navigator.pop(context, {
                        "accid": account[accountId],
                        "accname": account[accountName]
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
