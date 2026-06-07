// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IQ Motors';

  @override
  String get myAccount => 'My Account';

  @override
  String get signOut => 'Sign Out';

  @override
  String get navAllModels => 'All Models';

  @override
  String get navTuning => 'Tuning & Modified';

  @override
  String get navShowrooms => 'Showrooms';

  @override
  String get heroTitle => 'Power, simplified.';

  @override
  String get heroSubtitle => 'A new experience for discovering premium cars.';

  @override
  String get viewAll => 'All';

  @override
  String get footerCopyright => '© 2026 IQ Motors. All rights reserved.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get back => 'Back';

  @override
  String get signIn => 'Sign In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signInSubtitle => 'Enter your phone number and password.';

  @override
  String get registerSubtitle =>
      'Welcome — choose your account type to get started.';

  @override
  String get accountIndividual => 'Individual';

  @override
  String get accountShowroom => 'Car Showroom';

  @override
  String get emailSuperAdmin => 'Email (for Super Admin)';

  @override
  String get emailPlaceholder => 'Enter your email';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phonePlaceholder => '0750 000 0000';

  @override
  String get workPhonePlaceholder => '0770 000 0000';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordPlaceholder => 'Enter your password';

  @override
  String get passwordSetPlaceholder => 'Set your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get fullNamePlaceholder => 'Enter your name';

  @override
  String get otpRequired => 'Verification code is required';

  @override
  String get otpInvalid => 'Invalid verification code';

  @override
  String get otpPlaceholder => 'Verification code';

  @override
  String get sendCode => 'Send Code';

  @override
  String get showroomName => 'Showroom Name';

  @override
  String get showroomNameRequired => 'Showroom name is required';

  @override
  String get showroomNamePlaceholder => 'e.g. VIP Showroom';

  @override
  String get ownerName => 'Owner / Manager Name';

  @override
  String get ownerRequired => 'Manager name is required';

  @override
  String get ownerPlaceholder => 'Full name of the account manager';

  @override
  String get workPhoneLabel => 'Work Phone';

  @override
  String get cityLocation => 'City / Location';

  @override
  String get selectCityLocation => 'Select city / location';

  @override
  String get selectCityRequired => 'Please select your city';

  @override
  String get selectCityHint => 'Select your city...';

  @override
  String get register => 'Register';

  @override
  String get submitShowroomRequest => 'Submit Request';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get enterPhoneFirst => 'Enter your phone number first';

  @override
  String verificationCodeSent(String phone) {
    return 'Verification code sent to $phone';
  }

  @override
  String get authInvalidPhone =>
      'Invalid mobile number. Example: 0750 000 0000';

  @override
  String get authRegistrationFailed => 'Registration failed. Please try again.';

  @override
  String get authSendCodeFirst => 'Send the verification code first';

  @override
  String get authPhoneAutoVerified => 'Phone number verified automatically';

  @override
  String get authEmailAlreadyInUse =>
      'This phone number is already registered. Try signing in.';

  @override
  String get authWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get authWrongCredentials => 'Incorrect phone number or password.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get authNetworkError => 'No internet connection. Please try again.';

  @override
  String get authGenericError => 'Something went wrong. Please try again.';

  @override
  String get authVerificationExpired =>
      'Verification code expired. Send a new code.';

  @override
  String get authCaptchaFailed =>
      'Security verification failed. Refresh the page and try again.';

  @override
  String get cityErbil => 'Erbil';

  @override
  String get citySulaymaniyah => 'Sulaymaniyah';

  @override
  String get cityBaghdad => 'Baghdad';

  @override
  String get cityDohuk => 'Dohuk';

  @override
  String get cityKirkuk => 'Kirkuk';

  @override
  String get cityMosul => 'Mosul';

  @override
  String get cityBasra => 'Basra';

  @override
  String get cityMaysan => 'Maysan';

  @override
  String get cityNajaf => 'Najaf';

  @override
  String get cityKarbala => 'Karbala';

  @override
  String get cityAnbar => 'Anbar';

  @override
  String get citySalahuddin => 'Salah al-Din';

  @override
  String get cityBabylon => 'Babylon';

  @override
  String get cityDiyala => 'Diyala';

  @override
  String get cityWasit => 'Wasit';

  @override
  String get cityMuthanna => 'Muthanna';

  @override
  String get cityQadisiyyah => 'Qadisiyyah';

  @override
  String get cityHalabja => 'Halabja';

  @override
  String get cityDhiQar => 'Dhi Qar';

  @override
  String get locationDefaultRegion => 'Erbil, Sulaymaniyah & 3 more cities';

  @override
  String get locationAllCities => 'All Cities';

  @override
  String get locationSearch => 'Search';

  @override
  String get locationApply => 'Apply';

  @override
  String locationTwoCities(String city1, String city2) {
    return '$city1, $city2';
  }

  @override
  String locationCitiesAndMore(String city1, String city2, String count) {
    return '$city1, $city2 and $count other cities';
  }

  @override
  String get selectCity => 'Select City';

  @override
  String get advancedSearch => 'Advanced Search';

  @override
  String get filterModel => 'Model';

  @override
  String get filterYear => 'Year';

  @override
  String get filterMileage => 'Mileage';

  @override
  String get filterPrice => 'Price';

  @override
  String get filterCondition => 'Condition';

  @override
  String get filterEngineType => 'Engine Type';

  @override
  String get filterAllModels => 'All Models';

  @override
  String get filterAllYears => 'All Years';

  @override
  String get filterAllMileages => 'All Mileages';

  @override
  String get filterAllPrices => 'All Prices';

  @override
  String get modelCamry => 'Camry';

  @override
  String get modelLandCruiser => 'Land Cruiser';

  @override
  String get modelPatrol => 'Patrol';

  @override
  String get mileage0 => '0 km';

  @override
  String get mileage10k => 'Up to 10,000 km';

  @override
  String get mileage50k => 'Up to 50,000 km';

  @override
  String get mileage100k => 'Up to 100,000 km';

  @override
  String get mileage100kPlus => '100,000+ km';

  @override
  String get price20k => 'Up to \$20,000';

  @override
  String get price50k => 'Up to \$50,000';

  @override
  String get price100k => 'Up to \$100,000';

  @override
  String get price100kPlus => '\$100,000+';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionUsed => 'Used';

  @override
  String get enginePetrol => 'Petrol';

  @override
  String get engineHybrid => 'Hybrid';

  @override
  String get clearFilters => 'Clear';

  @override
  String showCarsCount(String count) {
    return 'Show $count cars';
  }

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterBrands => 'Brands';

  @override
  String get filterTrim => 'Trim';

  @override
  String get filterFromYear => 'From Year';

  @override
  String get filterToYear => 'To Year';

  @override
  String get filterMinPrice => 'Min Price';

  @override
  String get filterMaxPrice => 'Max Price';

  @override
  String get filterMinMileage => 'Min Mileage';

  @override
  String get filterMaxMileage => 'Max Mileage';

  @override
  String get filterPlateCity => 'Plate City';

  @override
  String get filterPlateType => 'Plate Type';

  @override
  String get filterConditionSection => 'Condition';

  @override
  String get filterAll => 'All';

  @override
  String get filterEngineSize => 'Engine Size';

  @override
  String get filterCylinders => 'Cylinders';

  @override
  String get filterImportCountry => 'Import Country';

  @override
  String get filterColor => 'Color';

  @override
  String get filterFuelType => 'Fuel Type';

  @override
  String get filterElectric => 'Electric';

  @override
  String get filterTransmission => 'Transmission';

  @override
  String get filterManual => 'Manual';

  @override
  String get filterSeatMaterial => 'Seat Material';

  @override
  String get filterSearchModel => 'Search for model';

  @override
  String filterShowResults(String count) {
    return 'Show $count cars';
  }

  @override
  String get trimBase => 'Standard';

  @override
  String get trimSport => 'Sport';

  @override
  String get trimLuxury => 'Luxury';

  @override
  String get plateTypePrivate => 'Private';

  @override
  String get plateTypeTemporary => 'Temporary';

  @override
  String get plateTypeCommercial => 'Commercial';

  @override
  String get cylinders4 => '4 Cylinders';

  @override
  String get cylinders6 => '6 Cylinders';

  @override
  String get cylinders8 => '8 Cylinders';

  @override
  String get importUae => 'UAE';

  @override
  String get importUsa => 'USA';

  @override
  String get importEurope => 'Europe';

  @override
  String get importGcc => 'GCC';

  @override
  String get importLocal => 'Local';

  @override
  String get seatFabric => 'Fabric';

  @override
  String get seatLeather => 'Leather';

  @override
  String get seatSemiLeather => 'Semi-Leather';

  @override
  String get seatAlcantaraLeather => 'Alcantara/Leather';

  @override
  String get seatAlcantara => 'Alcantara';

  @override
  String get brandTitle => 'Car Brand';

  @override
  String get brandSearchHint => 'Search brands...';

  @override
  String get noBrandsFound => 'No brands found';

  @override
  String get specEngine => 'Engine';

  @override
  String get specMileage => 'Mileage';

  @override
  String get specTransmission => 'Transmission';

  @override
  String get specLocation => 'Location';

  @override
  String get carDetailsTitle => 'Car Details';

  @override
  String get description => 'Description';

  @override
  String get features => 'Features';

  @override
  String get technicalDetails => 'Technical Details';

  @override
  String get specYear => 'Year';

  @override
  String get specType => 'Type';

  @override
  String get specColor => 'Color';

  @override
  String get contactSeller => 'Contact Seller';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get phoneCall => 'Phone Call';

  @override
  String get saveToWishlist => 'Save';

  @override
  String get removeFromWishlist => 'Remove from Wishlist';

  @override
  String get sellerDefault => 'Seller';

  @override
  String get transmissionAutomatic => 'Automatic';

  @override
  String get dummyCarDescription =>
      'Brand-new 2024 Cadillac Escalade-V at the highest VIP spec. Fully packaged with zero mileage. Ideal for the Kurdistan and Iraq market through a verified showroom.';

  @override
  String get dummyFeature1 => 'Full VIP package';

  @override
  String get dummyFeature2 => '38-inch OLED display';

  @override
  String get dummyFeature3 => 'Heated & ventilated front seats';

  @override
  String get dummyFeature4 => 'AKG sound system';

  @override
  String get dummyFeature5 => '360° camera';

  @override
  String get dummyFeature6 => 'Panoramic roof';

  @override
  String get dummyFeature7 => 'Rear passenger screen';

  @override
  String get dummyFeature8 => 'Three-row climate control';

  @override
  String get dummyColorMatteWhite => 'Matte White';

  @override
  String get dummySellerName => 'Aram Muhammad';

  @override
  String get dummySellerShowroom => 'VIP Showroom';

  @override
  String get dummySellerListings => '42 active listings';

  @override
  String get superAdminBadge => 'Super Admin';

  @override
  String get superAdminTitle => 'Super Admin';

  @override
  String welcomeAdmin(String name) {
    return 'Welcome, $name';
  }

  @override
  String get adminSubtitle =>
      'Review pending listings and platform statistics.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navApprovals => 'Approvals';

  @override
  String get navUsers => 'Users';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get statPendingApproval => 'Pending Approval';

  @override
  String get statTotalUsers => 'Total Users';

  @override
  String get statActiveListings => 'Active Listings';

  @override
  String get statRegisteredShowrooms => 'Registered Showrooms';

  @override
  String get pendingListingsTitle => 'Pending Listings';

  @override
  String get pendingListingsSubtitle => 'Review before publishing on the site.';

  @override
  String newCount(int count) {
    return '$count new';
  }

  @override
  String get tableCar => 'Car';

  @override
  String get tablePublisher => 'Publisher';

  @override
  String get tablePrice => 'Price';

  @override
  String get tableActions => 'Actions';

  @override
  String get publisherShowroom => 'Showroom';

  @override
  String get publisherIndividual => 'Individual';

  @override
  String get actionView => 'View';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionApprove => 'Approve';

  @override
  String get dummyPublisherVipShowroom => 'VIP Showroom';

  @override
  String get dummyPublisherAras => 'Aras Muhammad';

  @override
  String get dummyPublisherAlofShowroom => 'Alof Showroom';

  @override
  String get dummyPublisherHiwa => 'Hiwa Jamil';
}
