import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database_helper.dart';

class AllPaymentPage extends StatefulWidget {
  const AllPaymentPage({super.key});

  @override
  State<AllPaymentPage> createState() => _AllPaymentPageState();
}

class _AllPaymentPageState extends State<AllPaymentPage> {
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchAllTransactions();
  }

  Future<void> fetchAllTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.rawQuery('''
      SELECT t.*, a.account_name
      FROM transactions t
      JOIN accounts a ON t.account_id = a.account_id
      ORDER BY t.transaction_date DESC
    ''');
    setState(() => transactions = data);
  }



  Future<void> filterTransactionsByDate() async {
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;
    String filterType = 'ALL'; // NEW: Add this for Credit/Debit filter

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Filter Transactions"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => tempStartDate = pickedDate);
                    }
                  },
                  child: Text(tempStartDate == null
                      ? 'Start Date'
                      : DateFormat('dd MMM yyyy').format(tempStartDate!)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: tempEndDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => tempEndDate = pickedDate);
                    }
                  },
                  child: Text(tempEndDate == null
                      ? 'End Date'
                      : DateFormat('dd MMM yyyy').format(tempEndDate!)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text("All"),
                      selected: filterType == 'ALL',
                      onSelected: (_) => setState(() => filterType = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text("Credit"),
                      selected: filterType == 'CREDIT',
                      onSelected: (_) => setState(() => filterType = 'CREDIT'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text("Debit"),
                      selected: filterType == 'DEBIT',
                      onSelected: (_) => setState(() => filterType = 'DEBIT'),
                    ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'start': tempStartDate,
                  'end': tempEndDate,
                  'type': filterType
                }),
                child: const Text("Apply"),
              ),
            ],
          );
        });
      },
    ).then((pickedRange) async {
      if (pickedRange != null &&
          pickedRange['start'] != null &&
          pickedRange['end'] != null) {
        startDate = pickedRange['start'];
        endDate = pickedRange['end'];
        String type = pickedRange['type'];

        final db = await DatabaseHelper.instance.database;
        final adjustedEndDate = endDate!.add(const Duration(days: 1));

        String whereClause = '''
        t.transaction_date >= ? AND 
        t.transaction_date <= ? AND 
        t.is_delete = 0
        ''';

        List<dynamic> whereArgs = [
          DateFormat('dd MMM yyyy').format(startDate!),
          DateFormat('dd MMM yyyy').format(endDate!), // No need to add +1 day
        ];

        final rawDates = await db.rawQuery('SELECT DISTINCT transaction_date FROM transactions LIMIT 10');
        print("********************************* $rawDates");

        if (type == 'CREDIT') {
          whereClause += ' AND t.is_credited = 1';
        } else if (type == 'DEBIT') {
          whereClause += ' AND t.is_credited = 0';
        }

        final data = await db.rawQuery('''
        SELECT t.*, a.account_name
        FROM transactions t
        JOIN accounts a ON t.account_id = a.account_id
        WHERE $whereClause
        ORDER BY t.transaction_date DESC
      ''', whereArgs);
        print(transactions);
        print('666666666666666666666666666666666666666666666666666666666666666');

        debugPrint("Filtering from ${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}");
        debugPrint("Filtered transactions count: ${data.length}");
        debugPrint("Executing query with where: $whereClause");
        debugPrint("With args: $whereArgs");

        setState(() => transactions = data);
      }
    });
  }

  Future<void> generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'All Transactions Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          if (startDate != null && endDate != null)
            pw.Text(
              'From ${DateFormat('dd MMM yyyy').format(startDate!)} to ${DateFormat('dd MMM yyyy').format(endDate!)}',
              style: pw.TextStyle(fontSize: 12),
            ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
            },
            headers: ['Account', 'Date', 'Amount (Dr/Cr)'],
            data: transactions.map((t) {
              final isCredit = t['is_credited'] == 1;
              final formattedAmount =
                  "${t['transaction_amount']} ${isCredit ? 'Cr' : 'Dr'}";
              return [
                t['account_name'] ?? '',
                formatDate(t['transaction_date']),
                formattedAmount,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  String formatDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Payment"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllTransactions,
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: filterTransactionsByDate,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePDF,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "All Transactions",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 35,
                horizontalMargin: 12,
                dataRowMinHeight: 30,
                dataRowMaxHeight: 40,
                headingRowHeight: 36,
                columns: const [
                  DataColumn(
                    label: Text(
                      "Account",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Date",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Amount (Dr/Cr)",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: transactions.map((t) {
                  final isCredit = t['is_credited'] == 1;
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        t['account_name'] ?? '',
                        style: const TextStyle(fontSize: 11),
                      )),
                      DataCell(Text(
                        formatDate(t['transaction_date']),
                        style: const TextStyle(fontSize: 11),
                      )),
                      DataCell(Text(
                        "${t['transaction_amount']} ${isCredit ? 'Cr' : 'Dr'}",
                        style: TextStyle(
                          fontSize: 11,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
