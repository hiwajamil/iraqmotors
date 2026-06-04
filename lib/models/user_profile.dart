import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_type.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.accountType,
    required this.phone,
    required this.displayName,
    this.showroomName,
    this.ownerName,
    this.city,
    this.createdAt,
  });

  final String uid;
  final AccountType accountType;
  final String phone;
  final String displayName;
  final String? showroomName;
  final String? ownerName;
  final String? city;
  final DateTime? createdAt;

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      accountType: AccountType.fromFirestore(
        data['accountType'] as String? ?? 'individual',
      ),
      phone: data['phone'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      showroomName: data['showroomName'] as String?,
      ownerName: data['ownerName'] as String?,
      city: data['city'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'accountType': accountType.firestoreValue,
      'phone': phone,
      'displayName': displayName,
      if (showroomName != null) 'showroomName': showroomName,
      if (ownerName != null) 'ownerName': ownerName,
      if (city != null) 'city': city,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
