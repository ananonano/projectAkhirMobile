import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/lapangan_image_repository.dart';

class EditLapanganImagesScreen extends StatefulWidget {
  final int lapanganId;
  final String lapanganName;

  const EditLapanganImagesScreen({
    Key? key,
    required this.lapanganId,
    required this.lapanganName,
  }) : super(key: key);

  @override
  State<EditLapanganImagesScreen> createState() => _EditLapanganImagesScreenState();
}

class _EditLapanganImagesScreenState extends State<EditLapanganImagesScreen> {
  final LapanganImageRepository _imageRepo = LapanganImageRepository();
  final ImagePicker _picker = ImagePicker();
  late List<LapanganImage> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    final images = await _imageRepo.getImagesByLapangan(widget.lapanganId);
    setState(() {
      _images = images;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final newImage = LapanganImage(
        lapanganId: widget.lapanganId,
        imagePath: image.path,
        position: _images.length,
      );
      await _imageRepo.addImage(newImage);
      _loadImages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil ditambahkan!')),
        );
      }
    }
  }

  Future<void> _deleteImage(LapanganImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto?'),
        content: const Text('Yakin mau hapus foto ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && image.id != null) {
      await _imageRepo.deleteImage(image.id!);
      _loadImages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil dihapus!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Kelola Foto - ${widget.lapanganName}'),
        backgroundColor: const Color(0xFFF64E42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Photo Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: const Text('Tambah Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF64E42),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Images List
                  if (_images.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada foto untuk lapangan ini',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: List.generate(_images.length, (index) {
                        final image = _images[index];
                        final imageFile = File(image.imagePath);
                        final exists = imageFile.existsSync();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  color: Colors.grey[200],
                                ),
                                child: exists
                                    ? Image.file(
                                        imageFile,
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported,
                                                size: 50, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('File tidak ditemukan',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                              ),
                              // Info and Actions
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Foto #${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          image.imagePath.split('/').last,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => _deleteImage(image),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
    );
  }
}
