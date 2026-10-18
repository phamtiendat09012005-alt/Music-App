class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> favorites;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.favorites = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      favorites: (json['favorites'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}