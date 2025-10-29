import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

class ShareHelper {
  static Future<void> shareText(String text, {String? subject}) async {
    if (kIsWeb) {
      _shareWeb(text, subject: subject);
    } else {
      // share_plus já foi importado no widget
    }
  }

  static void _shareWeb(String text, {String? subject}) {
    try {
      final encoded = Uri.encodeComponent(text);
      final url = 'https://wa.me/?text=$encoded';
      html.window.open(url, '_blank');
    } catch (e) {
      debugPrint('Erro ao compartilhar via WhatsApp Web: $e');
    }
  }

  static void copyToClipboard(String text) {
    html.window.navigator.clipboard?.writeText(text).catchError((e) {
      debugPrint('Erro ao copiar: $e');
    });
  }
}
