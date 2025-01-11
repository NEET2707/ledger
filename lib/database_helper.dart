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
}






// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
//
// const id = "id" ;
//
// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._init();
//   static Database? _database;
//
//   DatabaseHelper._init();
//
//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB('accounts.db');
//     return _database!;
//   }
//
//   Future<Database> _initDB(String filePath) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, filePath);
//
//     return await openDatabase(
//       path,
//       version: 2,
//       onCreate: _onCreate,
//       // onUpgrade: _onUpgrade,
//     );
//   }
//
//   Future<void> _onCreate(Database db, int version) async {
//     await db.execute('PRAGMA foreign_keys = ON');
//     await db.execute('''CREATE TABLE accounts(
//       $id INTEGER PRIMARY KEY AUTOINCREMENT,
//       name TEXT,
//       mobile_number TEXT,
//       email TEXT,
//       description TEXT
//     )''');
//     await db.execute('''CREATE TABLE transactions(
//       id INTEGER PRIMARY KEY AUTOINCREMENT,
//       amount REAL,
//       transaction_date TEXT,
//       reminder_date TEXT,
//       note TEXT,
//       type TEXT,
//       account_id INTEGER,
//       FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
//     )''');
//   }
//
//   // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//   //   if (oldVersion < 2) {
//   //     await db.execute('''CREATE TABLE IF NOT EXISTS transactions(
//   //       id INTEGER PRIMARY KEY AUTOINCREMENT,
//   //       amount REAL,
//   //       transaction_date TEXT,
//   //       reminder_date TEXT,
//   //       note TEXT,
//   //       type TEXT,
//   //       account_id INTEGER,
//   //       FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
//   //     )''');
//   //   }
//   // }
//
//   Future<int> insertAccount(Map<String, dynamic> data) async {
//     final db = await database;
//     return await db.insert('accounts', data);
//   }
//
//   Future<List<Map<String, dynamic>>> fetchAccounts() async {
//     final db = await database;
//     return await db.query('accounts');
//   }
//
//   Future<int> insertTransaction(Map<String, dynamic> data) async {
//     final db = await database;
//     return await db.insert(
//       'transactions',
//       data,
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
//
//   Future<List<Map<String, dynamic>>> fetchTransactions(int accountId) async {
//     final db = await database;
//     return await db.query(
//       'transactions',
//       where: 'account_id = ?',
//       whereArgs: [accountId],
//       orderBy: 'transaction_date DESC',
//     );
//   }
//
//
//   Future<int> updateTransaction(Map<String, dynamic> transaction, int id) async {
//     final db = await database;
//     return await db.update(
//       'transactions',
//       transaction,
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }
//
//
//   Future<List<Map<String, dynamic>>> fetchAccountsWithBalance() async {
//     final db = await database;
//
//     return await db.rawQuery('''
//     SELECT
//       a.id,
//       a.name,
//       a.mobile_number,
//       (
//         -- Calculate balance as (total credits - total debits)
//         (SELECT COALESCE(SUM(amount), 0)
//          FROM transactions t
//          WHERE t.account_id = a.id AND t.type = 'credit') -
//         (SELECT COALESCE(SUM(amount), 0)
//          FROM transactions t
//          WHERE t.account_id = a.id AND t.type = 'debit')
//       ) AS balance
//     FROM accounts a
//   ''');
//   }
//
//
//
//
//
//   Future<void> debugDatabase() async {
//     final db = await database;
//     final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
//     for (final table in tables) {
//       final tableName = table['name'];
//       final data = await db.query(tableName as String);
//       print('Table $tableName: $data');
//     }
//   }
// }