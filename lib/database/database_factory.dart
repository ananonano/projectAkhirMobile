import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for platform-specific implementations
import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart'
    if (dart.library.html) 'database_factory_web.dart';

/// Factory class to get platform-specific database
class PlatformDatabaseFactory {
  static Future<Database> getDatabase({
    required int version,
    required Future<void> Function(Database, int) onCreate,
    required Future<void> Function(Database, int, int) onUpgrade,
  }) async {
    if (kIsWeb) {
      return getDatabaseWeb(
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
    } else {
      return getDatabaseIO(
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
    }
  }
}
