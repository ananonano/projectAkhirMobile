import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  // Singleton pattern biar database cuma diinisialisasi sekali
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'lapangin.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // 1. Tabel Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    // 2. Tabel Lapangans
    await db.execute('''
      CREATE TABLE lapangans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_lapangan TEXT,
        jenis TEXT,
        harga INTEGER,
        lat REAL,
        lng REAL
      )
    ''');

    // 3. Tabel Bookings
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        lapangan_id INTEGER,
        tanggal_main TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (lapangan_id) REFERENCES lapangans (id)
      )
    ''');

    // --- Insert Dummy Data Lapangan biar LBS langsung jalan ---
    await db.insert('lapangans', {
      'nama_lapangan': 'Gor Futsal UPN',
      'jenis': 'Futsal',
      'harga': 120000,
      'lat': -7.7613,
      'lng': 110.4090,
    });

    await db.insert('lapangans', {
      'nama_lapangan': 'Condongcatur Badminton',
      'jenis': 'Badminton',
      'harga': 40000,
      'lat': -7.7562,
      'lng': 110.4045,
    });

    await db.insert('lapangans', {
      'nama_lapangan': 'Seturan Basketball',
      'jenis': 'Basket',
      'harga': 150000,
      'lat': -7.7651,
      'lng': 110.4072,
    });

    // --- Insert Akun Default biar bisa langsung login ---
    await db.insert('users', {
      'username': 'admin',
      // Ini adalah hasil enkripsi SHA-1 dari kata 'password123'
      'password': '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8' 
    });
  }

  // --- Fungsi CRUD Basic buat Authentication ---

  // Register User Baru
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await instance.database;
    return await db.insert('users', user);
  }

  // Cek Login User
  Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
