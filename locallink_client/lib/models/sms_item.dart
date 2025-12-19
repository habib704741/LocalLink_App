class SmsItem {
  final int id;
  final String address;
  final String body;
  final int date;
  final bool read;

  SmsItem({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.read,
  });

  factory SmsItem.fromJson(Map<String, dynamic> json) {
    return SmsItem(
      id: json['id'] ?? 0,
      address: json['address'] ?? 'Unknown',
      body: json['body'] ?? '',
      date: json['date'] ?? 0,
      read: json['read'] ?? true,
    );
  }
}
