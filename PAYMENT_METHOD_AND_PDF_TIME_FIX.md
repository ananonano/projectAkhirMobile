# Payment Method & PDF Time Display Fix ✅

## Summary
1. **Payment Method**: Now saves actual payment method (QRIS, PayPal, etc.) to database instead of "Telah Dibayar"
2. **PDF Time Display**: Times now display 4 per row, then wrap to next row (no overflow)

---

## Part 1: Payment Method Storage

### Problem
- Payment method was not saved to database
- Booking history showed "Telah Dibayar" (payment status) instead of actual method
- PDF showed "Telah Dibayar" instead of QRIS, PayPal, etc.

### Solution
Added `payment_method` column to bookings table and save actual payment method selected by user.

---

## Database Changes

### Schema Update
**Version**: 8 → 9

**New Column**:
```sql
ALTER TABLE bookings ADD COLUMN payment_method TEXT DEFAULT "QRIS"
```

**Complete Table**:
```sql
CREATE TABLE bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  lapangan_id INTEGER,
  nama_lapangan TEXT,
  tanggal TEXT,
  jam TEXT,
  total_harga TEXT,
  status TEXT DEFAULT "completed",
  payment_method TEXT DEFAULT "QRIS",  -- ← NEW
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
```

### Migration
```dart
if (oldVersion < 9) {
  try {
    await db.execute('ALTER TABLE bookings ADD COLUMN payment_method TEXT DEFAULT "QRIS"');
    print('[DB] Successfully upgraded schema to v9 - Added payment_method to bookings');
  } catch (e) {
    print('[DB] Upgrade warning v9: $e');
  }
}
```

---

## Model Update

### BookingModel
**File**: `lib/models/booking_model.dart`

**Added Field**:
```dart
final String? paymentMethod;
```

**Constructor**:
```dart
BookingModel({
  ...
  this.paymentMethod = 'QRIS',
});
```

**fromMap**:
```dart
paymentMethod: map['payment_method'] ?? 'QRIS',
```

**toMap**:
```dart
'payment_method': paymentMethod ?? 'QRIS',
```

---

## Controller Update

### BookingController
**File**: `lib/controllers/booking_controller.dart`

**Added Parameter**:
```dart
Future<int> createBooking({
  ...
  String? paymentMethod,  // ← NEW
}) async {
  final booking = BookingModel(
    ...
    paymentMethod: paymentMethod ?? 'QRIS',
  );
  ...
}
```

---

## Payment Screen Update

### Pass Payment Method
**File**: `lib/screens/payment_screen.dart`

**Before**:
```dart
await _bookingController.createBooking(
  userId: userId,
  lapanganId: widget.lapangan['id'],
  ...
);
```

**After**:
```dart
await _bookingController.createBooking(
  userId: userId,
  lapanganId: widget.lapangan['id'],
  ...
  paymentMethod: _paymentMethod,  // ← Pass actual method
);
```

---

## Booking Screen Update

### Use Saved Payment Method
**File**: `lib/screens/booking_screen.dart`

**Before**:
```dart
metodeBayar: 'Telah Dibayar',  // ❌ Wrong
```

**After**:
```dart
metodeBayar: item.paymentMethod ?? 'QRIS',  // ✅ Correct
```

---

## Payment Method Values

### Possible Values
From payment screen selection:

1. **QRIS / E-Wallet (Lokal)**
   - For IDR currency
   - GoPay, OVO, Dana, ShopeePay

2. **QRIS Antarnegara**
   - For non-IDR QRIS-supported currencies
   - Cross-border QRIS

3. **International Credit Card**
   - Visa, Mastercard, AMEX, JCB

4. **PayPal**
   - Global payment

### Display
- **Booking History**: Shows actual method
- **Receipt Screen**: Shows actual method
- **PDF**: Shows actual method

---

## Part 2: PDF Time Display Fix

### Problem
Times were displayed one per line, taking too much vertical space:
```
Time    09:00
        10:00
        11:00
        12:00
        13:00
        14:00
```

### Solution
Display 4 times per row, then wrap to next row:
```
Time    09:00, 10:00, 11:00, 12:00
        13:00, 14:00
```

---

## Implementation

### Method: `_buildTimesList()`
**File**: `lib/screens/receipt_screen.dart`

