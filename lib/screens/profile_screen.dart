// In a file named: lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicine_reminder_system/screens/change_password_screen.dart';
import 'package:medicine_reminder_system/screens/edit_profile_screen.dart';
import 'package:medicine_reminder_system/screens/login_screen.dart';
import '../services/firebase_auth_service.dart';
import '../models/user_model.dart'; // NEW

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  final Color accentColor = const Color(0xFFEF6A6A);

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await FirebaseAuthService.fetchUserDetails(user.uid);
      if (mounted && data != null) {
        setState(() {
          _userProfile = UserProfile.fromFirestore(data, user.uid);
        });
      }
    }
  }

  // Calculate Age (Basic implementation)
  String _calculateAge(String dob) {
    try {
      final parts = dob.split('-'); // Assumes format 'dd-MM-yyyy'
      if (parts.length != 3) return 'N/A';
      final dobDate = DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final today = DateTime.now();
      int age = today.year - dobDate.year;
      if (today.month < dobDate.month ||
          (today.month == dobDate.month && today.day < dobDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  // --- Logout Functionality ---
  void _logout(BuildContext context) async {
    // 1. Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // 2. Navigate
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final String age = _calculateAge(_userProfile!.dob);
    final bool isDefaultImage =
        _userProfile!.imageUrl == 'assets/images/default_profile.png';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Profile",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // --- Profile Picture and Name Section ---
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: isDefaultImage
                          ? const AssetImage(
                                  'assets/images/default_profile.png')
                              as ImageProvider
                          : NetworkImage(_userProfile!
                              .imageUrl), // Use NetworkImage for Firebase URL
                    ),
                    const SizedBox(height: 12),
                    Text(_userProfile!.username, // Dynamic Username
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$age Years', // Dynamic Age
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Mobile Number Section ---
              const Text('Mobile Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    side: BorderSide(color: Color(0xFFF0F0F0))),
                child: ListTile(
                  leading: Icon(Icons.phone, color: accentColor),
                  title: Text(_userProfile!.mobile), // Dynamic Mobile
                ),
              ),
              const SizedBox(height: 30),

              // --- Settings Section ---
              const Text('Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    side: BorderSide(color: Color(0xFFF0F0F0))),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.edit,
                      title: 'Edit Profile',
                      onTap: () async {
                        // Navigate to EditProfileScreen and await refresh
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                    userProfile: _userProfile!)));
                        _fetchUserProfile(); // Refresh data after editing
                      },
                      color: accentColor,
                    ),
                    _buildSettingsTile(
                      icon: Icons.password,
                      title: 'Change Password',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen()));
                      },
                      color: accentColor,
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () {
                        // Show dialog before calling logout
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Logout'),
                            content:
                                const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => _logout(context),
                                child: const Text('Logout',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      color: accentColor,
                      hideDivider: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for settings items (unchanged)
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
    bool hideDivider = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        if (!hideDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
      ],
    );
  }
}
