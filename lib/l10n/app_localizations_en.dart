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
  String get authAccountNotFoundPrompt =>
      'This account was not found. Would you like to create a new account?';

  @override
  String get authCreateNewAccount => 'Create account';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get authDeviceBlocked =>
      'This device was temporarily blocked after too many verification attempts. Wait a few hours, try another browser, or use the test number 7722141988 with code 112233.';

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
  String get authInvalidAppCredential =>
      'Phone verification is not available on this domain. Use iqmotors.net or iqmotors-d588d.web.app, or add this domain in Firebase Console → Authentication → Settings → Authorized domains.';

  @override
  String get authBillingRequired =>
      'SMS verification requires Firebase Blaze billing. Contact the app administrator.';

  @override
  String get authPhoneAuthDisabled =>
      'Phone sign-in is disabled in Firebase. Enable Phone provider in the Firebase Console.';

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
  String get filterModelPlaceholder => 'e.g. BMW X7';

  @override
  String get filterYear => 'Year';

  @override
  String get filterYearPlaceholder => 'e.g. 2024';

  @override
  String get filterMileage => 'Mileage';

  @override
  String get filterMileagePlaceholder => 'e.g. up to 50,000 km';

  @override
  String get filterPrice => 'Price';

  @override
  String get filterPricePlaceholder => 'e.g. up to \$50,000';

  @override
  String get filterCondition => 'Condition';

  @override
  String get filterConditionPlaceholder => 'e.g. used';

  @override
  String get filterEngineType => 'Engine Type';

  @override
  String get filterEngineTypePlaceholder => 'e.g. petrol';

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
  String get sellerPriceLabel => 'Seller price:';

  @override
  String get latestBidLabel => 'Latest bid:';

  @override
  String get placeYourBid => 'Place your bid';

  @override
  String get enterBidAmount => 'Enter your bid amount';

  @override
  String get submitBid => 'Submit';

  @override
  String get bidTooLowError =>
      'Please enter an amount higher than the latest bid';

  @override
  String get bidSuccessMessage => 'Your bid was placed successfully!';

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

  @override
  String get userDashboardTitle => 'User Dashboard';

  @override
  String get navHomeScreen => 'Home';

  @override
  String get navMyFavorites => 'My Favorites';

  @override
  String get navMyAds => 'My Listings';

  @override
  String get navMessages => 'Messages';

  @override
  String get userAccountPersonal => 'Personal Account';

  @override
  String get favoritesSectionTitle => 'My Favorites (Saved)';

  @override
  String get favoritesEmpty => 'No saved cars yet';

  @override
  String get myAdsEmpty => 'You have no listings yet';

  @override
  String get viewAllListings => 'View All';

  @override
  String get deleteAdTitle => 'Delete Listing';

  @override
  String get deleteAdConfirm =>
      'Are you sure you want to delete this listing? This action cannot be undone.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get deleteAction => 'Delete';

  @override
  String get adDeletedSuccess => 'Listing deleted successfully';

  @override
  String get sell => 'Sell';

  @override
  String get sellCarButton => 'Sell Car';

  @override
  String get editAction => 'Edit';

  @override
  String get adStatusActive => 'Active';

  @override
  String get adStatusSold => 'Sold';

  @override
  String get soldAction => 'Sold';

  @override
  String get markAsSoldTitle => 'Mark as Sold';

  @override
  String get markAsSoldConfirm =>
      'Mark this listing as sold? Buyers will see a sold badge on the listing.';

  @override
  String get adMarkedSoldSuccess => 'Listing marked as sold';

  @override
  String adPostedAt(String date) {
    return 'Posted: $date';
  }

  @override
  String adDaysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get soldBadgeLabel => 'SOLD';

  @override
  String get carFallbackTitle => 'Vehicle';

  @override
  String get messagesEmpty => 'No messages yet';

  @override
  String get settingsComingSoon => 'Settings coming soon';

  @override
  String get adminApprovalsByCitySubtitle => 'Ad overview by governorate';

  @override
  String get adminUsersByCitySubtitle => 'Users by governorate';

  @override
  String get adminShowroomsByCitySubtitle => 'Showrooms by governorate';

  @override
  String get adminStatApproved => 'Approved';

  @override
  String get adminStatPendingReview => 'Pending';

  @override
  String get adminStatExpired => 'Expired';

  @override
  String get adminRetry => 'Retry';

  @override
  String get adminNoUsersInCity => 'No users in this city.';

  @override
  String get adminNoShowroomsInCity => 'No showrooms in this city.';

  @override
  String get adminNoPendingListings => 'No pending listings.';

  @override
  String get adminSectionComingSoon => 'This section is coming soon.';

  @override
  String get adminAdCountLabel => 'Ad count';

  @override
  String get adminActiveAdCountLabel => 'Active ads';

  @override
  String get adminTotalAdCountLabel => 'Total ads';

  @override
  String get adminUserCountLabel => 'Users';

  @override
  String get adminShowroomCountLabel => 'Showrooms';

  @override
  String get adminRejectAdTitle => 'Reject listing';

  @override
  String get adminRejectAdConfirm =>
      'Are you sure you want to reject this listing?';

  @override
  String get adminAdApprovedSuccess => 'Listing approved successfully';

  @override
  String get adminAdRejectedSuccess => 'Listing rejected';

  @override
  String get adminDescriptionLabel => 'Description';

  @override
  String get adminReportsSubtitle => 'Platform analytics and revenue overview';

  @override
  String get adminDailyActiveUsers => 'Daily Active Users';

  @override
  String get adminDailyNewAds => 'New Ad Submissions';

  @override
  String get adminLast30Days => 'Last 30 days';

  @override
  String get adminTotalRevenue => 'Total Revenue';

  @override
  String get adminRevenueFromBoost => 'From boost packages';

  @override
  String get adminRevenueCard => 'Card';

  @override
  String get adminRevenueEWallet => 'E-Wallet';

  @override
  String get adminCityPerformance => 'City Performance';

  @override
  String get adminCityColumn => 'City';

  @override
  String get adminTotalAdsColumn => 'Total Ads';

  @override
  String get adminApprovedAdsColumn => 'Approved';

  @override
  String get adminSettingsSubtitle =>
      'Manage platform configuration and access';

  @override
  String get adminSettingsGeneral => 'General Settings';

  @override
  String get adminSettingsPackages => 'Package Prices';

  @override
  String get adminSettingsCities => 'Cities & Regions';

  @override
  String get adminSettingsSecurity => 'Security & Admins';

  @override
  String get adminSettingsBoostPrice => 'Boost package price (IQD)';

  @override
  String get adminSettingsSuperBoostPrice => 'Super Boost package price (IQD)';

  @override
  String get adminSettingsSaveChanges => 'Save Changes';

  @override
  String get adminSettingsSavedSuccess => 'Settings saved successfully';

  @override
  String get adminSettingsActiveCities => 'Active cities';

  @override
  String get adminSettingsAddCity => 'Add New City';

  @override
  String get adminSettingsNewCityHint => 'City name';

  @override
  String get adminSettingsAdmins => 'Platform admins';

  @override
  String get adminSettingsAddAdmin => 'Add New Admin';

  @override
  String get adminSettingsAdminEmail => 'Email';

  @override
  String get adminSettingsAdminPhone => 'Phone';

  @override
  String get adminSettingsAdminName => 'Name';

  @override
  String get adminSettingsSystemCredentials => 'System credentials';

  @override
  String get adminSettingsR2Endpoint => 'R2 endpoint URL';

  @override
  String get adminSettingsR2AccessKey => 'R2 access key';

  @override
  String get adminSettingsR2SecretKey => 'R2 secret key';

  @override
  String get adminSettingsR2Bucket => 'R2 bucket name';

  @override
  String get adminSettingsR2PublicBaseUrl =>
      'R2 public URL (https://pub-xxxx.r2.dev)';

  @override
  String get adminSettingsGeneralInfo => 'Platform information';

  @override
  String get adminSettingsAppName => 'IQ Motors';

  @override
  String get adminSettingsAppVersion => 'Version 1.0.0';

  @override
  String get adminSettingsRemove => 'Remove';

  @override
  String get adminSettingsAddCityTitle => 'Add city';

  @override
  String get adminSettingsAddAdminTitle => 'Add admin';

  @override
  String get adminSettingsCredentialsNote =>
      'Visible to super admins only. Stored in Firestore system_config.';

  @override
  String get navActivity => 'Activity Log';

  @override
  String get adminActivitySubtitle => 'Admin action history and audit trail';

  @override
  String get adminActivitySearchHint => 'Search by admin name or action';

  @override
  String get adminActivityEmpty => 'No activity recorded yet.';

  @override
  String get adminActivityNoResults => 'No matching logs found.';

  @override
  String get adminActivityPerformedBy => 'By';

  @override
  String get adminActivityJustNow => 'Just now';

  @override
  String adminActivityMinutesAgo(int count) {
    return '$count mins ago';
  }

  @override
  String adminActivityHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String adminActivityDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get adminActivityActionApproved => 'Approved Ad';

  @override
  String get adminActivityActionRejected => 'Rejected Ad';

  @override
  String get adminActivityActionDeleted => 'Deleted Ad';

  @override
  String get adminActivityActionUpdatedPrice => 'Updated Package Price';

  @override
  String get adminActivityActionUpdatedConfig => 'Updated Settings';

  @override
  String get adminActivityActionAddedCity => 'Added City';

  @override
  String get adminActivityActionRemovedCity => 'Removed City';

  @override
  String get adminActivityActionAddedAdmin => 'Added Admin';

  @override
  String get adminActivityActionUpdatedCredentials => 'Updated Credentials';

  @override
  String get adminMessagesTitle => 'Messages & Complaints';

  @override
  String get adminMessagesSubtitle => 'User support tickets and conversations';

  @override
  String get adminMessagesFilterAll => 'All';

  @override
  String get adminMessagesFilterOpen => 'Open';

  @override
  String get adminMessagesFilterResolved => 'Resolved';

  @override
  String get adminMessagesStatusOpen => 'Open';

  @override
  String get adminMessagesStatusResolved => 'Resolved';

  @override
  String get adminMessagesSend => 'Send';

  @override
  String get adminMessagesSelectTicket =>
      'Select a ticket to view the conversation';

  @override
  String get adminMessagesResolve => 'Mark resolved';

  @override
  String get adminMessagesReopen => 'Reopen';

  @override
  String get adminMessagesReplyHint => 'Write a reply…';

  @override
  String get adminMessagesBackToList => 'Back to list';

  @override
  String get navFlaggedAds => 'Flagged Reports';

  @override
  String get adminFlaggedSubtitle => 'Review user-reported listings';

  @override
  String get adminFlaggedReasonLabel => 'Reason';

  @override
  String get adminFlaggedReportedByLabel => 'Reported by';

  @override
  String get adminFlaggedViewAd => 'View Ad';

  @override
  String get adminFlaggedDeleteAd => 'Delete Ad';

  @override
  String get adminFlaggedIgnore => 'Dismiss';

  @override
  String get adminFlaggedEmpty => 'No pending reports.';

  @override
  String get adminFlaggedDeleteConfirm =>
      'Are you sure you want to delete this listing?';

  @override
  String get adminFlaggedDeleteSuccess =>
      'Listing deleted and report resolved.';

  @override
  String get adminFlaggedIgnoredSuccess => 'Report dismissed.';

  @override
  String get adminFlaggedAdMissing => 'Listing no longer available';

  @override
  String get flaggedReasonSold => 'Car already sold';

  @override
  String get flaggedReasonWrongPrice => 'Wrong price';

  @override
  String get flaggedReasonMisleading => 'Misleading information';

  @override
  String get flaggedReasonSpam => 'Spam';

  @override
  String get next => 'Next';

  @override
  String addCarStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get addCarPublish => 'Publish';

  @override
  String get addCarSave => 'Save';

  @override
  String get addCarPublishing => 'Publishing...';

  @override
  String get addCarSaving => 'Saving...';

  @override
  String get addCarPhotoProcessing => 'Processing photo...';

  @override
  String get addCarMinPhotosRequired => 'Please select at least 4 photos.';

  @override
  String get addCarUploadFailed => 'Photo upload failed.';

  @override
  String get addCarSaveSuccess => 'Changes saved successfully.';

  @override
  String get addCarPublishSuccess => 'Your listing was published successfully.';

  @override
  String get addCarSaveFailed => 'Save failed. Please try again.';

  @override
  String get addCarPublishFailed => 'Publishing failed. Please try again.';

  @override
  String get addCarPhotoCheckFailed => 'Photo check failed. Please try again.';

  @override
  String get addCarStepLocationTitle => 'Location';

  @override
  String get addCarStepPhotosTitle => 'Photos';

  @override
  String get addCarStepInfoTitle => 'Info';

  @override
  String get addCarStepPlateTitle => 'Plate';

  @override
  String get addCarStepDetailsTitle => 'Details';

  @override
  String get addCarStepTechnicalTitle => 'Technical';

  @override
  String get addCarStepInteriorTitle => 'Interior';

  @override
  String get addCarStepConditionTitle => 'Condition';

  @override
  String get addCarStepPriceTitle => 'Price';

  @override
  String get addCarStepReviewTitle => 'Review';

  @override
  String get addCarStepListingTitle => 'Listing';

  @override
  String get addCarStepPaymentTitle => 'Payment';

  @override
  String get addCarLocationHeading => 'Where is your car located?';

  @override
  String get addCarLocationSubtitle => 'Select province / area';

  @override
  String get addCarProvinceLabel => 'Province';

  @override
  String get addCarProvincePlaceholder => 'Select province';

  @override
  String get addCarAreaLabel => 'Area / City';

  @override
  String get addCarAreaPlaceholder => 'Select area';

  @override
  String get addCarPhotosHeading => 'Take photos';

  @override
  String get addCarPhotosSubtitle => 'Take at least 4 photos of your car';

  @override
  String get addCarPhotoPrimary => 'Primary';

  @override
  String get addCarBasicInfoHeading => 'Basic vehicle information';

  @override
  String get addCarBasicInfoSubtitle =>
      'Select the details that match your vehicle';

  @override
  String get addCarBrandLabel => 'Brand';

  @override
  String get addCarBrandPlaceholder => 'Select brand';

  @override
  String get addCarModelLabel => 'Model';

  @override
  String get addCarModelPlaceholder => 'Select model';

  @override
  String get addCarColorLabel => 'Color';

  @override
  String get addCarColorPlaceholder => 'Select color';

  @override
  String get addCarYearLabel => 'Model year';

  @override
  String get addCarYearPlaceholder => 'Select year';

  @override
  String get addCarTrimLabel => 'Trim';

  @override
  String get addCarTrimPlaceholder => 'Select trim';
}
