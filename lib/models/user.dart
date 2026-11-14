import 'package:equatable/equatable.dart';

enum UserRole {
  user,
  admin;

  static UserRole fromApi(Object? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      _ => UserRole.user,
    };
  }

  String get apiValue => name;
}

/// A MealMate account as returned by the Express API.
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.user,
    this.isActive = true,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];

    return User(
      id: rawId?.toString() ?? '',
      name: (json['name'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      role: UserRole.fromApi(json['role']),
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: _parseDate(json['lastLoginAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.apiValue,
      'isActive': isActive,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    isActive,
    lastLoginAt,
    createdAt,
    updatedAt,
  ];
}
