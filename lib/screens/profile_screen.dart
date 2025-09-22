import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the accent color for icons
    const Color accentColor = Color(0xFFEF6A6A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // --- Profile Picture and Name Section ---
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      // Make sure you have an image in your assets folder
                      // and update pubspec.yaml accordingly.
                      backgroundImage: AssetImage('assets/profile_pic.png'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kris Kalariya',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '30 Male',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Mobile Number Section ---
              const Text(
                'Mobile Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    side: BorderSide(color: Color(0xFFF0F0F0))),
                child: ListTile(
                  leading: Icon(Icons.phone, color: accentColor),
                  title: Text('+91 97274 28844'),
                ),
              ),
              const SizedBox(height: 30),

              // --- Settings Section ---
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                      onTap: () {
                        // Handle Edit Profile tap
                      },
                      color: accentColor,
                    ),
                    _buildSettingsTile(
                      icon: Icons.password,
                      title: 'Change Password',
                      onTap: () {
                        // Handle Change Password tap
                      },
                      color: accentColor,
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () {
                        // Handle Logout tap
                      },
                      color: accentColor,
                      hideDivider: true, // No divider for the last item
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

  // Helper widget to build each setting item to avoid code repetition
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
