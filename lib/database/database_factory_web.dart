import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

/// Web implementation using sqflite_common_ffi_web
Future<Database> getDatabaseWeb({
  required int version,
  required Future<void> Function(Database, int) onCreate,
  required Future<void> Function(Database, int, int) onUpgrade,
}) async {
  print('[DB_WEB] Starting web database initialization...');
  
  try {
    // Set the database factory for web
    databaseFactory = databaseFactoryFfiWeb;
    print('[DB_WEB] Database factory set to web');
    
    // Open database in browser's IndexedDB
    print('[DB_WEB] Opening database...');
    final db = await openDatabase(
      'lapangin.db',
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
    
    print('[DB_WEB] Database opened successfully');
    return db;
  } catch (e, stackTrace) {
    print('[DB_WEB] ERROR: Failed to initialize web database');
    print('[DB_WEB] Error: $e');
    print('[DB_WEB] StackTrace: $stackTrace');
    rethrow;
  }
}

Future<Database> getDatabaseIO({
  required int version,
  required Future<void> Function(Database, int) onCreate,
  required Future<void> Function(Database, int, int) onUpgrade,
}) async {
  throw UnsupportedError('IO database not supported in Web implementation');
}
