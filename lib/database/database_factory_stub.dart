import 'package:sqflite/sqflite.dart';

/// Stub implementation (should never be called)
Future<Database> getDatabaseIO({
  required int version,
  required Future<void> Function(Database, int) onCreate,
  required Future<void> Function(Database, int, int) onUpgrade,
}) async {
  throw UnsupportedError('Cannot create database without dart:io or dart:html');
}

Future<Database> getDatabaseWeb({
  required int version,
  required Future<void> Function(Database, int) onCreate,
  required Future<void> Function(Database, int, int) onUpgrade,
}) async {
  throw UnsupportedError('Cannot create database without dart:io or dart:html');
}
