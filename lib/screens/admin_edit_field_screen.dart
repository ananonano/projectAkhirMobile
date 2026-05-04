import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database.dart';
import '../models/lapangan_model.dart';
import '../theme/app_theme.dart';
import 'map_picker_screen.dart';

class AdminEditFieldScreen extends StatefulWidget {
  final LapanganModel lapangan;

  const AdminEditFieldScreen({super.key, required this.lapangan});

  @override
  State<AdminEditFieldScreen> createState() => _AdminEditFieldScreenState();
}

class _AdminEditFieldScreenState extends State<AdminEditFieldScreen> {
  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _addressController;
  late TextEditingController _descController;
  late TextEditingController _jamBukaController;
  late TextEditingController _jamTutupController;

  late String _jenisOlahraga;
  final List<String> _pilihanJenis = [
    'FUTSAL',
    'BASKETBALL',
    'BADMINTON',
    'MINI_SOCCER',
    'TENNIS',
  ];

  List<String> _selectedImagePaths = [];
  List<Map<String, dynamic>> _allAmenities = [];
  Set<int> _selectedAmenityIds = {};
  bool _isLoadingAmenities = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _namaController = TextEditingController(text: widget.lapangan.namaLapangan);
    _hargaController = TextEditingController(text: widget.lapangan.harga.toString());
    _latController = TextEditingController(text: widget.lapangan.lat.toString());
    _lngController = TextEditingController(text: widget.lapangan.lng.toString());
    _addressController = TextEditingController(text: widget.lapangan.address ?? '');
    _descController = TextEditingController(text: widget.lapangan.description ?? '');
    _jamBukaController = TextEditingController(text: widget.lapangan.jamBuka);
    _jamTutupController = TextEditingController(text: widget.lapangan.jamTutup);
    _jenisOlahraga = widget.lapangan.jenis;
    
    // Load existing images
    if (widget.lapangan.image != null && widget.lapangan.image!.isNotEmpty) {
      _selectedImagePaths = widget.lapangan.image!.split(',');
    }
    
    _loadAmenities();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _jamBukaController.dispose();
    _jamTutupController.dispose();
    super.dispose();
  }

  Future<void> _loadAmenities() async {
    try {
      final amenities = await DatabaseHelper.instance.getAllAmenities();
      final lapanganAmenities = await DatabaseHelper.instance.getAmenitiesForLapangan(widget.lapangan.id!);
      
      setState(() {
        _allAmenities = amenities;
        _selectedAmenityIds = lapanganAmenities.map((a) => a['amenity_id'] as int).toSet();
        _isLoadingAmenities = false;
      });
    } catch (e) {
      print('[EditField] Error loading amenities: $e');
      setState(() => _isLoadingAmenities = false);
    }
  }

  Future<void> _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImagePaths.addAll(images.map((img) => img.path).toList());
      });
    }
  }

  Future<void> _bukaPeta() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lngController.text = result.longitude.toString();
      });
    }
  }

  Future<void> _simpanLapangan() async {
    String nama = _namaController.text.trim();
    String hargaStr = _hargaController.text.trim();
    String latStr = _latController.text.trim();
    String lngStr = _lngController.text.trim();
    String address = _addressController.text.trim();
    String description = _descController.text.trim();
    String jamBuka = _jamBukaController.text.trim();
    String jamTutup = _jamTutupController.text.trim();

    if (nama.isEmpty ||
        hargaStr.isEmpty ||
        latStr.isEmpty ||
        lngStr.isEmpty ||
        address.isEmpty ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int harga = int.tryParse(hargaStr) ?? 0;
    double lat = double.tryParse(latStr) ?? 0.0;
    double lng = double.tryParse(lngStr) ?? 0.0;

    try {
      // Update lapangan with all fields
      Database db = await DatabaseHelper.instance.database;
      await db.update(
        'lapangans',
        {
          'nama_lapangan': nama,
          'jenis': _jenisOlahraga,
          'harga': harga,
          'lat': lat,
          'lng': lng,
          'description': description,
          'address': address,
          'image': _selectedImagePaths.join(','),
          'jam_buka': jamBuka,
          'jam_tutup': jamTutup,
        },
        where: 'id = ?',
        whereArgs: [widget.lapangan.id],
      );

      // Save amenities
      if (_selectedAmenityIds.isNotEmpty) {
        await DatabaseHelper.instance.saveAmenitiesForLapangan(
          widget.lapangan.id!,
          _selectedAmenityIds.toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lapangan berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        title: const Text(
          'Edit Lapangan',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto Lapangan
            _buildSectionTitle('Foto Lapangan'),
            const SizedBox(height: 12),
            if (_selectedImagePaths.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImagePaths.length,
                  itemBuilder: (context, index) {
                    final imagePath = _selectedImagePaths[index];
                    final isUrl = imagePath.startsWith('http');
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isUrl
                                ? Image.network(
                                    imagePath,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(imagePath),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImagePaths.removeAt(index)),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickMultipleImages,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF78716C)),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Foto dari Galeri',
                      style: TextStyle(
                        color: Color(0xFF78716C),
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nama Lapangan
            _buildSectionTitle('Nama Lapangan'),
            const SizedBox(height: 8),
            _buildTextField(_namaController, 'Contoh: Lapangan Futsal A'),
            const SizedBox(height: 16),

            // Jenis Olahraga
            _buildSectionTitle('Jenis Olahraga'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE8E8E4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _jenisOlahraga,
                isExpanded: true,
                underline: const SizedBox(),
                items: _pilihanJenis.map((jenis) {
                  return DropdownMenuItem(
                    value: jenis,
                    child: Text(
                      jenis.replaceAll('_', ' '),
                      style: const TextStyle(fontFamily: 'Lexend'),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _jenisOlahraga = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Harga
            _buildSectionTitle('Harga per Jam (Rp)'),
            const SizedBox(height: 8),
            _buildTextField(
              _hargaController,
              'Contoh: 150000',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Jam Operasional
            _buildSectionTitle('Jam Operasional'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_jamBukaController, 'Jam Buka'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_jamTutupController, 'Jam Tutup'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alamat
            _buildSectionTitle('Alamat Lengkap'),
            const SizedBox(height: 8),
            _buildTextField(
              _addressController,
              'Contoh: Jl. Babarsari No.2, Yogyakarta',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Koordinat Lokasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Koordinat Lokasi'),
                TextButton.icon(
                  onPressed: _bukaPeta,
                  icon: const Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                  label: const Text(
                    'Pilih dari Peta',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _latController,
                    'Latitude',
                    readOnly: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _lngController,
                    'Longitude',
                    readOnly: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deskripsi
            _buildSectionTitle('Deskripsi'),
            const SizedBox(height: 8),
            _buildTextField(
              _descController,
              'Deskripsi lapangan...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Fasilitas
            _buildSectionTitle('Fasilitas'),
            const SizedBox(height: 12),
            if (_isLoadingAmenities)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allAmenities.map((amenity) {
                  final amenityId = amenity['id'] as int;
                  final isSelected = _selectedAmenityIds.contains(amenityId);
                  return FilterChip(
                    label: Text(amenity['name'] as String),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenityIds.add(amenityId);
                        } else {
                          _selectedAmenityIds.remove(amenityId);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : const Color(0xFF78716C),
                      fontFamily: 'Lexend',
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _simpanLapangan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Lexend',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Lexend',
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1C1A),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB8B5AC),
          fontFamily: 'Lexend',
          fontSize: 14,
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF4F1EC) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8E8E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8E8E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Lexend',
        fontSize: 14,
      ),
    );
  }
}