```dart
List<pw.Widget> _buildTimesList(String jam) {
  // Split times by comma
  final times = jam.split(',').map((e) => e.trim()).toList();
  
  List<pw.Widget> widgets = [];
  
  // Group times into rows of 4
  for (int i = 0; i < times.length; i += 4) {
    final endIndex = (i + 4 < times.length) ? i + 4 : times.length;
    final rowTimes = times.sublist(i, endIndex);
    
    widgets.add(
      pw.Text(
        rowTimes.join(', '),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey900,
        ),
        textAlign: pw.TextAlign.right,
      ),
    );
    
    // Add spacing between rows (except last one)
    if (endIndex < times.length) {
      widgets.add(pw.SizedBox(height: 4));
    }
  }
  
  return widgets;
}
```

---

## PDF Layout Examples

### 1-4 Times (Single Row)
```
Date              15 Jan 2026
Time              09:00, 10:00, 11:00, 12:00
Payment Method    QRIS / E-Wallet (Lokal)
```

### 5-8 Times (Two Rows)
```
Date              15 Jan 2026
Time              09:00, 10:00, 11:00, 12:00
                  13:00, 14:00, 15:00, 16:00
Payment Method    PayPal
```

### 9-12 Times (Three Rows)
```
Date              15 Jan 2026
Time              09:00, 10:00, 11:00, 12:00
                  13:00, 14:00, 15:00, 16:00
                  17:00, 18:00, 19:00, 20:00
Payment Method    International Credit Card
```

### 3 Times (Partial Row)
```
Date              3 Mei 2026
Time              15:00, 17:00, 20:00
Payment Method    QRIS Antarnegara
```

---

## Benefits

### Payment Method
✅ **Accurate Information**: Shows what user actually paid with
✅ **Better Records**: Clear payment method in database
✅ **Customer Support**: Easy to identify payment issues
✅ **Reporting**: Can analyze payment method preferences

### PDF Time Display
✅ **Space Efficient**: 4 times per row instead of 1
✅ **No Overflow**: Always fits in page width
✅ **Clean Layout**: Organized and readable
✅ **Flexible**: Works with any number of times

---

## Migration Required

### ⚠️ Database Version Change
**Old Version**: 8
**New Version**: 9

### Migration Behavior
- **Existing bookings**: Will have `payment_method = "QRIS"` (default)
- **New bookings**: Will save actual payment method
- **No data loss**: All existing data preserved

### User Action
**Run app normally** - migration happens automatically on first launch after update.

---

## Testing Checklist

### Payment Method
- [ ] Create new booking with QRIS
- [ ] Check booking history shows "QRIS / E-Wallet (Lokal)"
- [ ] Check PDF shows "QRIS / E-Wallet (Lokal)"
- [ ] Create booking with PayPal
- [ ] Check shows "PayPal" everywhere
- [ ] Create booking with Credit Card
- [ ] Check shows "International Credit Card"

### PDF Time Display
- [ ] Booking with 1-4 times → Single row
- [ ] Booking with 5-8 times → Two rows
- [ ] Booking with 9+ times → Multiple rows
- [ ] No horizontal overflow
- [ ] Times aligned to right
- [ ] Proper spacing between rows

---

## Files Modified

1. ✅ `lib/database/database.dart`
   - Added payment_method column
   - Added migration to v9
   - Updated version to 9

2. ✅ `lib/models/booking_model.dart`
   - Added paymentMethod field
   - Updated fromMap and toMap

3. ✅ `lib/controllers/booking_controller.dart`
   - Added paymentMethod parameter
   - Pass to BookingModel

4. ✅ `lib/screens/payment_screen.dart`
   - Pass _paymentMethod to createBooking

5. ✅ `lib/screens/booking_screen.dart`
   - Use item.paymentMethod instead of "Telah Dibayar"

6. ✅ `lib/screens/receipt_screen.dart`
   - Updated _buildTimesList() to group 4 per row

---

## Summary

✅ **Payment Method**: Now saves and displays actual payment method (QRIS, PayPal, etc.)

✅ **PDF Time Display**: Shows 4 times per row, wraps to next row

✅ **Database Migration**: Automatic upgrade from v8 to v9

✅ **No Data Loss**: Existing bookings get default "QRIS"

✅ **Better UX**: Clear, accurate information everywhere

---

The payment method is now properly saved and displayed, and PDF times are organized efficiently! 🎉
