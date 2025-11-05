// In a file named: lib/screens/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Helper for displaying toast notifications
  void _showToast(BuildContext context, String title, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(title),
      icon: Icon(type == ToastificationType.success
          ? Icons.check_circle
          : Icons.error),
      alignment: Alignment.topCenter,
      style: ToastificationStyle.fillColored,
      type: type,
      autoCloseDuration: const Duration(milliseconds: 3000),
    );
  }

  // --- Core Logic: Change Password (FIXED) ---
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (user == null) {
      _showToast(context, 'User not logged in.', ToastificationType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create credential using the old password (Reauthentication)
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      // 2. Reauthenticate the user (This verifies the old password)
      await user.reauthenticateWithCredential(credential);

      // 3. Update the password
      await user.updatePassword(newPassword);

      _showToast(context, 'Password changed successfully!',
          ToastificationType.success);

      // Clear fields and go back
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (context.mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Password change failed.';
      if (e.code == 'wrong-password') {
        message = 'Invalid old password.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log in again before changing the password.';
      } else if (e.code == 'operation-not-allowed') {
        // Handle users who signed in with providers like Google/Facebook
        message =
            'Change password is only allowed for Email/Password accounts.';
      } else {
        message = 'Error: ${e.message}';
      }
      _showToast(context, message, ToastificationType.error);
    } catch (e) {
      _showToast(
          context, 'An unexpected error occurred.', ToastificationType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFEF6A6A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildPasswordField(
                    label: 'Old Password',
                    controller: _oldPasswordController,
                    hint: 'Enter old password',
                    obscureText: _obscureOld,
                    onToggle: () => setState(() => _obscureOld = !_obscureOld),
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter old password' : null),
                const SizedBox(height: 20),
                _buildPasswordField(
                    label: 'New Password',
                    controller: _newPasswordController,
                    hint: 'Enter new password',
                    obscureText: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter new password";
                      if (value.length < 6) return "Minimum 6 characters";
                      if (value == _oldPasswordController.text)
                        return "New password cannot be the same as old password";
                      return null;
                    }),
                const SizedBox(height: 20),
                _buildPasswordField(
                    label: 'Confirm New Password',
                    controller: _confirmPasswordController,
                    hint: 'Confirm new password',
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (value) {
                      if (value!.isEmpty) return "Please confirm new password";
                      if (value != _newPasswordController.text)
                        return "Passwords do not match";
                      return null;
                    }),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Change', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for password fields
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
