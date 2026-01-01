class ContactItem {
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String initials;

  ContactItem({
    required this.displayName,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    required this.initials,
  });

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'initials': initials,
    };
  }

  factory ContactItem.fromJson(Map<String, dynamic> json) {
    return ContactItem(
      displayName: json['displayName'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      initials: json['initials'] ?? '',
    );
  }
}
