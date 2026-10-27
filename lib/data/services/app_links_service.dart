import 'package:app_links/app_links.dart';

/// Extracts an invite code from a Universal/App Link or web URL.
///
/// Accepted shapes:
/// - https://bagifair.app/join/ABC123
/// - bagifair://join/ABC123
/// - https://bagifair.app/join?code=ABC123
String? inviteCodeFromUri(Uri uri) {
  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
  final list = segments.toList(growable: false);
  for (var index = 0; index < list.length; index++) {
    if (list[index].toLowerCase() == 'join' && index + 1 < list.length) {
      return list[index + 1].toUpperCase();
    }
  }
  final query = uri.queryParameters['code'] ?? uri.queryParameters['invite'];
  if (query != null && query.trim().isNotEmpty) {
    return query.trim().toUpperCase();
  }
  if (uri.scheme == 'bagifair' && uri.host == 'join') {
    final first = uri.pathSegments.where((segment) => segment.isNotEmpty);
    if (first.isNotEmpty) return first.first.toUpperCase();
  }
  return null;
}

class AppLinksService {
  AppLinksService();

  final AppLinks _links = AppLinks();

  Stream<String> get inviteCodes {
    return _links.uriLinkStream
        .map(inviteCodeFromUri)
        .where((code) => code != null)
        .cast<String>();
  }

  Future<String?> initialInviteCode() async {
    try {
      final uri = await _links.getInitialLink();
      return uri == null ? null : inviteCodeFromUri(uri);
    } catch (_) {
      return null;
    }
  }
}
