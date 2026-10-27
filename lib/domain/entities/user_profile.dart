import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.defaultCurrency = 'IDR',
    this.localeCode = 'id',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String defaultCurrency;
  final String localeCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? defaultCurrency,
    String? localeCode,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      localeCode: localeCode ?? this.localeCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'display_name': displayName,
    'email': email,
    'avatar_url': avatarUrl,
    'default_currency': defaultCurrency,
    'locale': localeCode,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['user_id'] ?? json['id']) as String,
      displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
          ? json['display_name'] as String
          : 'Pengguna',
      email: (json['email'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      defaultCurrency: (json['default_currency'] as String?) ?? 'IDR',
      localeCode: (json['locale'] as String?) ?? 'id',
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static DateTime _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

  @override
  List<Object?> get props => [
    id,
    displayName,
    email,
    avatarUrl,
    defaultCurrency,
    localeCode,
    createdAt,
    updatedAt,
  ];
}
