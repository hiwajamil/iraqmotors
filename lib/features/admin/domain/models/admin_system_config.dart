import 'package:iq_motors/shared/data/add_car_option_keys.dart';
import 'package:iq_motors/shared/data/iraq_locations.dart';

/// Platform-wide configuration stored in Firestore `system_config/platform`.
class AdminSystemConfig {
  const AdminSystemConfig({
    required this.packagePrices,
    required this.activeCities,
    required this.admins,
    this.r2Endpoint = '',
    this.r2AccessKey = '',
    this.r2SecretKey = '',
    this.r2Bucket = '',
    this.r2PublicBaseUrl = '',
    this.r2Region = 'auto',
  });

  static const String firestoreDocPath = 'system_config/platform';

  static const Map<String, int> defaultPackagePrices = {
    AddCarOptionKeys.packageBoost: 10000,
    AddCarOptionKeys.packageSuperBoost: 60000,
  };

  static List<String> get defaultActiveCities =>
      List<String>.from(defaultTrackedCities);

  /// Default governorates used before Firestore config exists.
  ///
  /// Full 19 Iraqi governorates in Kurdish; must stay in sync with the
  /// admin city grids (users + showrooms) and [IraqLocationL10n] mappings.
  static const List<String> defaultTrackedCities = [
    'سلێمانی',
    'هەولێر',
    'دهۆک',
    'هەڵەبجە',
    'کەرکوک',
    'بەغداد',
    'بەسرە',
    'نەینەوا',
    'کەربەلا',
    'نەجەف',
    'ئەنبار',
    'بابل',
    'دیالە',
    'زیقار',
    'قادسیە',
    'میسان',
    'موسەنا',
    'واست',
    'سەڵاحەدین',
  ];

  final Map<String, int> packagePrices;
  final List<String> activeCities;
  final List<AdminAccountEntry> admins;
  final String r2Endpoint;
  final String r2AccessKey;
  final String r2SecretKey;
  final String r2Bucket;
  final String r2PublicBaseUrl;
  final String r2Region;

  int priceForPackage(String packageKey) {
    return packagePrices[packageKey] ??
        defaultPackagePrices[packageKey] ??
        0;
  }

  factory AdminSystemConfig.defaults() {
    return AdminSystemConfig(
      packagePrices: Map<String, int>.from(defaultPackagePrices),
      activeCities: List<String>.from(defaultTrackedCities),
      admins: const [
        AdminAccountEntry(
          email: 'hiwa.constructions@gmail.com',
          phone: '07500000000',
          name: 'Super Admin',
        ),
      ],
    );
  }

  factory AdminSystemConfig.fromFirestore(Map<String, dynamic>? data) {
    final defaults = AdminSystemConfig.defaults();
    if (data == null) return defaults;

    final rawPrices = data['packagePrices'];
    final prices = Map<String, int>.from(defaults.packagePrices);
    if (rawPrices is Map) {
      for (final entry in rawPrices.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is num) {
          prices[key] = value.toInt();
        } else {
          prices[key] = int.tryParse(value.toString()) ?? prices[key] ?? 0;
        }
      }
    }

    final rawCities = data['activeCities'];
    final cities = rawCities is List
        ? rawCities.map((e) => e.toString()).where((c) => c.isNotEmpty).toList()
        : List<String>.from(defaults.activeCities);
    if (cities.isEmpty) {
      cities.addAll(defaults.activeCities);
    }

    final rawAdmins = data['admins'];
    final admins = rawAdmins is List
        ? rawAdmins
            .whereType<Map>()
            .map((m) => AdminAccountEntry.fromMap(Map<String, dynamic>.from(m)))
            .where((a) => a.email.isNotEmpty || a.phone.isNotEmpty)
            .toList()
        : List<AdminAccountEntry>.from(defaults.admins);
    if (admins.isEmpty) {
      admins.addAll(defaults.admins);
    }

    return AdminSystemConfig(
      packagePrices: prices,
      activeCities: cities,
      admins: admins,
      r2Endpoint: data['r2Endpoint']?.toString() ?? '',
      r2AccessKey: data['r2AccessKey']?.toString() ?? '',
      r2SecretKey: data['r2SecretKey']?.toString() ?? '',
      r2Bucket: data['r2Bucket']?.toString() ?? '',
      r2PublicBaseUrl: data['r2PublicBaseUrl']?.toString() ?? '',
      r2Region: data['r2Region']?.toString() ?? 'auto',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'packagePrices': packagePrices,
      'activeCities': activeCities,
      'admins': admins.map((a) => a.toMap()).toList(),
      'r2Endpoint': r2Endpoint,
      'r2AccessKey': r2AccessKey,
      'r2SecretKey': r2SecretKey,
      'r2Bucket': r2Bucket,
      'r2PublicBaseUrl': r2PublicBaseUrl,
      'r2Region': r2Region,
    };
  }

  AdminSystemConfig copyWith({
    Map<String, int>? packagePrices,
    List<String>? activeCities,
    List<AdminAccountEntry>? admins,
    String? r2Endpoint,
    String? r2AccessKey,
    String? r2SecretKey,
    String? r2Bucket,
    String? r2PublicBaseUrl,
    String? r2Region,
  }) {
    return AdminSystemConfig(
      packagePrices: packagePrices ?? this.packagePrices,
      activeCities: activeCities ?? this.activeCities,
      admins: admins ?? this.admins,
      r2Endpoint: r2Endpoint ?? this.r2Endpoint,
      r2AccessKey: r2AccessKey ?? this.r2AccessKey,
      r2SecretKey: r2SecretKey ?? this.r2SecretKey,
      r2Bucket: r2Bucket ?? this.r2Bucket,
      r2PublicBaseUrl: r2PublicBaseUrl ?? this.r2PublicBaseUrl,
      r2Region: r2Region ?? this.r2Region,
    );
  }
}

class AdminAccountEntry {
  const AdminAccountEntry({
    required this.email,
    required this.phone,
    this.name = '',
  });

  final String email;
  final String phone;
  final String name;

  factory AdminAccountEntry.fromMap(Map<String, dynamic> map) {
    return AdminAccountEntry(
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'phone': phone,
        'name': name,
      };
}

/// Suggested cities from Iraq locations not yet in the active list.
List<String> suggestedCitiesNotIn(List<String> active) {
  final activeSet = active.toSet();
  return IraqLocations.provinceOrder
      .where((city) => !activeSet.contains(city))
      .toList();
}
