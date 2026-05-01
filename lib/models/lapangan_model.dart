class LapanganModel {
  final int? id;
  final String namaLapangan;
  final String? description;
  final String? image;
  final String jenis;
  final int harga;
  final int capacity;
  final String? address;
  final double? lat;
  final double? lng;
  final String jamBuka;
  final String jamTutup;
  final String? createdAt;

  LapanganModel({
    this.id,
    required this.namaLapangan,
    this.description,
    this.image,
    required this.jenis,
    required this.harga,
    this.capacity = 1,
    this.address,
    this.lat,
    this.lng,
    this.jamBuka = "08:00",
    this.jamTutup = "22:00",
    this.createdAt,
  });

  // Dari Map (hasil query SQLite) ke Object
  factory LapanganModel.fromMap(Map<String, dynamic> map) {
    return LapanganModel(
      id: map['id'] as int?,
      namaLapangan: map['nama_lapangan'] ?? '',
      description: map['description'],
      image: map['image'],
      jenis: map['jenis'] ?? '',
      harga: map['harga'] ?? 0,
      capacity: map['capacity'] ?? 1,
      address: map['address'],
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      jamBuka: map['jam_buka'] ?? "08:00",
      jamTutup: map['jam_tutup'] ?? "22:00",
      createdAt: map['created_at'],
    );
  }

  // Dari Object ke Map (buat insert/update ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_lapangan': namaLapangan,
      if (description != null) 'description': description,
      if (image != null) 'image': image,
      'jenis': jenis,
      'harga': harga,
      'capacity': capacity,
      if (address != null) 'address': address,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'jam_buka': jamBuka,
      'jam_tutup': jamTutup,
    };
  }

  // Ambil gambar pertama dari string CSV (misal: "url1,url2,url3")
  String get firstImage {
    if (image == null || image!.isEmpty) return '';
    return image!.split(',').first.trim();
  }

  // Ambil semua gambar sebagai List
  List<String> get imageList {
    if (image == null || image!.isEmpty) return [];
    return image!.split(',').map((e) => e.trim()).toList();
  }

  // Label jenis yang rapi (MINI_SOCCER → MINI SOCCER)
  String get jenisLabel => jenis.replaceAll('_', ' ');
}
