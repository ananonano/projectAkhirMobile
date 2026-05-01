class Review {
  final int? id;
  final int userId;
  final int lapanganId;
  final int rating; // 1-5 stars
  final String? comment;
  final String? createdAt;
  final String? userName; // For display purposes, joined from users table
  final String? userImage; // For display purposes

  Review({
    this.id,
    required this.userId,
    required this.lapanganId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.userImage,
  });

  // Convert from database map
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      userId: map['user_id'],
      lapanganId: map['lapangan_id'],
      rating: map['rating'],
      comment: map['comment'],
      createdAt: map['created_at'],
      userName: map['user_name'],
      userImage: map['user_image'],
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'lapangan_id': lapanganId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
    };
  }

  // Convert to UI map
  Map<String, dynamic> toUIMap() {
    return {
      'id': id,
      'user_id': userId,
      'lapangan_id': lapanganId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
      'user_name': userName,
      'user_image': userImage,
    };
  }

  // Get average rating text
  String getRatingText() {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }
}
