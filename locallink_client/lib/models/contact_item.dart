class ContactItem {
  final String id;
  final String displayName;
  final String phone;

  ContactItem({
    required this.id,
    required this.displayName,
    required this.phone,
  });

  factory ContactItem.fromJson(Map<String, dynamic> json) {
    return ContactItem(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? 'Unknown',
      phone: json['phone'] ?? '',
    );
  }
}
