class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final int age;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'age': age,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      age: map['age'],
    );
  }
}
