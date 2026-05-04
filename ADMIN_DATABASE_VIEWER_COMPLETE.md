# Admin Database Viewer - Complete ✅

## Task Summary
Menambahkan menu Database di admin panel untuk melihat semua tabel dan data di database aplikasi.

## Features Implemented

### 1. New Menu in Admin Drawer
**File**: `lib/widgets/admin_drawer.dart`

#### Added to Enum:
```dart
enum AdminMenuIndex {
  dashboard,
  bookings,
  venueManager,
  revenue,
  database,  // ✅ NEW
  settings,
}
```

#### Added to Menu Items:
```dart
{
  'label': 'Database',
  'icon': Icons.storage_rounded,
  'menu': AdminMenuIndex.database,
}
```

### 2. Database Viewer Screen
**File**: `lib/screens/admin_database_screen.dart` (NEW)

#### Layout Structure:
```
┌─────────────────────────────────────────┐
│ Header Bar (Database Viewer)            │
├──────────┬──────────────────────────────┤
│ Tables   │ Table Data                   │
│ List     │                              │
│          │ ┌──────────────────────────┐ │
│ • users  │ │ id │ username │ email   │ │
│ • bookings│ ├────┼──────────┼────────┤ │
│ • lapangans│ │ 1  │ danang   │ ...   │ │
│ • reviews│ │ 2  │ admin    │ ...   │ │
│ • vouchers│ └──────────────────────────┘ │
│          │                              │
└──────────┴──────────────────────────────┘
```

#### Key Features:

**Left Sidebar - Table List**
- Shows all tables in database
- Excludes system tables (sqlite_*)
- Shows table count
- Clickable to load table data
- Highlights selected table

**Right Panel - Table Data**
- Shows table name and row count
- Displays data in DataTable format
- Scrollable horizontally and vertically
- Shows column names as headers
- Handles NULL values
- Empty state for empty tables

### 3. Database Operations

#### Load All Tables:
```dart
Future<void> _loadTables() async {
  final db = await DatabaseHelper.instance.database;
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
  );
  // Returns: users, bookings, lapangans, reviews, vouchers, etc.
}
```

#### Load Table Data:
```dart
Future<void> _loadTableData(String tableName) async {
  final db = await DatabaseHelper.instance.database;
  
  // Get columns
  final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
  
  // Get all data
  final data = await db.query(tableName);
}
```

## UI/UX Design

### Color Scheme
- Background: `#FAFAF5` (cream)
- Sidebar: White with border
- Selected table: Green highlight (`AppColors.primary`)
- Headers: Light grey (`#F4F1EC`)
- Borders: `#E8E8E4`

### Typography
- Font: Lexend
- Table names: 13px, w400/w600 (selected)
- Headers: 14-16px, w600-w700
- Data: 12px, w400

### Icons
- Menu icon: `Icons.storage_rounded`
- Table list icon: `Icons.table_chart_rounded`
- Table row icon: `Icons.table_rows_rounded`
- Empty state: `Icons.inbox_rounded`

### States

**Loading Tables:**
```
┌─────────────────────┐
│  CircularProgress   │
└─────────────────────┘
```

**No Table Selected:**
```
┌─────────────────────┐
│   📊 Storage Icon    │
│ Pilih tabel untuk   │
│   melihat data      │
└─────────────────────┘
```

**Empty Table:**
```
┌─────────────────────┐
│   📥 Inbox Icon      │
│   Tabel kosong      │
└─────────────────────┘
```

**Table with Data:**
```
┌──────────────────────────────┐
│ table_name        [10 rows]  │
├──────────────────────────────┤
│ id │ name    │ created_at   │
├────┼─────────┼──────────────┤
│ 1  │ John    │ 2024-01-01   │
│ 2  │ Jane    │ 2024-01-02   │
└──────────────────────────────┘
```

## Tables Available

Based on database schema, these tables will be visible:

1. **users** - User accounts
2. **bookings** - Booking records
3. **lapangans** - Field/venue data
4. **reviews** - User reviews
5. **vouchers** - Discount vouchers
6. **chat_messages** - Chat history
7. **lapangan_images** - Field images
8. **amenities** - Facility amenities
9. **lapangan_amenities** - Field-amenity relations

## Use Cases

### For Admin:
1. **Debug Data Issues**
   - Check if data is saved correctly
   - Verify relationships between tables
   - Find missing or incorrect data

2. **Monitor System**
   - See total users
   - Check booking history
   - View voucher usage
   - Monitor reviews

3. **Data Analysis**
   - Count records per table
   - View raw data
   - Export data (future feature)

### Example Workflows:

**Check User Data:**
1. Open Database menu
2. Click "users" table
3. See all user accounts with details

**Verify Bookings:**
1. Click "bookings" table
2. See all bookings with status
3. Check user_id and lapangan_id relations

**Review Vouchers:**
1. Click "vouchers" table
2. See earned vouchers
3. Check is_used status

## Technical Details

### Performance:
- Lazy loading: Only loads data when table is selected
- Efficient queries: Uses SQLite PRAGMA for table info
- Scrollable: Handles large datasets with scroll

### Error Handling:
- Try-catch for database operations
- Shows error SnackBar if query fails
- Graceful fallback for empty states

### Data Display:
- NULL values shown as "NULL" in grey
- All data types converted to string
- Horizontal scroll for wide tables
- Vertical scroll for many rows

## Navigation Flow

```
Admin Dashboard
    ↓
Open Drawer
    ↓
Click "Database"
    ↓
Database Viewer Screen
    ↓
Select Table (e.g., "users")
    ↓
View Table Data
```

## Files Modified/Created

### Modified:
1. `lib/widgets/admin_drawer.dart`
   - Added `database` to enum
   - Added Database menu item
   - Added navigation case

### Created:
2. `lib/screens/admin_database_screen.dart`
   - Complete database viewer implementation
   - Table list sidebar
   - Data table display
   - Loading states

## Future Enhancements (Optional)

- [ ] Search/filter data
- [ ] Export to CSV
- [ ] Edit data inline
- [ ] Delete records
- [ ] SQL query console
- [ ] Table relationships visualization
- [ ] Data statistics

## Status
✅ **IMPLEMENTATION COMPLETE** - Database viewer ready

Admin sekarang bisa melihat semua tabel dan data di database dengan UI yang clean dan mudah digunakan!
