import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectakhir/database/database.dart';
import 'package:projectakhir/models/lapangan_model.dart';
import 'package:projectakhir/theme/app_theme.dart';
import 'admin_create_field_screen.dart';
import '../widgets/admin_drawer.dart';

class AdminFieldManagementScreen extends StatefulWidget {
  final AdminMenuIndex activeMenu;
  
  const AdminFieldManagementScreen({
    super.key,
    this.activeMenu = AdminMenuIndex.venueManager,
  });

  @override
  State<AdminFieldManagementScreen> createState() =>
      _AdminFieldManagementScreenState();
}

class _AdminFieldManagementScreenState extends State<AdminFieldManagementScreen> {
  late Future<List<LapanganModel>> _lapanganFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadLapangan();
  }

  void _loadLapangan() {
    setState(() {
      _lapanganFuture = DatabaseHelper.instance.getAllLapangan();
    });
  }

  Future<void> _deleteLapangan(int id, String nama) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lapangan?'),
        content: Text('Hapus "$nama" dari sistem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteLapangan(id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadLapangan();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lapangan berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _editLapangan(LapanganModel lapangan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAFAF5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditFieldBottomSheet(
        lapangan: lapangan,
        onSave: _loadLapangan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAF5),
      drawer: AdminDrawer(
        activeMenu: widget.activeMenu,
        scaffoldKey: _scaffoldKey,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCreateFieldScreen(),
            ),
          );
          if (result == true) {
            _loadLapangan();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Lapangan',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Konten utama dengan padding atas untuk header
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: RefreshIndicator(
              onRefresh: () async {
                _loadLapangan();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primary,
              child: FutureBuilder<List<LapanganModel>>(
          future: _lapanganFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final lapangan = snapshot.data ?? [];

            if (lapangan.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.domain_disabled_rounded,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada lapangan',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCreateFieldScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadLapangan();
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah Lapangan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 45, 20, 24),
              itemCount: lapangan.length,
              itemBuilder: (context, index) {
                final field = lapangan[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == lapangan.length - 1 ? 16 : 16,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFC2C8BF),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadows: [
                        BoxShadow(
                          color: const Color(0x0C000000),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 12,
                            children: [
                              // Header with badges
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 4,
                                      children: [
                                        Text(
                                          field.namaLapangan,
                                          style: const TextStyle(
                                            color: Color(0xFF1A1C1A),
                                            fontSize: 16,
                                            fontFamily: 'Lexend',
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            field.jenis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'Lexend',
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFC5ECC9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(9999),
                                      ),
                                    ),
                                    child: Text(
                                      'Rp ${NumberFormat("#,###").format(field.harga)}/jam',
                                      style: const TextStyle(
                                        color: Color(0xFF416448),
                                        fontSize: 11,
                                        fontFamily: 'Lexend',
                                        fontWeight: FontWeight.w600,
                                        height: 1.40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Divider
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: const Color(0xFFE8E8E4),
                              ),
                              // Details
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 8,
                                children: [
                                  Row(
                                    spacing: 8,
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      Expanded(
                                        child: Text(
                                          field.address ?? 'Alamat tidak tersedia',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF78716C),
                                            fontFamily: 'Lexend',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    spacing: 8,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      Text(
                                        '${field.jamBuka} - ${field.jamTutup}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF78716C),
                                          fontFamily: 'Lexend',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (field.description != null &&
                                      field.description!.isNotEmpty)
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        Expanded(
                                          child: Text(
                                            field.description!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF78716C),
                                              fontFamily: 'Lexend',
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 24,
                          ),
                          child: Row(
                            spacing: 12,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _editLapangan(field),
                                  child: Container(
                                    height: 40,
                                    decoration: ShapeDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                          width: 1,
                                          color: AppColors.primary,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Icon(
                                            Icons.edit_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 13,
                                              fontFamily: 'Lexend',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _deleteLapangan(field.id!, field.namaLapangan),
                                  child: Container(
                                    height: 40,
                                    decoration: ShapeDecoration(
                                      color:
                                          const Color(0xFFD84040).withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                          width: 1,
                                          color: Color(0xFFD84040),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Icon(
                                            Icons.delete_rounded,
                                            size: 14,
                                            color: Color(0xFFD84040),
                                          ),
                                          Text(
                                            'Hapus',
                                            style: TextStyle(
                                              color: Color(0xFFD84040),
                                              fontSize: 13,
                                              fontFamily: 'Lexend',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
        ),

          // Fixed Header Bar dengan hamburger menu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBar(
              title: 'Manajemen Lapangan',
              scaffoldKey: _scaffoldKey,
            ),
          ),
        ],
      ),
    );
  }
}

class EditFieldBottomSheet extends StatefulWidget {
  final LapanganModel lapangan;
  final VoidCallback onSave;

  const EditFieldBottomSheet({
    super.key,
    required this.lapangan,
    required this.onSave,
  });

  @override
  State<EditFieldBottomSheet> createState() => _EditFieldBottomSheetState();
}

class _EditFieldBottomSheetState extends State<EditFieldBottomSheet> {
  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _addressController;
  late TextEditingController _descController;
  late TextEditingController _jamBukaController;
  late TextEditingController _jamTutupController;
  late String _selectedJenis;
  
  List<Map<String, dynamic>> _allAmenities = [];
  Set<int> _selectedAmenityIds = {};
  bool _isLoadingAmenities = true;

  final List<String> _jenisOlahraga = [
    'FUTSAL',
    'BASKETBALL',
    'BADMINTON',
    'MINI_SOCCER',
    'TENNIS',
  ];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.lapangan.namaLapangan);
    _hargaController =
        TextEditingController(text: widget.lapangan.harga.toString());
    _addressController =
        TextEditingController(text: widget.lapangan.address ?? '');
    _descController =
        TextEditingController(text: widget.lapangan.description ?? '');
    _jamBukaController =
        TextEditingController(text: widget.lapangan.jamBuka);
    _jamTutupController =
        TextEditingController(text: widget.lapangan.jamTutup);
    _selectedJenis = widget.lapangan.jenis;
    _loadAmenities();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _jamBukaController.dispose();
    _jamTutupController.dispose();
    super.dispose();
  }

  Future<void> _loadAmenities() async {
    try {
      final allAmenities = await DatabaseHelper.instance.getAllAmenities();
      final lapanganAmenities = await DatabaseHelper.instance
          .getAmenitiesForLapangan(widget.lapangan.id!);

      setState(() {
        _allAmenities = allAmenities;
        _selectedAmenityIds = lapanganAmenities
            .map((a) => a['amenity_id'] as int)
            .toSet();
        _isLoadingAmenities = false;
      });
    } catch (e) {
      print('[EditField] Error loading amenities: $e');
      setState(() => _isLoadingAmenities = false);
    }
  }

  Future<void> _updateLapangan() async {
    try {
      final updated = LapanganModel(
        id: widget.lapangan.id,
        namaLapangan: _namaController.text.trim(),
        jenis: _selectedJenis,
        harga: int.tryParse(_hargaController.text) ?? 0,
        address: _addressController.text.trim(),
        description: _descController.text.trim(),
        jamBuka: _jamBukaController.text.trim(),
        jamTutup: _jamTutupController.text.trim(),
        capacity: widget.lapangan.capacity,
        lat: widget.lapangan.lat,
        lng: widget.lapangan.lng,
        image: widget.lapangan.image,
        createdAt: widget.lapangan.createdAt,
      );

      await DatabaseHelper.instance.updateLapangan(updated);
      
      // Save amenities
      await DatabaseHelper.instance.saveAmenitiesForLapangan(
        widget.lapangan.id!,
        _selectedAmenityIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lapangan berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Lapangan',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Nama
            _buildTextField('Nama Lapangan', _namaController),
            const SizedBox(height: 16),
            // Jenis
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text(
                  'Jenis Olahraga',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8E8E4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedJenis,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _jenisOlahraga.map((jenis) {
                      return DropdownMenuItem(
                        value: jenis,
                        child: Text(jenis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedJenis = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Harga
            _buildTextField('Harga per Jam (Rp)', _hargaController,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            // Jam Buka
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: _buildTextField('Jam Buka', _jamBukaController),
                ),
                Expanded(
                  child: _buildTextField('Jam Tutup', _jamTutupController),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Alamat
            _buildTextField('Alamat', _addressController),
            const SizedBox(height: 16),
            // Deskripsi
            _buildTextField(
              'Deskripsi',
              _descController,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Fasilitas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text(
                  'Fasilitas',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                if (_isLoadingAmenities)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
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
              ],
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE8E8E4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1C1A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _updateLapangan,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1A),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8E8E4)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
