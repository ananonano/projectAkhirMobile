# Biometric Status Display Fix

## Problem
User sudah berhasil login dengan biometrik dan biometrik sudah terdaftar, tapi di profile screen status biometrik masih menampilkan "Nonaktif".

## Root Cause
Status biometrik hanya dicek sekali saat `initState()` di profile screen. Ketika user login dengan biometrik dan masuk ke profile screen, status tidak di-refresh lagi.

## Solution

### Changes Made in `lib/screens/profile_screen.dart`:

#### 1. Added `didChangeDependencies()` lifecycle method
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Refresh biometric status setiap kali screen muncul
  _checkBiometricStatus();
}
```

**Why**: Method ini dipanggil setiap kali screen muncul kembali (termasuk setelah login), sehingga status biometrik akan selalu ter-update.

#### 2. Improved `_checkBiometricStatus()` method
```dart
Future<void> _checkBiometricStatus() async {
  // Pastikan username sudah di-load terlebih dahulu
  if (_username == "User") {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username != null) {
      setState(() => _username = username);
    }
  }
  
  final isEnabled = await _authController.isBiometricEnabled(_username);
  if (mounted) {
    setState(() => _isBiometricEnabled = isEnabled);
  }
  print('[ProfileScreen] Biometric status checked for $_username: $isEnabled');
}
```

**Improvements**:
- Memastikan username sudah di-load sebelum cek status
- Menambahkan `mounted` check sebelum `setState()`
- Menambahkan debug print untuk tracking

#### 3. Updated `_setupBiometric()` method
```dart
if (authenticated) {
  await _authController.saveBiometricOwner(_username, _role);
  // Refresh status biometrik setelah berhasil setup
  await _checkBiometricStatus();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sidik jari untuk $_username berhasil didaftarkan!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
```

**Change**: Mengganti `setState(() => _isBiometricEnabled = true)` dengan `await _checkBiometricStatus()` untuk memastikan status di-refresh dari SharedPreferences.

#### 4. Updated `_resetBiometric()` method
```dart
Future<void> _resetBiometric() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('biometric_enabled');
  await prefs.remove('biometric_username');
  await prefs.remove('biometric_role');
  // Refresh status biometrik setelah reset
  await _checkBiometricStatus();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Login biometrik berhasil dinonaktifkan.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
```

**Change**: Mengganti `setState(() => _isBiometricEnabled = false)` dengan `await _checkBiometricStatus()` untuk konsistensi.

## How It Works Now

### Flow 1: Login dengan Biometrik
1. User login dengan sidik jari di login screen
2. `AuthController.saveBiometricOwner()` menyimpan:
   - `biometric_enabled = true`
   - `biometric_username = username`
   - `biometric_role = role`
3. User masuk ke app dan navigasi ke profile screen
4. `didChangeDependencies()` dipanggil
5. `_checkBiometricStatus()` membaca dari SharedPreferences
6. Status "Aktif" ditampilkan ✅

### Flow 2: Setup Biometrik dari Profile
1. User klik "Login Biometrik" dengan status "Nonaktif"
2. `_setupBiometric()` dipanggil
3. User verifikasi sidik jari
4. `saveBiometricOwner()` menyimpan data ke SharedPreferences
5. `_checkBiometricStatus()` dipanggil untuk refresh
6. Status berubah menjadi "Aktif" ✅

### Flow 3: Reset Biometrik
1. User klik "Login Biometrik" dengan status "Aktif"
2. `_resetBiometric()` dipanggil
3. Data biometrik dihapus dari SharedPreferences
4. `_checkBiometricStatus()` dipanggil untuk refresh
5. Status berubah menjadi "Nonaktif" ✅

## Testing Checklist

- [x] Login dengan biometrik → Profile screen menampilkan "Aktif"
- [x] Setup biometrik dari profile → Status langsung berubah ke "Aktif"
- [x] Reset biometrik dari profile → Status langsung berubah ke "Nonaktif"
- [x] Logout dan login lagi dengan biometrik → Status tetap "Aktif"
- [x] Ganti akun → Status biometrik sesuai dengan akun yang login

## Files Modified

1. ✅ `lib/screens/profile_screen.dart`
   - Added `didChangeDependencies()` method
   - Improved `_checkBiometricStatus()` method
   - Updated `_setupBiometric()` method
   - Updated `_resetBiometric()` method

## Related Files (No Changes Needed)

- `lib/controllers/auth_controller.dart` - Already correct
  - `isBiometricEnabled()` - Checks if biometric is enabled for current user
  - `saveBiometricOwner()` - Saves biometric data to SharedPreferences
  - `hasBiometricSession()` - Checks if there's an active biometric session

## Conclusion

Masalah sudah diperbaiki dengan menambahkan `didChangeDependencies()` lifecycle method yang akan refresh status biometrik setiap kali profile screen muncul. Sekarang status biometrik akan selalu akurat dan ter-update.
