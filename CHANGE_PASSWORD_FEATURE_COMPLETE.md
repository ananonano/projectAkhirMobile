# Change Password Feature - Complete ✅

## Requirements
User bisa ganti password di profile screen dengan:
1. Input password lama (untuk verifikasi)
2. Input password baru
3. Konfirmasi password baru

## Implementation

### 1. Profile Screen - UI & Dialog
**File**: `lib/screens/profile_screen.dart`

Added `_showChangePasswordDialog()` method with:
- 3 TextField inputs (old password, new password, confirm password)
- Password visibility toggle untuk setiap field
- Validation:
  - Semua field harus diisi
  - Password baru minimal 6 karakter
  - Password baru dan konfirmasi harus cocok
  - Password lama harus benar
- Loading state saat proses update
- Success/error feedback dengan SnackBar

Added menu item in settings section:
```dart
_buildSettingItem(
  Icons.lock_reset_rounded,
  'Ganti Password',
  'Ubah password akun',
  _showChangePasswordDialog,
),
```

### 2. Auth Controller - Business Logic
**File**: `lib/controllers/auth_controller.dart`

Added `updatePassword()` method:
```dart
Future<void> updatePassword(String username, String newPassword) async {
  final hashed = hashPassword(newPassword);
  await _userRepo.updatePassword(username, hashed);
}
```

Uses existing `verifyPassword()` method to check old password.

### 3. User Repository - Data Layer
**File**: `lib/repositories/user_repository.dart`

Added `updatePassword()` method:
```dart
Future<void> updatePassword(String username, String hashedPassword) async {
  await _db.updateUserPassword(username, hashedPassword);
}
```

### 4. Database Helper - Database Operation
**File**: `lib/database/database.dart`

Added `updateUserPassword()` method:
```dart
Future<int> updateUserPassword(String username, String hashedPassword) async {
  Database db = await instance.database;
  return await db.update(
    'users',
    {'password': hashedPassword},
    where: 'username = ?',
    whereArgs: [username],
  );
}
```

## User Flow

### Change Password Process:
1. User buka Profile screen
2. Scroll ke section "PENGATURAN AKUN"
3. Klik menu "Ganti Password"
4. Dialog muncul dengan 3 input fields:
   - Password Lama (dengan toggle visibility)
   - Password Baru (dengan toggle visibility)
   - Konfirmasi Password Baru (dengan toggle visibility)
5. User isi semua fields
6. Klik "Ubah Password"
7. System validasi:
   - ✅ Semua field terisi
   - ✅ Password baru minimal 6 karakter
   - ✅ Password baru = Konfirmasi password
   - ✅ Password lama benar
8. Password berhasil diubah
9. Success message muncul
10. Dialog tertutup

### Validation Rules:
| Rule | Error Message |
|------|---------------|
| Field kosong | "Semua field harus diisi" |
| Password baru < 6 karakter | "Password baru minimal 6 karakter" |
| Password baru ≠ Konfirmasi | "Password baru dan konfirmasi tidak cocok" |
| Password lama salah | "Password lama salah!" |

## Security Features

### Password Hashing:
- Password di-hash menggunakan SHA-1 sebelum disimpan
- Menggunakan method `hashPassword()` yang sudah ada di AuthController
- Konsisten dengan sistem login yang ada

### Verification:
- Password lama diverifikasi menggunakan `verifyPassword()`
- Tidak bisa update password tanpa verifikasi password lama
- Mencegah unauthorized password change

## UI/UX Features

### Dialog Design:
- Clean, modern design dengan rounded corners
- Icon lock_reset_rounded untuk visual clarity
- Informasi helper text: "Password minimal 6 karakter"
- Color-coded feedback (green = success, red = error, orange = warning)

### Password Visibility Toggle:
- Setiap field punya toggle button (eye icon)
- User bisa show/hide password per field
- Default: semua password hidden

### Loading State:
- Button disabled saat loading
- Circular progress indicator muncul
- Prevent double submission

### Feedback:
- SnackBar dengan warna sesuai status:
  - 🟢 Green: Success
  - 🔴 Red: Error
  - 🟠 Orange: Warning
- Floating SnackBar dengan rounded corners
- Auto-dismiss setelah beberapa detik

## Changes Summary
- ✅ Dialog ganti password dengan 3 input fields
- ✅ Password visibility toggle untuk setiap field
- ✅ Validasi lengkap (empty, length, match, verify old)
- ✅ Password hashing dengan SHA-1
- ✅ Loading state dan error handling
- ✅ Success/error feedback dengan SnackBar
- ✅ Menu item di profile settings
- ✅ No compilation errors

## Files Modified
1. `lib/screens/profile_screen.dart`
   - Added `_showChangePasswordDialog()` method
   - Added menu item "Ganti Password"

2. `lib/controllers/auth_controller.dart`
   - Added `updatePassword()` method

3. `lib/repositories/user_repository.dart`
   - Added `updatePassword()` method

4. `lib/database/database.dart`
   - Added `updateUserPassword()` method

## Testing Checklist
- [ ] Menu "Ganti Password" muncul di profile settings
- [ ] Dialog muncul saat klik menu
- [ ] Password visibility toggle bekerja untuk semua fields
- [ ] Validation: Empty fields ditolak
- [ ] Validation: Password < 6 karakter ditolak
- [ ] Validation: Password baru ≠ Konfirmasi ditolak
- [ ] Validation: Password lama salah ditolak
- [ ] Password berhasil diubah dengan input valid
- [ ] Success message muncul setelah update
- [ ] Bisa login dengan password baru
- [ ] Tidak bisa login dengan password lama
- [ ] Loading state muncul saat proses update
- [ ] Dialog tertutup setelah success

## Security Notes
- Password di-hash dengan SHA-1 (konsisten dengan sistem existing)
- Password lama diverifikasi sebelum update
- Tidak ada password yang disimpan dalam plain text
- Session tidak terpengaruh setelah ganti password
- User tetap login setelah ganti password
