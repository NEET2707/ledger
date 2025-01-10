import 'package:flutter/material.dart';
import 'package:ledger/database_helper.dart';

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
      final name = account['name']?.toLowerCase() ?? '';
      final mobile = account['mobile_number']?.toLowerCase() ?? '';
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
        title: const Text('Search Accounts'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredAccounts.length,
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24, // Adjust the size as needed
                      backgroundColor: Colors.blueAccent, // Background color of the circle
                      child: Text(
                        account['name'][0].toUpperCase(), // First letter of the name
                        style: const TextStyle(
                          color: Colors.white, // Text color
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Adjust font size
                        ),
                      ),
                    ),
                    title: Text(account['name'] ?? ''),
                    subtitle: Text(account['mobile_number'] ?? ''),
                    onTap: () {
                      Navigator.pop(context, account);
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
