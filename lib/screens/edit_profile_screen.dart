import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../database/database.dart';
import '../theme/app_theme.dart';
import 'root.dart'; // Import untuk akses profileImageUpdateNotifier

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  String? _selectedImagePath;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedImagePath = widget.user.image;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      print('[EditProfile] Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username tidak boleh kosong')),
      );
      return;
    }

    if (_emailController.text.isNotEmpty &&
        !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check unique constraints
      if (_usernameController.text != widget.user.username) {
        final usernameExists = await _dbHelper.checkUsernameExistsExcept(
          _usernameController.text,
          widget.user.id!,
        );
        if (usernameExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Username sudah dipakai, gunakan username lain!')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (_emailController.text.isNotEmpty && _emailController.text != widget.user.email) {
        final emailExists = await _dbHelper.checkEmailExistsExcept(
          _emailController.text,
          widget.user.id!,
        );
        if (emailExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email sudah dipakai, gunakan email lain!')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (_phoneController.text.isNotEmpty && _phoneController.text != widget.user.phone) {
        final phoneExists = await _dbHelper.checkPhoneExistsExcept(
          _phoneController.text,
          widget.user.id!,
        );
        if (phoneExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No telepon sudah dipakai, gunakan no telepon lain!')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final updatedUser = UserModel(
        id: widget.user.id,
        username: _usernameController.text,
        password: widget.user.password,
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        image: _selectedImagePath,
        role: widget.user.role,
        createdAt: widget.user.createdAt,
      );

      // Update di database
      await _updateUserInDatabase(updatedUser);
      
      // Simpan foto ke SharedPreferences
      if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${updatedUser.username}', _selectedImagePath!);
        print('[EditProfile] Image saved to SharedPreferences: $_selectedImagePath');
      }

      // Update session username if changed
      if (_usernameController.text != widget.user.username) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _usernameController.text);
        print('[EditProfile] Session username updated to: ${_usernameController.text}');
      }

      // Trigger global notifier untuk update profile image di navbar
      profileImageUpdateNotifier.value++;
      print('[EditProfile] Profile image notifier triggered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );

        // Return updated user
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      print('[EditProfile] Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserInDatabase(UserModel user) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'users',
        {
          'username': user.username,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'image': user.image,
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );
      print('[EditProfile] User updated in database, ID: ${user.id}');
    } catch (e) {
      print('[EditProfile] Database error: $e');
      rethrow;
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImagePath == null || _selectedImagePath!.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primaryLight.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 60,
          color: Colors.white,
        ),
      );
    }

    if (_selectedImagePath!.startsWith('http')) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_selectedImagePath!),
        onBackgroundImageError: (_, __) {},
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(File(_selectedImagePath!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  _buildImagePreview(),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: const Text(
                'Ubah Foto',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Form Fields
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Masukkan username Anda',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              hint: 'Masukkan nama Anda',
              prefixIcon: Icons.person_rounded,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'contoh@email.com',
              prefixIcon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: 'Nomor Telepon',
              hint: '+62 812 3456 7890',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.inputFill,
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.primary,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
