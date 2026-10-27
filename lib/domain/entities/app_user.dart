import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.isDemo = false,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final bool isDemo;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.length > 1
        ? parts.last.substring(0, 1).toUpperCase()
        : '';
    return '$first$last';
  }

  @override
  List<Object?> get props => [id, displayName, email, avatarUrl, isDemo];
}
