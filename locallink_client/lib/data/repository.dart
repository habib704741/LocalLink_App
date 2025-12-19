import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:locallink_client/models/contact_item.dart';
import 'package:locallink_client/models/sms_item.dart';
import '../models/system_info.dart';
import '../models/file_item.dart';

abstract class LocalLinkRepository {
  Future<SystemInfo> getSystemInfo();
  Future<List<FileItem>> getFiles(String? path);
  Future<List<ContactItem>> getContacts();
  Future<List<SmsItem>> getMessages();
}

class MockRepository implements LocalLinkRepository {
  @override
  Future<SystemInfo> getSystemInfo() async {
    return SystemInfo(
      deviceName: "Mock Pixel",
      batteryLevel: 80,
      isCharging: false,
      storageLabel: "Unknown Storage",
      storagePercent: 0.0,
    );
  }

  @override
  Future<List<FileItem>> getFiles(String? path) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      FileItem(name: "DCIM", path: "/storage/DCIM", isDirectory: true, size: 0),
      FileItem(
        name: "Music",
        path: "/storage/Music",
        isDirectory: true,
        size: 0,
      ),
      FileItem(
        name: "photo.jpg",
        path: "/storage/photo.jpg",
        isDirectory: false,
        size: 2048,
      ),
    ];
  }

  @override
  Future<List<ContactItem>> getContacts() async {
    return [ContactItem(id: '1', displayName: 'Mock Mom', phone: '123')];
  }

  @override
  Future<List<SmsItem>> getMessages() async {
    return [
      SmsItem(
        id: 1,
        address: "+123456",
        body: "Hello from Mock!",
        date: 0,
        read: false,
      ),
    ];
  }
}

class ApiRepository implements LocalLinkRepository {
  final String baseUrl;
  ApiRepository(this.baseUrl);

  @override
  Future<SystemInfo> getSystemInfo() async {
    final response = await http.get(Uri.parse('$baseUrl/api/system'));
    if (response.statusCode == 200) {
      return SystemInfo.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to load system info");
  }

  @override
  Future<List<FileItem>> getFiles(String? path) async {
    try {
      String urlString = '$baseUrl/api/files';
      if (path != null) {
        urlString += '?path=$path';
      }

      final response = await http.get(Uri.parse(urlString));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FileItem.fromJson(json)).toList();
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  @override
  Future<List<ContactItem>> getContacts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/contacts'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ContactItem.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load contacts");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  @override
  Future<List<SmsItem>> getMessages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sms'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => SmsItem.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load SMS");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }
}
