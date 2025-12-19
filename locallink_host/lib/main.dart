import 'package:flutter/material.dart';
import 'package:locallink_host/screens/device_contacts_screen.dart';
import 'package:locallink_host/screens/device_files_screen.dart';
import 'package:locallink_host/screens/device_sms_screen.dart';
import 'package:locallink_host/system_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'server.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalLinkServer _server = LocalLinkServer();

  bool _isRunning = false;
  String _ipAddress = "Loading...";

  final SystemService _systemService = SystemService();
  String _storageText = "Calculating...";
  double _storagePercent = 0.0;

  @override
  void initState() {
    super.initState();
    _getDeviceIP();
    _requestPermission();
    _loadLocalStats();
  }

  Future<void> _loadLocalStats() async {
    final data = await _systemService.getSystemData();
    if (mounted) {
      setState(() {
        _storageText = data['storageLabel'];
        _storagePercent = data['storagePercent'];
      });
    }
  }

  Future<void> _requestPermission() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _getDeviceIP() async {
    final info = NetworkInfo();
    setState(() async {
      _ipAddress = (await info.getWifiIP())!;
    });
  }

  void _toggleServer() async {
    if (_isRunning) {
      await _server.stop();
    } else {
      await _server.start();
    }

    setState(() {
      _isRunning = !_isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LocalLink Host")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRunning ? "Server Running" : "Server Stopped",
              style: TextStyle(
                fontSize: 24,
                color: _isRunning ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Text("Access at: $_ipAddress:8080/"),
            const SizedBox(height: 40),

            Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Device Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(_storageText),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(value: _storagePercent),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _toggleServer,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Colors.indigo,
                          ),
                          child: Text(
                            _isRunning ? "Stop Server" : "Start Server",
                          ),
                        ),

                        const SizedBox(height: 30),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_shared),
                          label: const Text("Manage My Files"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Colors.indigo,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DeviceFilesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_shared),
                          label: const Text("View Contacts"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Colors.indigo,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DeviceContactsScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_shared),
                          label: const Text("View Messages"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Colors.indigo,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DeviceSmsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
