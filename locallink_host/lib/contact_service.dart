import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  Future<List<Map<String, dynamic>>> getContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      throw Exception('Permission denied');
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);

    return contacts.map((c) {
      String phone = c.phones.isNotEmpty ? c.phones.first.number : '';

      return {'id': c.id, 'displayName': c.displayName, 'phone': phone};
    }).toList();
  }
}
