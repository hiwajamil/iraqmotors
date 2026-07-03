/// A locally stored brand/model pair from search or listing views.
class UserCarInterest {
  const UserCarInterest({
    required this.brandId,
    this.modelKey,
  });

  final String brandId;
  final String? modelKey;

  bool matches(UserCarInterest other) =>
      brandId == other.brandId && modelKey == other.modelKey;

  Map<String, dynamic> toJson() => {
        'brandId': brandId,
        if (modelKey != null) 'modelKey': modelKey,
      };

  factory UserCarInterest.fromJson(Map<String, dynamic> json) {
    return UserCarInterest(
      brandId: json['brandId']?.toString() ?? '',
      modelKey: json['modelKey']?.toString(),
    );
  }
}
