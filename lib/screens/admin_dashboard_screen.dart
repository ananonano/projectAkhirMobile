import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/lapangan_controller.dart';
import '../models/lapangan_model.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

// ==========================================
// 1. HALAMAN UTAMA DASHBOARD ADMIN
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final LapanganController _controller = LapanganController();
  List<LapanganModel> _lapangans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLapangans();
  }

  Future<void> _fetchLapangans() async {
    setState(() => _isLoading = true);
    final data = await _controller.getAllLapangans();
    setState(() {
      _lapangans = data;
      _isLoading = false;
    });
  }

  void _logoutAdmin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');
    await prefs.remove('role');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Widget _buildThumbnail(LapanganModel lapangan) {
    final img = lapangan.firstImage;
    if (img.isEmpty) {
      return Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.image_not_supported, color: Colors.grey));
    }
    if (img.startsWith('assets/')) {
      return Image.asset(img, width: 60, height: 60, fit: BoxFit.cover);
    } else if (img.startsWith('http')) {
      return Image.network(img, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[300]));
    } else {
      return Image.file(File(img), width: 60, height: 60, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logoutAdmin),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _lapangans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.sports_soccer_rounded, size: 36, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      const Text('Belum ada lapangan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lapangans.length,
                  itemBuilder: (context, index) {
                    final lap = _lapangans[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildThumbnail(lap),
                        ),
                        title: Text(lap.namaLapangan, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
                                child: Text(lap.jenisLabel, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              Text('Rp ${lap.harga}/jam', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () async {
                            if (lap.id != null) {
                              await _controller.deleteLapangan(lap.id!);
                              _fetchLapangans();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormLapanganScreen()));
          _fetchLapangans();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tambah Lapangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ==========================================
// 2. HALAMAN FORM TAMBAH LAPANGAN (CRUD & MULTI-IMAGE)
// ==========================================
class FormLapanganScreen extends StatefulWidget {
  const FormLapanganScreen({super.key});

  @override
  State<FormLapanganScreen> createState() => _FormLapanganScreenState();
}

class _FormLapanganScreenState extends State<FormLapanganScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final LapanganController _controller = LapanganController();
  
  String _selectedJenis = 'FUTSAL';
  final List<String> _jenisOptions = ['FUTSAL', 'BASKETBALL', 'BADMINTON', 'MINI_SOCCER', 'TENNIS'];
  final List<String> _selectedImagePaths = [];

  Future<void> _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImagePaths.addAll(images.map((img) => img.path).toList());
      });
    }
  }

  Future<void> _simpanLapangan() async {
    if (_namaController.text.isEmpty || _hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga wajib diisi bre!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final lapangan = LapanganModel(
      namaLapangan: _namaController.text,
      description: _descController.text,
      image: _selectedImagePaths.join(','),
      jenis: _selectedJenis,
      harga: int.tryParse(_hargaController.text) ?? 0,
      capacity: 10,
      address: _alamatController.text,
      lat: double.tryParse(_latController.text) ?? 0.0,
      lng: double.tryParse(_lngController.text) ?? 0.0,
    );

    await _controller.addLapangan(lapangan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mantap! Lapangan berhasil ditambahkan.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  // --- CUSTOM WIDGET POSITIONAL PARAMETERS ---
  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, int maxLines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Lapangan'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Foto Lapangan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            if (_selectedImagePaths.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImagePaths.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_selectedImagePaths[index]), width: 120, height: 120, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0, top: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImagePaths.removeAt(index)),
                              child: Container(
                                width: 24, height: 24,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickMultipleImages,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Pilih Foto dari Galeri', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_namaController, 'Nama Lapangan', TextInputType.text, 1),
            _buildTextField(_descController, 'Deskripsi', TextInputType.multiline, 3),
            DropdownButtonFormField<String>(
              value: _selectedJenis,
              decoration: const InputDecoration(labelText: 'Jenis Olahraga'),
              items: _jenisOptions.map((val) =>
                DropdownMenuItem(value: val, child: Text(val.replaceAll('_', ' ')))
              ).toList(),
              onChanged: (newVal) => setState(() => _selectedJenis = newVal!),
            ),
            const SizedBox(height: 16),
            _buildTextField(_hargaController, 'Harga per Jam (Rp)', TextInputType.number, 1),
            _buildTextField(_alamatController, 'Alamat Lengkap', TextInputType.text, 2),
            Row(
              children: [
                Expanded(child: _buildTextField(_latController, 'Latitude', TextInputType.number, 1)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_lngController, 'Longitude', TextInputType.number, 1)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _simpanLapangan,
                child: const Text('Simpan Lapangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}