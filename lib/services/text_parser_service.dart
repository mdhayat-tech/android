import '../models/action_model.dart';

class TextParserService {
  static List<SmartAction> getActionsForText(String text) {
    List<SmartAction> actions = [];
    if (text.trim().isEmpty) return actions;

    // 1. URL Detection
    final urlRegex = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
      caseSensitive: false,
    );
    
    // 2. Phone Number Detection (Matches global formats)
    final phoneRegex = RegExp(r'\+?[0-9]{7,15}');

    // 3. Address Detection (Fixed Escaped Syntax)
    final addressRegex = RegExp(
      r'\b\d{1,6}\s+[A-Za-z0-9\s\.,\-\x27]{5,50}',
      caseSensitive: false,
    );

    // 4. Tracking Number Detection (Standard 12 to 22 digit alphanumeric barcodes)
    final trackingRegex = RegExp(r'\b[A-Z0-9]{12,22}\b', caseSensitive: false);

    // Apply URL Parsing
    if (urlRegex.hasMatch(text)) {
      final match = urlRegex.firstMatch(text)?.group(0) ?? '';
      final validUrl = match.startsWith('http') ? match : 'https://$match';
      actions.add(SmartAction(
        title: 'Open Link',
        iconName: 'link',
        actionUrl: validUrl,
      ));
    }

    // Apply Phone Parsing
    if (phoneRegex.hasMatch(text)) {
      final phone = phoneRegex.firstMatch(text)?.group(0) ?? '';
      actions.add(SmartAction(
        title: 'Call Number',
        iconName: 'phone',
        actionUrl: 'tel:$phone',
      ));
      actions.add(SmartAction(
        title: 'Send WhatsApp',
        iconName: 'message',
        actionUrl: 'https://wa.me{phone.replaceAll('+', '')}',
      ));
    }

    // Apply Address Parsing
    if (addressRegex.hasMatch(text) && !urlRegex.hasMatch(text)) {
      final address = addressRegex.firstMatch(text)?.group(0) ?? '';
      final encodedAddress = Uri.encodeComponent(address);
      actions.add(SmartAction(
        title: 'View on Maps',
        iconName: 'map',
        actionUrl: 'https://google.com',
      ));
    }

    // Apply Tracking Parsing
    if (trackingRegex.hasMatch(text) && !urlRegex.hasMatch(text) && !phoneRegex.hasMatch(text)) {
      final tracking = trackingRegex.firstMatch(text)?.group(0) ?? '';
      actions.add(SmartAction(
        title: 'Track Package',
        iconName: 'local_shipping',
        actionUrl: 'https://google.com',
      ));
    }

    // Always provide fallback general actions for basic text strings
    final cleanText = Uri.encodeComponent(text);
    actions.add(SmartAction(
      title: 'Google Search',
      iconName: 'search',
      actionUrl: 'https://google.com',
    ));

    actions.add(SmartAction(
      title: 'Translate Text',
      iconName: 'translate',
      actionUrl: 'https://google.com',
    ));

    return actions;
  }
}
