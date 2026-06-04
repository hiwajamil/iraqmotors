enum AccountType {
  individual,
  showroom;

  String get firestoreValue => name;

  static AccountType fromFirestore(String value) {
    return AccountType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AccountType.individual,
    );
  }
}
