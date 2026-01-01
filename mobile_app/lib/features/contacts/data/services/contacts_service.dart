import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mobile_app/features/contacts/domain/models/contact_item.dart';
import 'dart:convert'; // Add this

class ContactsService {
  /// Get all contacts from device
  static Future<List<ContactItem>> getAllContacts() async {
    try {
      // Request permission
      if (!await FlutterContacts.requestPermission()) {
        throw Exception('Contacts permission denied');
      }

      // Get contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      final contactItems = <ContactItem>[];

      for (final contact in contacts) {
        // Get first phone number
        String? phoneNumber;
        if (contact.phones.isNotEmpty) {
          phoneNumber = contact.phones.first.number;
        }

        // Get first email
        String? email;
        if (contact.emails.isNotEmpty) {
          email = contact.emails.first.address;
        }

        // Display name
        final displayName = contact.displayName.isNotEmpty
            ? contact.displayName
            : 'Unknown';

        // Generate initials
        final initials = _getInitials(displayName);

        String? photoUrl;
        if (contact.photo != null && contact.photo!.isNotEmpty) {
          // Use Dart's built-in encoder
          photoUrl = 'data:image/png;base64,${base64Encode(contact.photo!)}';
        }

        contactItems.add(
          ContactItem(
            displayName: displayName,
            phoneNumber: phoneNumber,
            email: email,
            photoUrl: photoUrl,
            initials: initials,
          ),
        );
      }

      // Sort by display name
      contactItems.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

      return contactItems;
    } catch (e) {
      print('Error getting contacts: $e');
      rethrow;
    }
  }

  /// Get contact initials from name
  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      final firstChar = parts[0].isNotEmpty ? parts[0][0] : '?';
      return firstChar.toUpperCase();
    }

    final firstChar = parts[0].isNotEmpty ? parts[0][0] : '';
    final lastChar = parts[parts.length - 1].isNotEmpty
        ? parts[parts.length - 1][0]
        : '';
    return '$firstChar$lastChar'.toUpperCase();
  }

  /// Convert Uint8List to base64 string
  static String _uint8ListToBase64(List<int> bytes) {
    // Simple base64 encoding
    const base64Chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';
    int i = 0;

    while (i < bytes.length) {
      final b1 = bytes[i++];
      final b2 = i < bytes.length ? bytes[i++] : 0;
      final b3 = i < bytes.length ? bytes[i++] : 0;

      final n = (b1 << 16) | (b2 << 8) | b3;

      result += base64Chars[(n >> 18) & 63];
      result += base64Chars[(n >> 12) & 63];
      result += i - 2 < bytes.length ? base64Chars[(n >> 6) & 63] : '=';
      result += i - 1 < bytes.length ? base64Chars[n & 63] : '=';
    }

    return result;
  }

  /// Search contacts
  static Future<List<ContactItem>> searchContacts(String query) async {
    final allContacts = await getAllContacts();

    if (query.isEmpty) return allContacts;

    final lowerQuery = query.toLowerCase();
    return allContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(lowerQuery) ||
          (contact.phoneNumber?.contains(query) ?? false) ||
          (contact.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
