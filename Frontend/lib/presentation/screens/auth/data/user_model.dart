class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? image;
  final String? token;
  final String? visa;
  final String? address;

  UserModel({
    this.id = '',
    required this.name,
    required this.email,
    this.role = 'user',
    this.image,
    this.token,
    this.address,
    this.visa,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? profile['name'] ?? 'FitGuard User').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      image: json['image']?.toString(),
      token: json['token']?.toString(),
      address: json['address']?.toString(),
      visa: json['Visa']?.toString(),
    );
  }
}
