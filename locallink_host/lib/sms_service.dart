import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<List<Map<String, dynamic>>> getMessages() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        throw Exception('SMS Permission denied');
      }
    }

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 50,
    );

    return messages.map((m) {
      return {
        'id': m.id,
        'address': m.address,
        'body': m.body,
        'date': m.date?.millisecondsSinceEpoch ?? 0,
        'read': m.read,
      };
    }).toList();
  }
}
