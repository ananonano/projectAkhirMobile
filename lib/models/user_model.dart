class UserModel {
  final int? id;
  final String username;
  final String password;
  final String? name;
  final String? email;
  final String? phone;
  final String? image;
  final String role;
  final String? createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    this.name,
    this.email,
    this.phone,
    this.image,
    this.role = 'user',
    this.createdAt,
  });

  // Dari Map (hasil query SQLite) ke Object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      image: map['image'],
      role: map['role'] ?? 'user',
      createdAt: map['created_at'],
    );
  }

  // Dari Object ke Map (buat insert/update ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password': password,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (image != null) 'image': image,
      'role': role,
    };
  }

  bool get isAdmin => role == 'admin';
}
