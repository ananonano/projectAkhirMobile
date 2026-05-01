class BookingModel {
  final int? id;
  final int userId;
  final int? lapanganId;
  final String namaLapangan;
  final String tanggal;
  final String jam;
  final String totalHarga;
  final String? createdAt;

  BookingModel({
    this.id,
    required this.userId,
    this.lapanganId,
    required this.namaLapangan,
    required this.tanggal,
    required this.jam,
    required this.totalHarga,
    this.createdAt,
  });

  // Dari Map (hasil query SQLite) ke Object
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as int?,
      userId: map['user_id'] ?? 0,
      lapanganId: map['lapangan_id'] as int?,
      namaLapangan: map['nama_lapangan'] ?? '',
      tanggal: map['tanggal'] ?? '',
      jam: map['jam'] ?? '',
      totalHarga: map['total_harga']?.toString() ?? '0',
      createdAt: map['created_at'],
    );
  }

  // Dari Object ke Map (buat insert ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (lapanganId != null) 'lapangan_id': lapanganId,
      'nama_lapangan': namaLapangan,
      'tanggal': tanggal,
      'jam': jam,
      'total_harga': totalHarga,
    };
  }

  // Ambil list jam dari string CSV (misal: "08:00, 09:00, 10:00")
  List<String> get jamList {
    return jam.split(',').map((e) => e.trim()).toList();
  }

  // Total harga sebagai integer
  int get totalHargaInt => int.tryParse(totalHarga) ?? 0;
}
