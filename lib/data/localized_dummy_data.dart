import '../l10n/app_localizations.dart';

/// Localized dummy listing data for prototypes and demos.
abstract final class LocalizedDummyData {
  static Map<String, dynamic> prototypeCar(AppLocalizations l10n) {
    return {
      'make': 'CADILLAC',
      'model': 'Escalade-V 2024',
      'price': r'$165,000',
      'mileage': '0 km',
      'transmission': l10n.transmissionAutomatic,
      'engine': '6.2L Supercharged V8',
      'location': l10n.cityErbil,
      'year': '2024',
      'bodyType': 'SUV',
      'color': l10n.dummyColorMatteWhite,
      'images': [
        'https://images.unsplash.com/photo-1562911791-c7a97b729ec5?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1614200187524-dc4b892acf16?q=80&w=600&auto=format&fit=crop',
      ],
      'description': l10n.dummyCarDescription,
      'features': [
        l10n.dummyFeature1,
        l10n.dummyFeature2,
        l10n.dummyFeature3,
        l10n.dummyFeature4,
        l10n.dummyFeature5,
        l10n.dummyFeature6,
        l10n.dummyFeature7,
        l10n.dummyFeature8,
      ],
      'sellerName': l10n.dummySellerName,
      'sellerShowroom': l10n.dummySellerShowroom,
      'sellerAvatar':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=200&auto=format&fit=crop',
      'sellerVerified': true,
      'sellerListings': l10n.dummySellerListings,
    };
  }

  static List<Map<String, dynamic>> homeListings() {
    return [
      {
        'id': 'demo-cadillac-escalade',
        'imageUrl':
            'https://images.unsplash.com/photo-1562911791-c7a97b729ec5?q=80&w=800&auto=format&fit=crop',
        'make': 'Cadillac',
        'model': 'Escalade-V 2024',
        'price': r'$165,000',
        'latestBid': r'$162,500',
        'engine': '6.2L Supercharged',
        'mileage': '0 km',
      },
      {
        'id': 'demo-mercedes-s500',
        'imageUrl':
            'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=800&auto=format&fit=crop',
        'make': 'Mercedes-Benz',
        'model': 'S-Class S500',
        'price': r'$158,000',
        'latestBid': r'$155,000',
        'engine': '3.0L Inline-6 Turbo',
        'mileage': '2,500 km',
      },
      {
        'id': 'demo-lexus-lx600',
        'imageUrl':
            'https://images.unsplash.com/photo-1614200187524-dc4b892acf16?q=80&w=800&auto=format&fit=crop',
        'make': 'Lexus',
        'model': 'LX 600 VIP',
        'price': r'$152,000',
        'latestBid': r'$149,500',
        'engine': '3.5L Twin-Turbo',
        'mileage': '0 km',
      },
      {
        'id': 'demo-hennessey-raptor',
        'imageUrl':
            'https://images.unsplash.com/photo-1532581140115-3e355d1ed1de?q=80&w=800&auto=format&fit=crop',
        'make': 'Hennessey Performance',
        'model': 'VelociRaptor 600',
        'price': r'$145,000',
        'latestBid': r'$142,000',
        'engine': '3.5L V6 Tuned',
        'mileage': '1,200 km',
      },
    ];
  }
}
