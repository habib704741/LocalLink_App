import 'package:flutter/material.dart';
import '../sms_service.dart';

class DeviceSmsScreen extends StatefulWidget {
  const DeviceSmsScreen({super.key});

  @override
  State<DeviceSmsScreen> createState() => _DeviceSmsScreenState();
}

class _DeviceSmsScreenState extends State<DeviceSmsScreen> {
  final SmsService _smsService = SmsService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSms();
  }

  Future<void> _loadSms() async {
    try {
      final data = await _smsService.getMessages();
      setState(() {
        _messages = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Inbox")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _messages.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final m = _messages[index];
                final date = DateTime.fromMillisecondsSinceEpoch(m['date']);

                return ListTile(
                  leading: const Icon(Icons.sms),
                  title: Text(m['address'] ?? 'Unknown'),
                  subtitle: Text(m['body'] ?? ''),
                  trailing: Text(
                    "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                  ),
                );
              },
            ),
    );
  }
}
