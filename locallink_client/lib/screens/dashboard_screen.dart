import 'package:flutter/material.dart';
import 'package:locallink_client/screens/contacts_screen.dart';
import 'package:locallink_client/screens/files_screen.dart';
import 'package:locallink_client/screens/sms_screen.dart';
import '../data/repository.dart';
import '../models/system_info.dart';

class DashboardScreen extends StatefulWidget {
  final LocalLinkRepository repository;

  const DashboardScreen({super.key, required this.repository});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<SystemInfo> _systemInfoFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _systemInfoFuture = widget.repository.getSystemInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("LocalLink Dashboard"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Center(
        child: FutureBuilder<SystemInfo>(
          future: _systemInfoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else if (snapshot.hasData) {
              final info = snapshot.data!;
              return _buildInfoCard(info);
            }
            return const Text("No Data");
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(SystemInfo info) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android, size: 50, color: Colors.indigo),
            const SizedBox(height: 10),
            Text(
              info.deviceName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                info.isCharging
                    ? Icons.battery_charging_full
                    : Icons.battery_std,
                color: Colors.green,
              ),
              title: const Text("Battery Level"),
              trailing: Text(
                "${info.batteryLevel}%",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Internal Storage",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        info.storageLabel,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: info.storagePercent,
                    backgroundColor: Colors.grey[200],
                    color: info.storagePercent > 0.9
                        ? Colors.red
                        : Colors.indigo,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text("Open File Manager"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FilesScreen(repository: widget.repository),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: const Icon(Icons.contacts),
                  label: const Text("View Contacts"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ContactsScreen(repository: widget.repository),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sms),
                  label: const Text("Read Messages"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SmsScreen(repository: widget.repository),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
