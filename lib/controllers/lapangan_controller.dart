import '../models/lapangan_model.dart';
import '../repositories/lapangan_repository.dart';

/// Mengelola logika bisnis seputar data lapangan
class LapanganController {
  final LapanganRepository _repo = LapanganRepository();

  // Ambil lapangan dengan filter opsional (untuk HomeScreen)
  Future<List<LapanganModel>> searchLapangans({
    String? jenis,
    String? location,
  }) async {
    return _repo.getLapangans(jenis: jenis, location: location);
  }

  // Ambil semua lapangan (untuk AdminDashboard)
  Future<List<LapanganModel>> getAllLapangans() async {
    return _repo.getAllLapangans();
  }

  // Tambah lapangan baru (Admin)
  Future<int> addLapangan(LapanganModel lapangan) async {
    return _repo.insertLapangan(lapangan);
  }

  // Hapus lapangan (Admin)
  Future<void> deleteLapangan(int id) async {
    await _repo.deleteLapangan(id);
  }

  // Update lapangan (Admin)
  Future<int> updateLapangan(LapanganModel lapangan) async {
    return _repo.updateLapangan(lapangan);
  }
}
