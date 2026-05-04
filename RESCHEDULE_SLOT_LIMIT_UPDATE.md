# Reschedule Slot Limit Update - COMPLETE ✅

## Problem
User yang booking 1 jam bisa reschedule dengan memilih banyak jam (tidak terbatas). Harusnya jumlah jam yang bisa dipilih saat reschedule harus sama dengan jumlah jam booking asli.

## Solution
Implementasi pembatasan jumlah slot yang bisa dipilih saat reschedule berdasarkan booking asli.

## Business Rules Updated
- **Booking 1 jam** → Reschedule hanya bisa pilih **1 jam**
- **Booking 3 jam** → Reschedule hanya bisa pilih **3 jam**
- **Booking N jam** → Reschedule hanya bisa pilih **N jam**

## Implementation Details

### 1. Calculate Max Selectable Slots
```dart
late int _maxSelectableSlots; // Jumlah jam yang bisa dipilih

@override
void initState() {
  super.initState();
  // Hitung jumlah jam dari booking asli
  final originalTimes = widget.booking.jam.split(',').map((e) => e.trim()).toList();
  _maxSelectableSlots = originalTimes.length;
  // ...
}
```

### 2. Disable Time Slots When Limit Reached
```dart
final canSelect = _selectedTimes.length < _maxSelectableSlots || isSelected;

GestureDetector(
  onTap: (isPassed || (!canSelect && !isSelected))
      ? null  // Disable jika sudah mencapai limit
      : () {
          // Allow selection/deselection
        },
  // ...
)
```

**Logic:**
- Jika `_selectedTimes.length < _maxSelectableSlots` → Masih bisa pilih
- Jika sudah mencapai limit → Hanya bisa deselect yang sudah dipilih
- Slot yang belum dipilih akan disabled (grey) saat limit tercapai

### 3. Visual Feedback
- **Available slots** (white) → Bisa dipilih jika belum mencapai limit
- **Selected slots** (green) → Sudah dipilih, bisa di-deselect
- **Disabled slots** (grey) → Tidak bisa dipilih karena:
  - Sudah di-booking user lain
  - Jam sudah lewat (untuk hari ini)
  - **Limit sudah tercapai** (NEW!)

### 4. Info Banner
Ditambahkan info banner biru di atas time slots:
```
ℹ️ Pilih N jam (sama dengan booking asli)
```

### 5. Counter Update
Counter di bawah time slots sekarang menampilkan:
```
Dipilih: X/N jam (09:00, 10:00, ...)
```
- X = jumlah yang sudah dipilih
- N = jumlah maksimal (dari booking asli)

### 6. Validation Before Confirm
```dart
if (_selectedTimes.length != _maxSelectableSlots) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Anda harus memilih $_maxSelectableSlots jam (sama dengan booking asli)'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

## User Experience Flow

### Example 1: Booking 1 Jam
1. User booking jam 10:00 (1 jam)
2. User tap "Reschedule"
3. UI shows: "Pilih 1 jam (sama dengan booking asli)"
4. User pilih jam 14:00
5. Semua slot lain langsung disabled (grey)
6. Counter shows: "Dipilih: 1/1 jam (14:00)"
7. User tap "Konfirmasi Reschedule" → Success ✅

### Example 2: Booking 3 Jam
1. User booking jam 09:00, 10:00, 11:00 (3 jam)
2. User tap "Reschedule"
3. UI shows: "Pilih 3 jam (sama dengan booking asli)"
4. User pilih jam 14:00 → Counter: "1/3 jam"
5. User pilih jam 15:00 → Counter: "2/3 jam"
6. User pilih jam 16:00 → Counter: "3/3 jam"
7. Semua slot lain langsung disabled (grey)
8. User tap "Konfirmasi Reschedule" → Success ✅

### Example 3: User Coba Pilih Kurang dari Limit
1. User booking 3 jam
2. User hanya pilih 2 jam
3. User tap "Konfirmasi Reschedule"
4. System shows error: "Anda harus memilih 3 jam (sama dengan booking asli)"
5. User harus pilih 1 jam lagi ❌

## UI Changes

### Before:
- ❌ User bisa pilih unlimited jam
- ❌ Tidak ada info berapa jam yang harus dipilih
- ❌ Counter hanya show jumlah tanpa limit

### After:
- ✅ User hanya bisa pilih sesuai booking asli
- ✅ Info banner menjelaskan berapa jam yang harus dipilih
- ✅ Counter show progress: "X/N jam"
- ✅ Slot auto-disabled saat limit tercapai
- ✅ Validation error jika jumlah tidak sesuai

## Files Modified
- `lib/screens/booking_screen.dart`
  - Added `_maxSelectableSlots` variable
  - Updated `initState()` to calculate max slots
  - Updated time slot tap logic with `canSelect` check
  - Added info banner above time slots
  - Updated counter to show "X/N jam"
  - Added validation in `_confirmReschedule()`

## Testing Scenarios

### ✅ Test 1: Booking 1 jam
- Booking: 10:00
- Reschedule: Pilih 14:00
- Expected: Bisa pilih 1 jam, slot lain disabled ✅

### ✅ Test 2: Booking 3 jam
- Booking: 09:00, 10:00, 11:00
- Reschedule: Pilih 14:00, 15:00, 16:00
- Expected: Bisa pilih 3 jam, slot lain disabled ✅

### ✅ Test 3: Coba pilih kurang
- Booking: 3 jam
- Reschedule: Pilih 2 jam → Tap konfirmasi
- Expected: Error message muncul ✅

### ✅ Test 4: Deselect dan pilih lagi
- Booking: 2 jam
- Reschedule: Pilih 10:00, 11:00 → Deselect 11:00 → Pilih 12:00
- Expected: Bisa deselect dan pilih slot lain ✅

## Status
✅ **COMPLETE** - Ready for testing

---
**Update Date**: May 4, 2026
**Developer**: Kiro AI Assistant
