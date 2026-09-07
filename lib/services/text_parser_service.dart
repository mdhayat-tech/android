import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/action_model.dart';

/// Converts pasted text into executable actions without holding UI state.
class TextParserService {
  TextParserService._();

  static final RegExp _urlPattern = RegExp(
    r'(?:(?:https?|ftp)://|www\.)[^\s<>]+',
    caseSensitive: false,
  );
  static final RegExp _phonePattern = RegExp(
    r'(?<!\w)(?:\+?\d[\d ()().-]{7,}\d)(?!\w)',
  );
  static final RegExp _trackingPattern = RegExp(
    r'(?<![A-Za-z0-9])[A-Za-z0-9]{12,22}(?![A-Za-z0-9])',
  );
  static final RegExp _addressPattern = RegExp(
    r'\b\d{1,6}\s+[A-Za-z0-9][A-Za-z0-9 .\'-]{2,},\s*[A-Za-z .\'-]{2,}',
    caseSensitive: false,
  );

  static List<SmartAction> getActionsForText(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return <SmartAction>[];

    final actions = <SmartAction>[];
    final urlMatch = _urlPattern.firstMatch(trimmedText)?.group(0);
    final phoneMatch = _phonePattern.firstMatch(trimmedText)?.group(0);

    if (urlMatch != null) {
      final normalizedUrl = _normalizeUrl(urlMatch);
      actions.add(_action(
        title: 'Open Link',
        iconName: 'open_in_new',
        actionUrl: normalizedUrl,
        callback: () => _launch(Uri.parse(normalizedUrl)),
      ));
    }

    if (_addressPattern.hasMatch(trimmedText)) {
      final mapsUrl = Uri.https(
        'www.google.com',
        '/maps/search/',
        <String, String>{'api': '1', 'query': trimmedText},
      );
      actions.add(_action(
        title: 'View on Google Maps',
        iconName: 'map_outlined',
        actionUrl: mapsUrl.toString(),
        callback: () => _launch(mapsUrl),
      ));
    }

    if (phoneMatch != null) {
      final phoneNumber = _digitsOnly(phoneMatch);
      final callUrl = 'tel:$phoneNumber';
      final whatsappUrl = 'https://wa.me/${phoneNumber.replaceFirst('+', '')}';
      actions.add(_action(
        title: 'Call Number',
        iconName: 'phone_outlined',
        actionUrl: callUrl,
        callback: () => _launch(Uri.parse(callUrl)),
      ));
      actions.add(_action(
        title: 'Send WhatsApp Message',
        iconName: 'chat_outlined',
        actionUrl: whatsappUrl,
        callback: () => _launch(Uri.parse(whatsappUrl)),
      ));
    }

    if (_trackingPattern.hasMatch(trimmedText) && phoneMatch == null) {
      final trackingUrl = Uri.https(
        'www.google.com',
        '/search',
        <String, String>{'q': '$trimmedText tracking'},
      );
      actions.add(_action(
        title: 'Track Package',
        iconName: 'local_shipping_outlined',
        actionUrl: trackingUrl.toString(),
        callback: () => _launch(trackingUrl),
      ));
    }

    final searchUrl = Uri.https(
      'www.google.com',
      '/search',
      <String, String>{'q': trimmedText},
    );
    final shareUrl = Uri(
      scheme: 'mailto',
      queryParameters: <String, String>{
        'subject': 'Shared from QuickActions',
        'body': trimmedText,
      },
    );

    actions.addAll(<SmartAction>[
      _action(
        title: 'Search Google',
        iconName: 'search',
        actionUrl: searchUrl.toString(),
        callback: () => _launch(searchUrl),
      ),
      _action(
        title: 'Copy to Clipboard',
        iconName: 'copy_outlined',
        actionUrl: '',
        callback: () => Clipboard.setData(ClipboardData(text: trimmedText)),
      ),
      _action(
        title: 'Share Text',
        iconName: 'share_outlined',
        actionUrl: shareUrl.toString(),
        callback: () => _launch(shareUrl),
      ),
    ]);

    return actions;
  }

  static SmartAction _action({
    required String title,
    required String iconName,
    required String actionUrl,
    required ActionCallback callback,
  }) {
    return SmartAction(
      title: title,
      iconName: iconName,
      actionUrl: actionUrl,
      onTapCallback: callback,
    );
  }

  static String _normalizeUrl(String value) {
    return value.toLowerCase().startsWith('www.') ? 'https://$value' : value;
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}