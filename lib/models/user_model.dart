// In a file named: lib/models/user_profile.dart

class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String dob;
  final String mobile;
  final String imageUrl;

  UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    required this.dob,
    required this.mobile,
    required this.imageUrl,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      username: data['username'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
      dob: data['dob'] ?? 'N/A',
      mobile: data['mobile'] ?? 'N/A',
      imageUrl: data['imageUrl'] ?? 'assets/default_profile.png',
    );
  }
}
