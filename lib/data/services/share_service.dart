import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  const ShareService();

  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  /// WhatsApp is the default channel for Indonesian friend groups.
  Future<bool> shareToWhatsApp(String text) async {
    final uri = Uri.https('wa.me', '/', {'text': text});
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await shareText(text);
    }
    return opened;
  }
}
