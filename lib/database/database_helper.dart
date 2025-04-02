import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

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
const String transaction_accountId = "account_id";
const String transaction_id = "transaction_id";
const String transaction_amount = "transaction_amount";
const String transaction_date = "transaction_date";
const String transaction_is_due_reminder = "is_due_reminder";
const String transaction_reminder_date = "reminder_date";
const String transaction_is_credited = "is_credited";
const String transaction_note = "transaction_note";
const String transaction_date_added = "date_added";
const String transaction_date_modified = "date_modified";
const String transaction_is_delete = "is_delete";


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    // Create Accounts table
    await db.execute('''
    CREATE TABLE accounts (
      $accountId INTEGER PRIMARY KEY AUTOINCREMENT,
      $accountName TEXT,
      $accountContact TEXT,
      $accountEmail TEXT,
      $accountDescription TEXT,
      $accountImage TEXT,
      $accountTotal REAL,
      $accountDateAdded TEXT,
      $accountDateModified TEXT,
      $accountIsDelete INTEGER DEFAULT 0
    )
  ''');

    // Create Transactions table
    await db.execute('''
    CREATE TABLE transactions (
      $transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
      $transaction_amount REAL,
      $transaction_date TEXT,
      $transaction_is_due_reminder INTEGER DEFAULT 0,
      $transaction_reminder_date TEXT,
      $transaction_is_credited INTEGER DEFAULT 0,
      $transaction_note TEXT,
      $transaction_date_added TEXT,
      $transaction_date_modified TEXT,
      $transaction_is_delete INTEGER DEFAULT 0,
      $transaction_accountId INTEGER,
      FOREIGN KEY ($transaction_accountId) REFERENCES accounts($accountId) ON DELETE CASCADE
    )
  ''');
  }

  Future<int> insertAccount(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('accounts', data);
  }

  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    final db = await database;
    return await db.query('accounts');
  }

  Future<int> updateAccount(Map<String, dynamic> row) async {
    final db = await database;
    int id = row[accountId];
    return await db.update('accounts', row, where: '$accountId = ?', whereArgs: [id]);
  }

  Future<int> deleteTransactions(int accountId) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      'transactions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(int accountId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: '$transaction_accountId = ?',
      whereArgs: [accountId],
      orderBy: '$transaction_date DESC',
    );
  }

  Future<int> updateTransaction(Map<String, dynamic> transaction, int id) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction,
      where: '$transaction_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> fetchAccountsWithBalance() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT
      a.$accountId,
      a.$accountName,
      a.$accountContact,
      a.$accountEmail,
      a.$accountDescription,
      (
        (SELECT COALESCE(SUM($transaction_amount), 0)
         FROM transactions t
         WHERE t.$transaction_accountId = a.$accountId AND t.$transaction_is_credited = 1) -
        (SELECT COALESCE(SUM($transaction_amount), 0)
         FROM transactions t
         WHERE t.$transaction_accountId = a.$accountId AND t.$transaction_is_credited = 0)
      ) AS balance
    FROM accounts a
  ''');
  }

  Future<void> debugDatabase() async {
    final db = await database;
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    for (final table in tables) {
      final tableName = table['name'];
      final data = await db.query(tableName as String);
      print('Table $tableName: $data');
    }
  }

  Future<List<Map<String, dynamic>>> getAllAccountsWithBalance() async {
    final db = await database;

    final accounts = await db.query('accounts');

    List<Map<String, dynamic>> result = [];

    for (var account in accounts) {
      final accId = account[accountId];

      // Get credit total
      final creditResult = await db.rawQuery('''
      SELECT SUM($transaction_amount) as total_credit 
      FROM transactions 
      WHERE $transaction_accountId = ? AND $transaction_is_credited = 1 AND $transaction_is_delete = 0
    ''', [accId]);

      // Get debit total
      final debitResult = await db.rawQuery('''
      SELECT SUM($transaction_amount) as total_debit 
      FROM transactions 
      WHERE $transaction_accountId = ? AND $transaction_is_credited = 0 AND $transaction_is_delete = 0
    ''', [accId]);

      // Safe conversion function
      double toDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        return 0.0;
      }

      double credit = toDouble(creditResult.first['total_credit']);
      double debit = toDouble(debitResult.first['total_debit']);

      double balance = credit - debit;

      result.add({
        'account_id': account[accountId],
        'name': account[accountName],
        'phone': account[accountContact],
        'balance': balance,
      });
    }

    return result;
  }

  static Future<Database> getDatabase() async {
    return await instance.database;
  }


  Future<List<Map<String, dynamic>>> getReminderTransactions() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      t.*,
      a.account_name,
      a.account_contact
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE t.reminder_date IS NOT NULL AND t.is_delete = 0
    ORDER BY t.reminder_date ASC
  ''');
  }


  /// **Request Storage Permission (for Android 13 and below)**
  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    print("❌ Storage permission denied!");
    return false;
  }

  static Future<bool> backupDatabase() async {
    if (!await requestStoragePermission()) {
      print("Storage permission denied!");
      return false;
    }
    final _saf = SafUtil();
    try {
      String? pickedDirectory = await _saf.openDirectory();
      if (pickedDirectory == null) {
        print("❌ No directory selected!");
        return false;
      }

      String filePath = "$pickedDirectory/backup.csv";

      bool success = await exportToCSV(filePath);
      return success;
    } catch (e) {
      print("❌ Error during backup: $e");
      return false;
    }
  }

  static Future<bool> restoreDatabase() async {
    if (!await requestStoragePermission()) {
      print("Storage permission denied!");
      return false;
    }

    try {

      bool success = await importFromCSV();
      return success;
    } catch (e) {
      print("❌ Error during restore: $e");
      return false;
    }
  }

  Future<String?> picksafdirectory() async {
    final _safUtil = SafUtil();
    String? selectedDirectory = await _safUtil.openDirectory();
    if (selectedDirectory == null) {
      Fluttertoast.showToast(msg: "No folder selected.");
      return null;
    }
    return selectedDirectory;
  }

  static Future<bool> exportToCSV(String filePath) async {
    final _safStreamPlugin = SafStream();
    final _safUtil = SafUtil();
    // String? selectedDirectory = await _safUtil.openDirectory();
    try {
      Database db = await getDatabase();
      List<String> tables = ['accounts','transactions'];

      List<List<String>> csvData = [];
      for (String table in tables) {
        List<Map<String, dynamic>> rows = await db.query(table);
        print("roesssss : $rows");
        if (rows.isNotEmpty) {
          csvData.add([table]); // Table name
          csvData.add(rows.first.keys.toList()); // Column headers
          for (var row in rows) {
            csvData.add(row.values.map((value) => value.toString()).toList());
          }
        }
      }
      String csv = const ListToCsvConverter().convert(csvData);
      Uint8List unitdata = Uint8List.fromList(csv.codeUnits);
      await _safStreamPlugin.writeFileBytes(filePath, "fxdfhjh.csv", "text/csv", unitdata);


      print("✅ Exported Success");
      return true;
    } catch (e) {
      print("❌ Error during export: $e");
      return false;
    }
  }

  static Future<bool> importFromCSV() async {
    final _safUtil = SafUtil();
    String? selectedFilePath = await _safUtil.openFile();  // Use openFile() for file selection

    if (selectedFilePath == null) {
      print("❌ No file selected.");
      return false;
    }

    try {
      final _safStreamPlugin = SafStream();
      Uint8List fileBytes = await _safStreamPlugin.readFileBytes(selectedFilePath);

      // Convert bytes to string
      String fileContent = utf8.decode(fileBytes);
      List<List<dynamic>> csvData = const CsvToListConverter().convert(fileContent);

      print("CSV Data: $csvData");

      Database db = await getDatabase();
      String? currentTable;
      List<String> tables = ['accounts','transactions'];

      for (int rowIndex = 0; rowIndex < csvData.length; rowIndex++) {
        List<dynamic> row = csvData[rowIndex];

        if (row.isEmpty) continue; // Skip empty rows

        if (row.length == 1 && tables.contains(row[0].toString().trim().toLowerCase())) {
          // Identify new table
          currentTable = row[0].toString().trim();
          print("Switching to table: $currentTable");
        } else if (currentTable != null && rowIndex > 0) {
          // Check if this row is the column headers
          List<String> columns = csvData[rowIndex - 1].map((e) => e.toString()).toList();
          if (columns.length <= 1) continue; // Skip invalid headers

          Map<String, dynamic> rowData = {};
          for (int i = 0; i < columns.length; i++) {
            if (i < row.length) {
              rowData[columns[i]] = row[i];
            }
          }

          await db.insert(currentTable, rowData, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      print("✅ Data imported successfully!");
      return true;
    } catch (e) {
      print("❌ Error during import: $e");
      return false;
    }
  }

  static Future<Map<String, double>> getMonthlyGstReport(DateTime selectedDate) async {
    final db = await getDatabase();

    String month = selectedDate.month.toString().padLeft(2, '0');
    String year = selectedDate.year.toString();

    final result = await db.rawQuery('''
    SELECT 
      SUM(total_cgst) as total_cgst,
      SUM(total_sgst) as total_sgst,
      SUM(total_igst) as total_igst
    FROM invoice
    WHERE substr(date_added, 6, 2) = ? AND substr(date_added, 1, 4) = ?
  ''', [month, year]);

    if (result.isNotEmpty) {
      return {
        'cgst': (result[0]['total_cgst'] ?? 0.0) as double,
        'sgst': (result[0]['total_sgst'] ?? 0.0) as double,
        'igst': (result[0]['total_igst'] ?? 0.0) as double,
      };
    }

    return {'cgst': 0.0, 'sgst': 0.0, 'igst': 0.0};
  }

  static Future<List<Map<String, dynamic>>> getGstInvoicesByMonth(DateTime selectedDate) async {
    final db = await getDatabase();

    String month = selectedDate.month.toString().padLeft(2, '0');
    String year = selectedDate.year.toString();

    return await db.rawQuery('''
    SELECT 
      i.invoice_id,
      i.date_added,
      i.taxable_amount,
      i.total_amount,
      i.total_cgst,
      i.total_sgst,
      i.total_igst,
      c.client_company
    FROM invoice i
    JOIN client c ON i.client_id = c.client_id
    WHERE substr(i.date_added, 6, 2) = ? AND substr(i.date_added, 1, 4) = ?
    ORDER BY i.date_added
  ''', [month, year]);
  }

}
