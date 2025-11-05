// In a file named: lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';

import 'dart:typed_data';
import '../services/firebase_auth_service.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;

  Uint8List? _imageBytes; // Holds raw image data for display/upload

  // REMOVED: File? _imageFile; // Removed unnecessary and problematic variable

  late String _currentImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.userProfile.username);
    _mobileController = TextEditingController(text: widget.userProfile.mobile);
    _dobController = TextEditingController(text: widget.userProfile.dob);
    _currentImageUrl = widget.userProfile.imageUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // --- Image Picker Logic ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  // --- Date Picker Logic (Unchanged) ---
  Future<void> _selectDate() async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('dd-MM-yyyy').parse(_dobController.text);
    } catch (e) {
      initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  // --- Save Logic (FIXED UPLOAD CONDITION) ---
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String newImageUrl = _currentImageUrl;

      // FIX: Check _imageBytes instead of _imageFile! This guarantees upload works on Web.
      if (_imageBytes != null) {
        newImageUrl = await FirebaseAuthService.uploadProfileImageBytes(
            _imageBytes!, user.uid);
        setState(() {
          _currentImageUrl = newImageUrl;
          _imageBytes = null; // Clear bytes after successful upload
        });
      }

      // 2. Update text fields in Firestore
      await FirebaseAuthService.updateUserDetails(
        uid: user.uid,
        username: _usernameController.text.trim(),
        mobile: _mobileController.text.trim(),
        dob: _dobController.text.trim(),
      );

      if (context.mounted) {
        toastification.show(
            title: const Text('Profile Updated Successfully!'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 2));
        Navigator.pop(context);
      }
    } catch (e) {
      toastification.show(
          title: Text('Update Failed: ${e.toString()}'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // --- Build Widgets ---

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFEF6A6A);
    // FIX: Standardize asset check if needed, using simple path for clarity.
    final isDefaultImage = _currentImageUrl == 'assets/default_profile.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Profile Image ---
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageBytes != null
                      ? MemoryImage(_imageBytes!) // Display new image bytes
                      : isDefaultImage
                          ? const AssetImage('assets/default_profile.png')
                              as ImageProvider
                          : NetworkImage(_currentImageUrl)
                              as ImageProvider, // Display network image
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Upload Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Form Fields ---
              _buildTextField(
                  label: 'Username',
                  controller: _usernameController,
                  hint: 'Enter your username',
                  validator: (v) => v!.isEmpty ? 'Username is required' : null),
              const SizedBox(height: 16),

              _buildReadOnlyTextField(
                label: 'Email',
                text: widget.userProfile.email,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                  label: 'Date of Birth',
                  controller: _dobController,
                  hint: 'Select your DOB',
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (v) => v!.isEmpty ? 'DOB is required' : null),
              const SizedBox(height: 16),

              _buildTextField(
                  label: 'Mobile Number',
                  controller: _mobileController,
                  hint: 'Enter your mobile no',
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.length != 10 ? 'Enter valid 10-digit number' : null),
              const SizedBox(height: 40),

              // --- Save Button ---
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Edit', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for mutable text fields
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Helper widget for read-only fields (Email)
  Widget _buildReadOnlyTextField({
    required String label,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: text),
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
