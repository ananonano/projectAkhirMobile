# Booking Debug Logging - Troubleshooting

## Issue Report
User melaporkan bahwa booking tidak masuk untuk akun selain "danang". Booking tidak muncul di riwayat booking.

## Debug Logging Added

### 1. Auth Controller - Session Management
**File**: `lib/controllers/auth_controller.dart`

#### A. saveSession() Method
```dart
Future<void> saveSession(UserModel user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  await prefs.setInt('user_id', user.id ?? 0);
  await prefs.setString('username', user.username);
  await prefs.setString('role', user.role);
  
  // Debug logging
  print('[AuthController] Session saved:');
  print('  - user_id: ${user.id}');
  print('  - username: ${user.username}');
  print('  - role: ${user.role}');
}
```

**What to check**:
- Is user_id being saved correctly?
- Is user_id null or 0?

#### B. getSessionUserId() Method
```dart
Future<int> getSessionUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;
  print('[AuthController] getSessionUserId: $userId');
  return userId;
}
```

**What to check**:
- Is userId being retrieved correctly?
- Is it returning 0 (default) or actual user_id?

### 2. Payment Screen - Booking Creation
**File**: `lib/screens/payment_screen.dart`

#### _prosesBayar() Method
```dart
Future<void> _prosesBayar() async {
  final int hargaPerJam = widget.lapangan['harga'] ?? 0;
  final userId = await _authController.getSessionUserId();
  
  // Debug logging
  print('[PaymentScreen] Processing payment for userId: $userId');
  print('[PaymentScreen] Lapangan: ${widget.lapangan['nama_lapangan']}');
  print('[PaymentScreen] Date: ${widget.selectedDate}');
  print('[PaymentScreen] Times: ${widget.selectedTimes}');
  
  try {
    final bookingId = await _bookingController.createBooking(
      userId: userId,
      lapanganId: widget.lapangan['id'],
      namaLapangan: widget.lapangan['nama_lapangan'],
      tanggal: widget.selectedDate,
      selectedTimes: widget.selectedTimes,
      hargaPerJam: hargaPerJam,
      paymentMethod: _paymentMethod,
    );
    
    print('[PaymentScreen] Booking created with ID: $bookingId');
    // ...
  } catch (e) {
    print('[PaymentScreen] Error creating booking: $e');
    // ...
  }
}
```

**What to check**:
- Is userId correct when creating booking?
- Is booking being created successfully?
- What is the bookingId returned?
- Are there any errors?

### 3. Booking Screen - Fetching Bookings
**File**: `lib/screens/booking_screen.dart`

#### _getMyBookings() Method
```dart
Future<List<BookingModel>> _getMyBookings() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;
  final username = prefs.getString('username') ?? '';
  
  print('[BookingScreen] Getting bookings for userId: $userId, username: $username');
  
  final bookings = await _controller.getMyBookings(userId);
  
  print('[BookingScreen] Found ${bookings.length} bookings');
  for (var booking in bookings) {
    print('[BookingScreen] Booking ID: ${booking.id}, User ID: ${booking.userId}, Lapangan: ${booking.namaLapangan}');
  }
  
  return bookings;
}
```

**What to check**:
- Is userId correct when fetching bookings?
- How many bookings are found?
- Do the booking user_ids match the current user_id?

## Testing Steps

### Step 1: Login with Different User
1. Logout if currently logged in
2. Login with user "vano" (or any user except "danang")
3. Check console for:
   ```
   [AuthController] Session saved:
     - user_id: X
     - username: vano
     - role: user
   ```
4. **Verify**: Is user_id a valid number (not 0)?

### Step 2: Navigate to Booking Screen
1. Go to Booking/History screen
2. Check console for:
   ```
   [BookingScreen] Getting bookings for userId: X, username: vano
   [BookingScreen] Found Y bookings
   ```
3. **Verify**: Does userId match the one from login?

### Step 3: Create New Booking
1. Select a lapangan
2. Select date and times
3. Go to payment screen
4. Complete payment (biometric or password)
5. Check console for:
   ```
   [AuthController] getSessionUserId: X
   [PaymentScreen] Processing payment for userId: X
   [PaymentScreen] Lapangan: [name]
   [PaymentScreen] Date: [date]
   [PaymentScreen] Times: [times]
   [PaymentScreen] Booking created with ID: Y
   ```
6. **Verify**: 
   - Is userId correct?
   - Is booking created successfully?
   - Is bookingId returned?

### Step 4: Check Booking Screen Again
1. Go back to Booking screen
2. Check console for:
   ```
   [BookingScreen] Getting bookings for userId: X, username: vano
   [BookingScreen] Found Y bookings
   [BookingScreen] Booking ID: Y, User ID: X, Lapangan: [name]
   ```
3. **Verify**: 
   - Is new booking showing up?
   - Does booking user_id match current user_id?

## Possible Issues & Solutions

### Issue 1: user_id is 0 or null
**Symptom**: 
```
[AuthController] Session saved:
  - user_id: 0  // or null
```

**Cause**: User model from database doesn't have id field populated

**Solution**: Check database query in UserRepository.login() or loginWithEmailOrUsername()

### Issue 2: user_id changes between login and payment
**Symptom**:
```
[AuthController] Session saved: user_id: 5
[PaymentScreen] Processing payment for userId: 0
```

**Cause**: Session is being cleared or overwritten

**Solution**: Check if logout() is being called unexpectedly

### Issue 3: Booking created but not showing
**Symptom**:
```
[PaymentScreen] Booking created with ID: 10
[BookingScreen] Found 0 bookings
```

**Cause**: Booking is created with wrong user_id

**Solution**: Check BookingController.createBooking() and database insert

### Issue 4: Wrong user_id in booking
**Symptom**:
```
[BookingScreen] Booking ID: 10, User ID: 1, Lapangan: [name]
// But current user_id is 5
```

**Cause**: Booking created with hardcoded or wrong user_id

**Solution**: Check BookingController.createBooking() parameter passing

## Database Check

### Query to check bookings
```sql
SELECT id, user_id, nama_lapangan, tanggal, jam, created_at 
FROM bookings 
ORDER BY id DESC 
LIMIT 10;
```

### Query to check users
```sql
SELECT id, username, name, email, role 
FROM users;
```

### Expected Data
- User "danang" should have id = 2
- User "vano" should have id = 3
- User "atilla" should have id = 4
- User "najla" should have id = 5

## Next Steps

1. **Run the app** with debug logging enabled
2. **Login** with user "vano"
3. **Create a booking**
4. **Check console logs** for the flow
5. **Identify** where the issue occurs
6. **Report findings** with console output

## Files Modified

1. ✅ `lib/controllers/auth_controller.dart` - Added debug logging
2. ✅ `lib/screens/payment_screen.dart` - Added debug logging
3. ✅ `lib/screens/booking_screen.dart` - Added debug logging

## How to Use

1. Open terminal/console to see debug output
2. Run app: `flutter run`
3. Follow testing steps above
4. Copy console output
5. Analyze the logs to find the issue

---

**Status**: Debug logging added, ready for testing
**Next**: Run app and collect console logs
