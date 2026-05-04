import '../database/database.dart';
import '../models/chat_message_model.dart';

/// Repository untuk manage chat messages history
class ChatRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Tambah message baru ke database
  Future<int> addMessage(ChatMessage message) async {
    final database = await _db.database;
    return await database.insert('chat_messages', message.toMap());
  }

  /// Ambil semua messages dari database untuk user tertentu, ordered by created_at
  Future<List<ChatMessage>> getAllMessages(int userId) async {
    try {
      final database = await _db.database;
      final data = await database.query(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at ASC',
      );
      print('[DEBUG] Retrieved ${data.length} messages for user $userId from database');
      return data.map((map) => ChatMessage.fromMap(map)).toList();
    } catch (e) {
      print('[ERROR] Error fetching messages: $e');
      return [];
    }
  }

  /// Clear semua chat history untuk user tertentu
  Future<int> clearAllMessages(int userId) async {
    try {
      final database = await _db.database;
      int result = await database.delete(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print('[DEBUG] Cleared $result messages for user $userId from database');
      return result;
    } catch (e) {
      print('[ERROR] Error clearing messages: $e');
      return 0;
    }
  }

  /// Delete message tertentu berdasarkan ID
  Future<int> deleteMessage(int id) async {
    try {
      final database = await _db.database;
      return await database.delete(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('[ERROR] Error deleting message: $e');
      return 0;
    }
  }
}
