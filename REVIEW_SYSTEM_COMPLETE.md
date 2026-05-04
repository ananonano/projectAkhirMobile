# Review System Enhancement - Complete ✅

## Requirements
1. ✅ 1 akun hanya bisa review 1x per lapangan
2. ✅ User bisa delete review sendiri
3. ✅ User bisa edit review sendiri
4. ✅ Kalau sudah pernah review, tombol "Rating" jadi "Edit"

## Implementation

### 1. Check User Review Status
**File**: `lib/screens/detail_lapangan_screen.dart`

Added state variable:
```dart
int? _currentUserId; // Store current user ID for checking ownership
```

Updated `_loadReviews()` to:
- Get current user ID from SharedPreferences
- Check if user has already reviewed using `getUserReview()`
- Store user's review in `_userReview` state
- Store current user ID in `_currentUserId` for ownership checking

### 2. Dynamic Button Label
**File**: `lib/screens/detail_lapangan_screen.dart` (lines ~590-615)

Button changes based on review status:
- **No review yet**: Shows "+ Rating" icon with "Rating" text
- **Already reviewed**: Shows "✏️ Edit" icon with "Edit" text

```dart
Icon(
  _userReview == null ? Icons.add_rounded : Icons.edit_rounded,
  color: const Color(0xFF597D60),
  size: 18,
),
Text(
  _userReview == null ? 'Rating' : 'Edit',
  style: const TextStyle(
    color: Color(0xFF597D60),
    fontWeight: FontWeight.bold,
    fontSize: 12,
  ),
),
```

### 3. Edit Review Dialog
**File**: `lib/screens/detail_lapangan_screen.dart` (lines ~268-350)

Dialog now supports both add and edit modes:
- **Title**: "Beri Rating & Ulasan" (new) vs "Edit Rating & Ulasan" (edit)
- **Pre-filled data**: If editing, loads existing rating and comment
- **Buttons**:
  - "Batal" - Cancel
  - "Hapus" - Delete (only shown when editing)
  - "Kirim" (new) / "Update" (edit) - Submit

### 4. Delete Review Functionality
**File**: `lib/screens/detail_lapangan_screen.dart` (lines ~430-470)

Added `_deleteReview()` method:
- Shows confirmation dialog
- Calls `_reviewRepository.deleteReview()`
- Reloads reviews after deletion
- Triggers home screen refresh

### 5. Review Item with Menu
**File**: `lib/screens/detail_lapangan_screen.dart` (lines ~455-550)

Updated `_buildReviewItem()`:
- Check if review belongs to current user (`isOwnReview`)
- Show 3-dot menu (⋮) for own reviews only
- Menu options:
  - **Edit**: Opens edit dialog
  - **Hapus**: Deletes review with confirmation

### 6. Submit Review Logic
**File**: `lib/screens/detail_lapangan_screen.dart` (lines ~353-428)

`_submitReview()` handles both add and update:
- If `_userReview == null` → Add new review
- If `_userReview != null` → Update existing review
- Shows appropriate success message
- Reloads reviews and triggers home screen refresh

## User Flow

### First Time Review:
1. User clicks "+ Rating" button
2. Dialog opens: "Beri Rating & Ulasan"
3. User selects rating (1-5 stars) and writes comment
4. User clicks "Kirim"
5. Review added to database
6. Button changes to "✏️ Edit"

### Edit Existing Review:
1. User clicks "✏️ Edit" button (or 3-dot menu on their review)
2. Dialog opens: "Edit Rating & Ulasan" with pre-filled data
3. User modifies rating/comment
4. User clicks "Update"
5. Review updated in database

### Delete Review:
1. User clicks 3-dot menu (⋮) on their review
2. User selects "Hapus"
3. Confirmation dialog appears
4. User confirms deletion
5. Review deleted from database
6. Button changes back to "+ Rating"

## Database Methods Used

From `ReviewRepository`:
- `getUserReview(userId, lapanganId)` - Check if user already reviewed
- `addReview(review)` - Add new review
- `updateReview(review)` - Update existing review
- `deleteReview(reviewId)` - Delete review
- `getReviewsByLapangan(lapanganId)` - Get all reviews for display
- `getAverageRating(lapanganId)` - Calculate average rating
- `getReviewCount(lapanganId)` - Count total reviews

## UI Changes

### Button States:
| State | Icon | Text | Color |
|-------|------|------|-------|
| No review | + | Rating | Green |
| Has review | ✏️ | Edit | Green |

### Review Item:
- **Own review**: Shows 3-dot menu (⋮) in top-right
- **Other's review**: No menu, read-only

### Menu Options (Own Review):
- ✏️ Edit - Opens edit dialog
- 🗑️ Hapus - Deletes with confirmation (red text)

## Changes Summary
- ✅ One review per user per lapangan enforced
- ✅ Edit functionality with pre-filled data
- ✅ Delete functionality with confirmation
- ✅ Dynamic button label (Rating vs Edit)
- ✅ 3-dot menu on own reviews
- ✅ Proper ownership checking
- ✅ Home screen refresh after review changes
- ✅ No compilation errors

## Files Modified
1. `lib/screens/detail_lapangan_screen.dart`
   - Added `_currentUserId` state variable
   - Updated `_loadReviews()` to check user review status
   - Updated `_showRatingDialog()` for edit mode
   - Added `_deleteReview()` method
   - Updated `_buildReviewItem()` with menu for own reviews
   - Updated button to show "Rating" or "Edit"

2. `lib/repositories/review_repository.dart` (already had needed methods)
   - `getUserReview()` - Check existing review
   - `updateReview()` - Update review
   - `deleteReview()` - Delete review

## Testing Checklist
- [ ] User can add review (first time)
- [ ] Button changes to "Edit" after adding review
- [ ] User cannot add second review (button shows "Edit")
- [ ] Clicking "Edit" opens dialog with existing data
- [ ] User can update rating and comment
- [ ] User can delete own review via dialog button
- [ ] User can delete own review via 3-dot menu
- [ ] Confirmation dialog appears before deletion
- [ ] Button changes back to "Rating" after deletion
- [ ] 3-dot menu only appears on own reviews
- [ ] Other users' reviews are read-only
- [ ] Home screen refreshes after review changes
