# Chat Per User Feature - Complete ✅

## Problem
Semua akun share chat history yang sama. Ketika user A chat dengan bot, user B juga bisa lihat chat history user A.

## Solution
Setiap user sekarang punya chat history sendiri-sendiri yang terpisah berdasarkan `user_id`.

## Implementation

### 1. Database Schema Update
**File**: `lib/database/database.dart`

**Updated chat_messages table:**
```sql
CREATE TABLE chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,              -- NEW: User ID pemilik chat
  role TEXT NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
)
```

**Migration v10:**
- Database version: 9 → 10
- Added `user_id` column to existing `chat_messages` table
- Default value: 1 (for existing messages)
- Foreign key constraint to `users` table
- CASCADE delete: chat messages dihapus otomatis kalau user dihapus

### 2. ChatMessage Model Update
**File**: `lib/models/chat_message_model.dart`

Added `userId` field:
```dart
class ChatMessage {
  final int? id;
  final int userId;        // NEW: User ID pemilik chat
  final String role;
  final String text;
  final String? createdAt;
  
  ChatMessage({
    this.id,
    required this.userId,  // Required parameter
    required this.role,
    required this.text,
    this.createdAt,
  });
}
```

### 3. ChatRepository Update
**File**: `lib/repositories/chat_repository.dart`

**Updated methods to filter by user_id:**

```dart
// Get messages for specific user only
Future<List<ChatMessage>> getAllMessages(int userId) async {
  final data = await database.query(
    'chat_messages',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'created_at ASC',
  );
  return data.map((map) => ChatMessage.fromMap(map)).toList();
}

// Clear messages for specific user only
Future<int> clearAllMessages(int userId) async {
  return await database.delete(
    'chat_messages',
    where: 'user_id = ?',
    whereArgs: [userId],
  );
}
```

### 4. ChatScreen Update
**File**: `lib/screens/chat_screen.dart`

**Added user_id state and loading:**
```dart
class _ChatScreenState extends State<ChatScreen> {
  int _userId = 0; // Store current user ID
  
  @override
  void initState() {
    super.initState();
    _loadUserIdAndChat(); // Load user ID first, then chat
  }
  
  Future<void> _loadUserIdAndChat() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    setState(() {
      _userId = userId;
    });
    await _loadChatHistory();
  }
}
```

**Updated message operations:**
- `_sendMessage()`: Pass `userId` when creating ChatMessage
- `_loadChatHistory()`: Load messages for current user only
- `_clearHistory()`: Clear messages for current user only

## How It Works

### User Flow:

1. **User Login**
   - User login dengan username/password
   - System save `user_id` ke SharedPreferences
   
2. **Open Chat Screen**
   - Screen load `user_id` dari SharedPreferences
   - Load chat history untuk `user_id` tersebut dari database
   - Display messages milik user tersebut saja

3. **Send Message**
   - User ketik pesan dan send
   - Message disimpan dengan `user_id` user yang login
   - AI response juga disimpan dengan `user_id` yang sama

4. **Clear History**
   - User klik "Clear History"
   - Hanya messages dengan `user_id` user tersebut yang dihapus
   - Messages user lain tetap aman

5. **Switch Account**
   - User logout dan login dengan akun lain
   - Chat screen load messages untuk `user_id` baru
   - Messages akun sebelumnya tidak terlihat

### Data Isolation:

| User | user_id | Chat Messages |
|------|---------|---------------|
| danang | 2 | Only messages with user_id=2 |
| admin | 1 | Only messages with user_id=1 |
| budi | 3 | Only messages with user_id=3 |

Each user sees only their own chat history!

## Database Migration

### For Existing Users:
- Existing messages get `user_id = 1` (default)
- New messages get actual `user_id` from logged-in user
- No data loss during migration

### For New Installations:
- Table created with `user_id` column from start
- All messages require `user_id` on insert

## Security & Privacy

### Data Isolation:
- ✅ User A cannot see User B's chat history
- ✅ Each user has completely separate chat history
- ✅ Clear history only affects current user

### Foreign Key Constraint:
- ✅ If user deleted, their chat messages auto-deleted (CASCADE)
- ✅ Cannot insert message with invalid user_id
- ✅ Data integrity maintained

## Changes Summary
- ✅ Database schema updated with `user_id` column
- ✅ Migration v10 added for existing databases
- ✅ ChatMessage model includes `userId` field
- ✅ ChatRepository filters by `user_id`
- ✅ ChatScreen loads user-specific messages
- ✅ Each user has isolated chat history
- ✅ No compilation errors
- ✅ Backward compatible with migration

## Files Modified
1. `lib/database/database.dart`
   - Updated schema: added `user_id` to chat_messages
   - Added migration v10
   - Version: 9 → 10

2. `lib/models/chat_message_model.dart`
   - Added `userId` field
   - Updated constructor and fromMap/toMap methods

3. `lib/repositories/chat_repository.dart`
   - Updated `getAllMessages(int userId)`
   - Updated `clearAllMessages(int userId)`
   - Removed unused import

4. `lib/screens/chat_screen.dart`
   - Added `_userId` state variable
   - Added `_loadUserIdAndChat()` method
   - Updated `_sendMessage()` to pass userId
   - Updated `_clearHistory()` to clear for current user
   - Added SharedPreferences import

## Testing Checklist
- [ ] Login dengan user A
- [ ] Send beberapa messages di chat
- [ ] Logout dan login dengan user B
- [ ] Chat screen kosong (tidak ada messages user A)
- [ ] Send messages sebagai user B
- [ ] Logout dan login kembali sebagai user A
- [ ] Messages user A masih ada (tidak hilang)
- [ ] Messages user B tidak terlihat
- [ ] Clear history sebagai user A
- [ ] Messages user A terhapus
- [ ] Login sebagai user B
- [ ] Messages user B masih ada (tidak terhapus)

## Technical Notes
- Database version incremented: 9 → 10
- Migration runs automatically on app start
- Existing messages assigned to user_id=1 by default
- New messages use actual logged-in user_id
- Foreign key ensures data integrity
- CASCADE delete prevents orphaned messages
