import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/sms_item.dart';

class SmsScreen extends StatefulWidget {
  final LocalLinkRepository repository;
  const SmsScreen({super.key, required this.repository});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  Future<List<SmsItem>>? _smsFuture;

  @override
  void initState() {
    super.initState();
    _smsFuture = widget.repository.getMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: FutureBuilder<List<SmsItem>>(
        future: _smsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Messages"));
          }

          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final msg = snapshot.data![index];
              final date = DateTime.fromMillisecondsSinceEpoch(msg.date);

              return ListTile(
                leading: const Icon(Icons.message, color: Colors.indigo),
                title: Text(
                  msg.address,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
