import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'ADD/ADD/transaction_search.dart';

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

  // Future<List<Map<String, dynamic>>> fetchTransactionsByDateAndType({
  //   required DateTime startDate,
  //   required DateTime endDate,
  //   required String filterType, // 'ALL', 'CREDIT', or 'DEBIT'
  // }) async {
  //   final db = await database;
  //
  //   // Extend the end date by 1 day for <= comparison
  //   final adjustedEndDate = endDate.add(const Duration(days: 1));
  //
  //   // Convert to strings for comparison
  //   final String startStr = DateFormat('yyyy-MM-dd').format(startDate);
  //   final String endStr = DateFormat('yyyy-MM-dd').format(adjustedEndDate);
  //
  //   String whereClause = '''
  //   date(substr(t.$transaction_date, 1, 10)) >= ? AND
  //   date(substr(t.$transaction_date, 1, 10)) < ? AND
  //   t.$transaction_is_delete = 0
  // ''';
  //
  //   List<dynamic> whereArgs = [startStr, endStr];
  //
  //   if (filterType == 'CREDIT') {
  //     whereClause += ' AND t.$transaction_is_credited = 1';
  //   } else if (filterType == 'DEBIT') {
  //     whereClause += ' AND t.$transaction_is_credited = 0';
  //   }
  //
  //   final result = await db.rawQuery('''
  //   SELECT t.*, a.$accountName
  //   FROM transactions t
  //   JOIN accounts a ON t.$transaction_accountId = a.$accountId
  //   WHERE $whereClause
  //   ORDER BY t.$transaction_date DESC
  // ''', whereArgs);
  //
  //   return result;
  // }


}

