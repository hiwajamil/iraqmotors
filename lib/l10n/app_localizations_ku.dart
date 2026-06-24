// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kurdish (`ku`).
class AppLocalizationsKu extends AppLocalizations {
  AppLocalizationsKu([String locale = 'ku']) : super(locale);

  @override
  String get appTitle => 'IQ Motors';

  @override
  String get myAccount => 'هەژمارەکەم';

  @override
  String get signOut => 'چوونەدەرەوە';

  @override
  String get navAllModels => 'هەموو مۆدێلەکان';

  @override
  String get navTuning => 'توونینگ و دەستکاریکراو';

  @override
  String get navShowrooms => 'پێشانگاکان';

  @override
  String get heroTitle => 'هێز بە شێوازێکی سادە.';

  @override
  String get heroSubtitle =>
      'ئەزموونێکی نوێ بۆ دۆزینەوەی ئۆتۆمبێلە ئاست بەرزەکان.';

  @override
  String get viewAll => 'هەموو';

  @override
  String get footerCopyright => '© 2026 IQ Motors. گشت مافەکان پارێزراون.';

  @override
  String get selectLanguage => 'زمان هەڵبژێرە';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get back => 'گەڕانەوە';

  @override
  String get signIn => 'چوونەژوورەوە';

  @override
  String get createAccount => 'دروستکردنی هەژمار';

  @override
  String get signInSubtitle => 'ژمارەی مۆبایل و وشەی نهێنیت بنووسە.';

  @override
  String get registerSubtitle =>
      'بەخێربێیت، جۆری هەژمارەکەت هەڵبژێرە بۆ دەستپێکردن.';

  @override
  String get accountIndividual => 'کەسی ئاسایی';

  @override
  String get accountShowroom => 'پێشانگای ئۆتۆمبێل';

  @override
  String get emailSuperAdmin => 'ئیمەیڵ (بۆ بەڕێوەبەری سەرەکی)';

  @override
  String get emailPlaceholder => 'ئیمەیڵەکەت بنووسە';

  @override
  String get invalidEmail => 'ئیمەیڵ دروست نییە';

  @override
  String get phoneLabel => 'ژمارەی مۆبایل';

  @override
  String get phoneRequired => 'ژمارەی مۆبایل پێویستە';

  @override
  String get phonePlaceholder => '750 000 0000';

  @override
  String get workPhonePlaceholder => '770 000 0000';

  @override
  String get passwordLabel => 'وشەی نهێنی (Password)';

  @override
  String get passwordRequired => 'وشەی نهێنی پێویستە';

  @override
  String get passwordPlaceholder => 'وشەی نهێنییەکەت بنووسە';

  @override
  String get passwordSetPlaceholder => 'وشەی نهێنییەکەت دابنێ';

  @override
  String get passwordMinLength => 'وشەی نهێنی دەبێت لانیکەم ٦ پیت بێت';

  @override
  String get fullName => 'ناوی تەواو';

  @override
  String get fullNameRequired => 'ناوی تەواو پێویستە';

  @override
  String get fullNamePlaceholder => 'ناوی خۆت بنووسە';

  @override
  String get otpRequired => 'کۆدی سەلماندن پێویستە';

  @override
  String get otpInvalid => 'کۆدەکە دروست نییە';

  @override
  String get otpPlaceholder => 'کۆدی سەلماندن';

  @override
  String get sendCode => 'ناردنی کۆد';

  @override
  String get showroomName => 'ناوی پێشانگا';

  @override
  String get showroomNameRequired => 'ناوی پێشانگا پێویستە';

  @override
  String get showroomNamePlaceholder => 'بۆ نموونە: پێشانگای ڤی ئای پی';

  @override
  String get ownerName => 'ناوی خاوەن پێشانگا / بەڕێوەبەر';

  @override
  String get ownerRequired => 'ناوی بەرپرس پێویستە';

  @override
  String get ownerPlaceholder => 'ناوی تەواوی بەرپرسی هەژمارەکە';

  @override
  String get workPhoneLabel => 'ژمارەی مۆبایلی کار';

  @override
  String get cityLocation => 'شار / شوێن';

  @override
  String get selectCityLocation => 'شار / شوێن هەڵبژێرە';

  @override
  String get selectCityRequired => 'شارەکەت هەڵبژێرە';

  @override
  String get selectCityHint => 'شارەکەت هەڵبژێرە...';

  @override
  String get register => 'تۆمارکردن';

  @override
  String get submitShowroomRequest => 'ناردنی داواکاری';

  @override
  String get noAccount => 'هەژمارت نییە؟ ';

  @override
  String get haveAccount => 'پێشتر هەژمارت هەیە؟ ';

  @override
  String get enterPhoneFirst => 'سەرەتا ژمارەی مۆبایل بنووسە';

  @override
  String verificationCodeSent(String phone) {
    return 'کۆدی سەلماندن نێردرا بۆ $phone';
  }

  @override
  String get authInvalidPhone =>
      'ژمارەی مۆبایل دروست نییە. نموونە: 750 000 0000';

  @override
  String get authRegistrationFailed =>
      'تۆمارکردن سەرکەوتوو نەبوو. دووبارە هەوڵ بدەرەوە.';

  @override
  String get authSendCodeFirst => 'سەرەتا کۆدی سەلماندن بنێرە';

  @override
  String get authPhoneAutoVerified => 'ژمارەی مۆبایل بە شێوەی خۆکار سەلماندرا';

  @override
  String get authEmailAlreadyInUse =>
      'ئەم ژمارەی مۆبایلە پێشتر تۆمار کراوە. چوونەژوورەوە هەوڵ بدە.';

  @override
  String get authWeakPassword =>
      'وشەی نهێنی زۆر لاوازە. لانیکەم ٦ پیت بەکاربهێنە.';

  @override
  String get authWrongCredentials => 'ژمارەی مۆبایل یان وشەی نهێنی هەڵەیە.';

  @override
  String get authAccountNotFoundPrompt =>
      'ئەم هەژمارە نەدۆزرایەوە، ئایا دەتەوێت هەژمارێکی نوێ دروست بکەیت؟';

  @override
  String get authCreateNewAccount => 'دروستکردنی هەژمار';

  @override
  String get authTooManyRequests =>
      'هەوڵی زۆر. کەمێک چاوەڕێ بکە و دووبارە هەوڵ بدەرەوە.';

  @override
  String get authDeviceBlocked =>
      'ئەم ئامێرە کاتییان قەدەغە کراوە لە هەوڵی زۆری ناردنی کۆد. چەند کاتژمێرێک چاوەڕێ بکە، وێبگەڕێکی تر تاقی بکەرەوە، یان ژمارەی تاقیکردنەوە 7722141988 بە کۆدی 112233 بەکاربهێنە.';

  @override
  String get authNetworkError =>
      'پەیوەندی ئینتەرنێت نییە. دووبارە هەوڵ بدەرەوە.';

  @override
  String get authGenericError => 'هەڵەیەک ڕوویدا. دووبارە هەوڵ بدەرەوە.';

  @override
  String get authVerificationExpired =>
      'کۆدی سەلماندن بەسەرچوو. کۆدێکی نوێ بنێرە.';

  @override
  String get authCaptchaFailed =>
      'سەلماندنی ئاسایش سەرکەوتوو نەبوو. پەڕەکە نوێ بکەرەوە و دووبارە هەوڵ بدەرەوە.';

  @override
  String get authInvalidAppCredential =>
      'سەلماندنی مۆبایل لەم دۆمەینەدا بەردەست نییە. iqmotors.net یان iqmotors-d588d.web.app بەکاربهێنە، یان دۆمەینەکە لە Firebase Console → Authentication → Settings → Authorized domains زیاد بکە.';

  @override
  String get authBillingRequired =>
      'ناردنی کۆدی SMS پێویستی بە پلانی Blaze هەیە لە Firebase. پەیوەندی بە بەڕێوەبەری ئەپەکە بکە.';

  @override
  String get authPhoneAuthDisabled =>
      'چوونەژوورەوە بە مۆبایل لە Firebase ناچالاکە. دابینکەری Phone لە کۆنسۆڵی Firebase چالاک بکە.';

  @override
  String get cityErbil => 'هەولێر';

  @override
  String get citySulaymaniyah => 'سلێمانی';

  @override
  String get cityBaghdad => 'بەغداد';

  @override
  String get cityDohuk => 'دهۆک';

  @override
  String get cityKirkuk => 'کەرکوک';

  @override
  String get cityMosul => 'موسڵ';

  @override
  String get cityBasra => 'بەسڕا';

  @override
  String get cityMaysan => 'میسان';

  @override
  String get cityNajaf => 'نەجەف';

  @override
  String get cityKarbala => 'کەربەلا';

  @override
  String get cityAnbar => 'ئەنبار';

  @override
  String get citySalahuddin => 'سەلاحەدین';

  @override
  String get cityBabylon => 'بابل';

  @override
  String get cityDiyala => 'دیالە';

  @override
  String get cityWasit => 'واست';

  @override
  String get cityMuthanna => 'موسەنا';

  @override
  String get cityQadisiyyah => 'قادسیە';

  @override
  String get cityHalabja => 'هەڵەبجە';

  @override
  String get cityDhiQar => 'زیقار';

  @override
  String get locationDefaultRegion => 'هەولێر، سلێمانی و ٣ شاری تر';

  @override
  String get locationAllCities => 'هەموو شارەکان';

  @override
  String get locationSearch => 'گەڕان';

  @override
  String get locationApply => 'جێبەجێکردن';

  @override
  String locationTwoCities(String city1, String city2) {
    return '$city1، $city2';
  }

  @override
  String locationCityPlusMore(String city, String count) {
    return '$city +$count';
  }

  @override
  String locationCitiesAndMore(String city1, String city2, String count) {
    return '$city1، $city2 و $count شاری تر';
  }

  @override
  String get selectCity => 'شار هەڵبژێرە';

  @override
  String get advancedSearch => 'گەڕانی تایبەت';

  @override
  String get filterModel => 'مۆدێل';

  @override
  String get filterModelPlaceholder => 'بۆ نموونە: BMW X7';

  @override
  String get filterYear => 'ساڵ';

  @override
  String get filterYearPlaceholder => 'بۆ نموونە: ٢٠٢٤';

  @override
  String get filterMileage => 'ماوەی ڕۆیشتن';

  @override
  String get filterMileagePlaceholder => 'بۆ نموونە: تا ٥٠،٠٠٠ km';

  @override
  String get filterPrice => 'نرخ';

  @override
  String get filterPricePlaceholder => 'بۆ نموونە: تا \$٥٠،٠٠٠';

  @override
  String get filterCondition => 'بارودۆخ';

  @override
  String get filterConditionPlaceholder => 'بۆ نموونە: بەکارهاتوو';

  @override
  String get filterEngineType => 'جۆری بزوێنەر';

  @override
  String get filterEngineTypePlaceholder => 'بۆ نموونە: بەنزین';

  @override
  String get filterAllModels => 'هەموو مۆدێلەکان';

  @override
  String get filterAllYears => 'هەموو ساڵەکان';

  @override
  String get filterAllMileages => 'هەموو ماوەکان';

  @override
  String get filterAllPrices => 'هەموو نرخەکان';

  @override
  String get modelCamry => 'کامری';

  @override
  String get modelLandCruiser => 'لاند کروزەر';

  @override
  String get modelPatrol => 'پاترۆڵ';

  @override
  String get mileage0 => '٠ km';

  @override
  String get mileage10k => 'تا ١٠،٠٠٠ km';

  @override
  String get mileage50k => 'تا ٥٠،٠٠٠ km';

  @override
  String get mileage100k => 'تا ١٠٠،٠٠٠ km';

  @override
  String get mileage100kPlus => '١٠٠،٠٠٠+ km';

  @override
  String get price20k => 'تا \$٢٠،٠٠٠';

  @override
  String get price50k => 'تا \$٥٠،٠٠٠';

  @override
  String get price100k => 'تا \$١٠٠،٠٠٠';

  @override
  String get price100kPlus => '\$١٠٠،٠٠٠+';

  @override
  String get conditionNew => 'نوێ';

  @override
  String get conditionUsed => 'بەکارهاتوو';

  @override
  String get enginePetrol => 'بەنزین';

  @override
  String get engineHybrid => 'هایبرید';

  @override
  String get clearFilters => 'سڕینەوە';

  @override
  String showCarsCount(String count) {
    return 'پیشاندانی $count ئۆتۆمبێل';
  }

  @override
  String get filterTitle => 'جیاکاری';

  @override
  String get filterReset => 'ڕێکخستنەوە';

  @override
  String get filterBrands => 'براندەکان';

  @override
  String get filterTrim => 'خاسڵەت';

  @override
  String get filterFromYear => 'لە ساڵی';

  @override
  String get filterToYear => 'بۆ ساڵی';

  @override
  String get filterMinPrice => 'کەمترین نرخ';

  @override
  String get filterMaxPrice => 'زۆرترین نرخ';

  @override
  String get filterMinMileage => 'کەمترین کیلۆمەتر';

  @override
  String get filterMaxMileage => 'زۆرترین کیلۆمەتر';

  @override
  String get filterPlateCity => 'شاری تابلۆ';

  @override
  String get filterPlateType => 'جۆری تابلۆ';

  @override
  String get filterConditionSection => 'ڕەوش';

  @override
  String get filterAll => 'هەموو';

  @override
  String get filterEngineSize => 'قەبارەی بزوێنەر';

  @override
  String get filterCylinders => 'پستۆن';

  @override
  String get filterImportCountry => 'وڵاتی هاوردە';

  @override
  String get filterColor => 'ڕەنگ';

  @override
  String get filterFuelType => 'سوتەمەنی';

  @override
  String get filterElectric => 'کارەبای';

  @override
  String get filterTransmission => 'گێڕ';

  @override
  String get filterManual => 'دەستی';

  @override
  String get filterSeatMaterial => 'ماددەی کورسییەکان';

  @override
  String get filterSearchModel => 'گەڕان بەدوای مۆدێل';

  @override
  String filterShowResults(String count) {
    return 'دیارخستنی $count ئۆتۆمبێلەکان';
  }

  @override
  String get trimBase => 'ستاندارد';

  @override
  String get trimSport => 'وەرزشی';

  @override
  String get trimLuxury => 'لوکس';

  @override
  String get plateTypePrivate => 'تایبەت';

  @override
  String get plateTypeTemporary => 'کاتی';

  @override
  String get plateTypeCommercial => 'بازرگانی';

  @override
  String get cylinders4 => '٤ پستۆن';

  @override
  String get cylinders6 => '٦ پستۆن';

  @override
  String get cylinders8 => '٨ پستۆن';

  @override
  String get importUae => 'ئیمارات';

  @override
  String get importUsa => 'ئەمریکا';

  @override
  String get importEurope => 'ئەوروپا';

  @override
  String get importGcc => 'GCC';

  @override
  String get importLocal => 'ناوخۆیی';

  @override
  String get seatFabric => 'قوماش';

  @override
  String get seatLeather => 'جلد';

  @override
  String get seatSemiLeather => 'نیو جلد';

  @override
  String get seatAlcantaraLeather => 'شامۆ/جلد';

  @override
  String get seatAlcantara => 'شامۆ';

  @override
  String get brandTitle => 'مارکەی ئۆتۆمبێل';

  @override
  String get brandSearchHint => 'گەڕان بە مارکە...';

  @override
  String get noBrandsFound => 'هیچ مارکەیەک نەدۆزرایەوە';

  @override
  String get specEngine => 'بزوێنەر';

  @override
  String get specMileage => 'ڕۆیشتوو';

  @override
  String get sellerPriceLabel => 'نرخی فرۆشیار:';

  @override
  String get latestBidLabel => 'بەرزترین نرخ:';

  @override
  String get placeYourBid => 'نرخی خۆت دابنێ';

  @override
  String get enterBidAmount => 'نرخی پێشنیارکراوت داخڵ بکە';

  @override
  String get submitBid => 'ناردن';

  @override
  String get bidTooLowError => 'تکایە نرخێکی بەرزتر لە دوایین نرخ داخڵ بکە';

  @override
  String get bidSuccessMessage => 'نرخەکەت بە سەرکەوتوویی دانرا!';

  @override
  String bidOwnerNotification(String amount, String carName) {
    return 'نرخێکی نوێی $amount بۆ $carName پێشنیار کرا';
  }

  @override
  String get specTransmission => 'گێڕ';

  @override
  String get specLocation => 'شوێن';

  @override
  String get carDetailsTitle => 'زانیاری ئۆتۆمبێل';

  @override
  String get description => 'وەسف';

  @override
  String get features => 'تایبەتمەندیەکان';

  @override
  String get technicalDetails => 'وردەکاری تەکنیکی';

  @override
  String get specYear => 'ساڵ';

  @override
  String get specType => 'جۆر';

  @override
  String get specColor => 'ڕەنگ';

  @override
  String get contactSeller => 'پەیوەندی بە فرۆشیار';

  @override
  String get whatsapp => 'واتسئاپ';

  @override
  String get phoneCall => 'پەیوەندی تەلەفۆنی';

  @override
  String get saveToWishlist => 'پاشەکەوتکردن';

  @override
  String get removeFromWishlist => 'لابردن لە دڵخواز';

  @override
  String get sellerDefault => 'فرۆشیار';

  @override
  String get transmissionAutomatic => 'ئۆتۆماتیک';

  @override
  String get dummyCarDescription =>
      'کادیلاک Escalade-V 2024 بە تەواوی نوێ و بە بەرزترین ئاستی VIP. ئۆتۆمبێلەکە بە تەواوی پاکەتە و هیچ ڕۆیشتوویەکی نییە. گونجاوە بۆ بازاڕی کوردستان و عێراق بە پێشانگای پشتڕاستکراو.';

  @override
  String get dummyFeature1 => 'پاکێجی VIP تەواو';

  @override
  String get dummyFeature2 => 'شاشەی OLED 38 ئینچ';

  @override
  String get dummyFeature3 => 'کورسی سەرەکی گەرم و سارد';

  @override
  String get dummyFeature4 => 'سیستەمی دەنگی AKG';

  @override
  String get dummyFeature5 => 'کامێرای 360 پلە';

  @override
  String get dummyFeature6 => 'سقف پانۆراما';

  @override
  String get dummyFeature7 => 'شاشەی پشت بۆ گەشتیاران';

  @override
  String get dummyFeature8 => 'سەرمایەگرتنی سێ ڕیز';

  @override
  String get dummyColorMatteWhite => 'سپی مەت';

  @override
  String get dummySellerName => 'ئارام محەمەد';

  @override
  String get dummySellerShowroom => 'پێشانگای ڤی ئای پی';

  @override
  String get dummySellerListings => '٤٢ ڕیکلامی چالاک';

  @override
  String get superAdminBadge => 'Super Admin';

  @override
  String get superAdminTitle => 'بەڕێوەبەری سەرەکی';

  @override
  String welcomeAdmin(String name) {
    return 'بەخێربێیت، $name';
  }

  @override
  String get adminSubtitle =>
      'پێداچوونەوە بە ڕیکلامە چاوەڕوانەکان و ئامارەکانی پلاتفۆرم.';

  @override
  String get navDashboard => 'داشبۆرد';

  @override
  String get navApprovals => 'پەسەندکردنەکان';

  @override
  String get navUsers => 'بەکارهێنەران';

  @override
  String get navReports => 'ڕاپۆرتەکان';

  @override
  String get navSettings => 'ڕێکخستن';

  @override
  String get statPendingApproval => 'چاوەڕوانی پەسەندکردن';

  @override
  String get statTotalUsers => 'کۆی بەکارهێنەران';

  @override
  String get statActiveListings => 'ڕیکلامی چالاک';

  @override
  String get statRegisteredShowrooms => 'پێشانگای تۆمارکراو';

  @override
  String get pendingListingsTitle => 'ڕیکلامەکانی چاوەڕوان';

  @override
  String get pendingListingsSubtitle =>
      'پێداچوونەوە بکە پێش بڵاوکردنەوە لە ماڵپەڕەکەدا.';

  @override
  String newCount(int count) {
    return '$count نوێ';
  }

  @override
  String get tableCar => 'ئۆتۆمبێل';

  @override
  String get tablePublisher => 'بڵاوکەرەوە';

  @override
  String get tablePrice => 'نرخ';

  @override
  String get tableActions => 'کردارەکان';

  @override
  String get publisherShowroom => 'پێشانگا';

  @override
  String get publisherIndividual => 'کەسی';

  @override
  String get actionView => 'بینین';

  @override
  String get actionReject => 'ڕەتکردنەوە';

  @override
  String get actionApprove => 'پەسەندکردن';

  @override
  String get dummyPublisherVipShowroom => 'پێشانگای ڤی ئای پی';

  @override
  String get dummyPublisherAras => 'ئاراس محەمەد';

  @override
  String get dummyPublisherAlofShowroom => 'پێشانگای ئەلۆف';

  @override
  String get dummyPublisherHiwa => 'هیوا جەمیل';

  @override
  String get userDashboardTitle => 'داشبۆردی بەکارهێنەر';

  @override
  String get navHomeScreen => 'پەڕەی سەرەکی';

  @override
  String get navMyFavorites => 'دڵخوازەکانم';

  @override
  String get navMyAds => 'ڕیکلامەکانم';

  @override
  String get navMessages => 'نامەکان';

  @override
  String get userAccountPersonal => 'هەژماری کەسی';

  @override
  String get favoritesSectionTitle => 'دڵخوازەکانم (سەیڤکراو)';

  @override
  String get homeFeedEmpty => 'لە ئێستادا هیچ ئۆتۆمبێلێک بەردەست نییە';

  @override
  String get homeFeedLoadError =>
      'نەتوانرا ڕیکلامەکان بار بکرێن. تکایە دووبارە هەوڵ بدەرەوە.';

  @override
  String get homeBrowseBrands => 'گەڕان بەپێی براند';

  @override
  String get homeAvailableListings => 'ئۆتۆمبێلە بەردەستەکان';

  @override
  String get favoritesEmpty => 'هیچ ئۆتۆمبێلێکی سەیڤکراو نییە';

  @override
  String get myAdsEmpty => 'هیچ ڕیکلامێکت نییە';

  @override
  String get viewAllListings => 'بینینی هەمووی';

  @override
  String get deleteAdTitle => 'سڕینەوەی ڕیکلام';

  @override
  String get deleteAdConfirm =>
      'ئایا دڵنیایت لە سڕینەوەی ئەم ڕیکلامە؟ ئەم کارە هەڵناوەشێتەوە.';

  @override
  String get cancelAction => 'پاشگەزبوونەوە';

  @override
  String get deleteAction => 'سڕینەوە';

  @override
  String get adDeletedSuccess => 'ڕیکلامەکە بە سەرکەوتوویی سڕایەوە';

  @override
  String get sell => 'فرۆشتن';

  @override
  String get sellCarButton => 'فرۆشتنی ئۆتۆمبێل';

  @override
  String get editAction => 'دەستکاری';

  @override
  String get adStatusActive => 'چالاک';

  @override
  String get adStatusSold => 'فرۆشرا';

  @override
  String get adStatusDraft => 'ڕەشنووس';

  @override
  String get adCompleteDraft => 'تەواوی بکە';

  @override
  String get soldAction => 'فرۆشرا';

  @override
  String get markAsSoldTitle => 'نیشانکردن وەک فرۆشراو';

  @override
  String get markAsSoldConfirm =>
      'ئایا دڵنیایت لە نیشانکردنی ئەم ڕیکلامە وەک فرۆشراو؟ کڕیاران نیشانەی فرۆشراو دەبینن.';

  @override
  String get adMarkedSoldSuccess => 'ڕیکلامەکە وەک فرۆشراو نیشانکرا';

  @override
  String adPostedAt(String date) {
    return 'کاتی دانان: $date';
  }

  @override
  String adDaysRemaining(int days) {
    return 'ماوەی ڕیکلام: $days ڕۆژی ماوە';
  }

  @override
  String get soldBadgeLabel => 'فرۆشرا';

  @override
  String get carSoldNoBids => 'ئەم ئۆتۆمبێلە فرۆشراوە';

  @override
  String get offersAction => 'نرخەکان';

  @override
  String get bidHistoryTitle => 'مێژووی نرخەکان';

  @override
  String get bidHistoryEmpty => 'تا ئێستا هیچ نرخێک دانەنراوە';

  @override
  String get bidHistoryBidderName => 'ناوی کەس';

  @override
  String get bidHistoryBidderPhone => 'ژمارەی مۆبایل';

  @override
  String get bidHistoryAmount => 'بڕی نرخ';

  @override
  String get bidHistoryDate => 'کات و بەروار';

  @override
  String get carFallbackTitle => 'ئۆتۆمبێل';

  @override
  String get messagesEmpty => 'هیچ نامەیەک نییە';

  @override
  String get settingsComingSoon => 'ڕێکخستنەکان بەزووی زیاد دەکرێت';

  @override
  String get adminApprovalsByCitySubtitle =>
      'پێداچوونەوەی ڕیکلامەکان بەپێی پارێزگا';

  @override
  String get adminUsersByCitySubtitle => 'بەکارهێنەران بەپێی پارێزگا';

  @override
  String get adminShowroomsByCitySubtitle => 'پێشانگاکان بەپێی پارێزگا';

  @override
  String get adminStatApproved => 'پەسەندکراو';

  @override
  String get adminStatPendingReview => 'چاوەڕوانکراو';

  @override
  String get adminStatExpired => 'بەسەرچوو';

  @override
  String get adminRetry => 'دووبارە';

  @override
  String get adminNoUsersInCity => 'هیچ بەکارهێنەرێک لەم شارەدا نییە.';

  @override
  String get adminNoShowroomsInCity => 'هیچ پێشانگایەک لەم شارەدا نییە.';

  @override
  String get adminNoPendingListings => 'هیچ ڕیکلامێکی چاوەڕوان نییە.';

  @override
  String get adminSectionComingSoon => 'ئەم بەشە بەمزوانە بەردەست دەبێت.';

  @override
  String get adminAdCountLabel => 'ژمارەی ڕیکلامەکان';

  @override
  String get adminActiveAdCountLabel => 'ڕیکلامی چالاک';

  @override
  String get adminTotalAdCountLabel => 'کۆی ڕیکلامەکان';

  @override
  String get adminUserCountLabel => 'بەکارهێنەر';

  @override
  String get adminShowroomCountLabel => 'پێشانگا';

  @override
  String get adminRejectAdTitle => 'ڕەتکردنەوەی ڕیکلام';

  @override
  String get adminRejectAdConfirm => 'ئایا دڵنیایت لە ڕەتکردنەوەی ئەم ڕیکلامە؟';

  @override
  String get adminAdApprovedSuccess => 'ڕیکلامەکە بە سەرکەوتوویی پەسەندکرا';

  @override
  String get adminAdRejectedSuccess => 'ڕیکلامەکە ڕەتکرایەوە';

  @override
  String get adminDescriptionLabel => 'وەسف';

  @override
  String get adminReportsSubtitle => 'ئامارەکانی پلاتفۆرم و پێشاندانی داهات';

  @override
  String get adminDailyActiveUsers => 'بەکارهێنەری چالاکی ڕۆژانە';

  @override
  String get adminDailyNewAds => 'ڕیکلامی نوێ';

  @override
  String get adminLast30Days => '٣٠ ڕۆژی ڕابردوو';

  @override
  String get adminTotalRevenue => 'کۆی داهات';

  @override
  String get adminRevenueFromBoost => 'لە پاکێجی بووست';

  @override
  String get adminRevenueCard => 'کارتی بانکی';

  @override
  String get adminRevenueEWallet => 'جزدانی ئەلیکترۆنی';

  @override
  String get adminCityPerformance => 'ئەدای شارەکان';

  @override
  String get adminCityColumn => 'شار';

  @override
  String get adminTotalAdsColumn => 'کۆی ڕیکلام';

  @override
  String get adminApprovedAdsColumn => 'پەسەندکراو';

  @override
  String get adminSettingsSubtitle => 'ڕێکخستنی پلاتفۆرم و دەسەڵاتەکان';

  @override
  String get adminSettingsGeneral => 'ڕێکخستنی گشتی';

  @override
  String get adminSettingsPackages => 'نرخی پاکێجەکان';

  @override
  String get adminSettingsCities => 'شار و ناوچەکان';

  @override
  String get adminSettingsSecurity => 'ئاسایش و ئەدمین';

  @override
  String get adminSettingsBoostPrice => 'نرخی پاکێجی بووست (د.ع)';

  @override
  String get adminSettingsSuperBoostPrice => 'نرخی سوپەر بووست (د.ع)';

  @override
  String get adminSettingsSaveChanges => 'پاشەکەوتکردن';

  @override
  String get adminSettingsSavedSuccess =>
      'ڕێکخستنەکان بە سەرکەوتوویی پاشەکەوت کران';

  @override
  String get adminSettingsActiveCities => 'شارە چالاکەکان';

  @override
  String get adminSettingsAddCity => 'زیادکردنی شار';

  @override
  String get adminSettingsNewCityHint => 'ناوی شار';

  @override
  String get adminSettingsAdmins => 'ئەدمینەکانی پلاتفۆرم';

  @override
  String get adminSettingsAddAdmin => 'زیادکردنی ئەدمین';

  @override
  String get adminSettingsAdminEmail => 'ئیمەیڵ';

  @override
  String get adminSettingsAdminPhone => 'ژمارەی مۆبایل';

  @override
  String get adminSettingsAdminName => 'ناو';

  @override
  String get adminSettingsSystemCredentials => 'زانیاری سیستەم';

  @override
  String get adminSettingsR2Endpoint => 'بەستەری R2';

  @override
  String get adminSettingsR2AccessKey => 'کلیلی دەستگەیشتنی R2';

  @override
  String get adminSettingsR2SecretKey => 'کلیلی نهێنی R2';

  @override
  String get adminSettingsR2Bucket => 'ناوی bucket ی R2';

  @override
  String get adminSettingsR2PublicBaseUrl =>
      'بەستەری گشتی R2 (https://pub-xxxx.r2.dev)';

  @override
  String get adminSettingsGeneralInfo => 'زانیاری پلاتفۆرم';

  @override
  String get adminSettingsAppName => 'IQ Motors';

  @override
  String get adminSettingsAppVersion => 'وەشان 1.0.0';

  @override
  String get adminSettingsRemove => 'سڕینەوە';

  @override
  String get adminSettingsAddCityTitle => 'شارێکی نوێ';

  @override
  String get adminSettingsAddAdminTitle => 'ئەدمینی نوێ';

  @override
  String get adminSettingsCredentialsNote =>
      'تەنها بۆ بەڕێوەبەری سەرەکی. لە Firestore system_config هەڵدەگیرێت.';

  @override
  String get navActivity => 'چالاکییەکان';

  @override
  String get adminActivitySubtitle => 'مێژووی کردارەکانی ئەدمین';

  @override
  String get adminActivitySearchHint => 'گەڕان بە ناو یان جۆری کردار';

  @override
  String get adminActivityEmpty => 'هێشتا هیچ چالاکییەک تۆمار نەکراوە.';

  @override
  String get adminActivityNoResults => 'هیچ ئەنجامێک نەدۆزرایەوە.';

  @override
  String get adminActivityPerformedBy => 'لەلایەن';

  @override
  String get adminActivityJustNow => 'ئێستا';

  @override
  String adminActivityMinutesAgo(int count) {
    return '$count خولەک پێش ئێستا';
  }

  @override
  String adminActivityHoursAgo(int count) {
    return '$count کاتژمێر پێش ئێستا';
  }

  @override
  String adminActivityDaysAgo(int count) {
    return '$count ڕۆژ پێش ئێستا';
  }

  @override
  String get adminActivityActionApproved => 'پەسەندکردنی ڕیکلام';

  @override
  String get adminActivityActionRejected => 'ڕەتکردنەوەی ڕیکلام';

  @override
  String get adminActivityActionDeleted => 'سڕینەوەی ڕیکلام';

  @override
  String get adminActivityActionUpdatedPrice => 'نوێکردنەوەی نرخی پاکێج';

  @override
  String get adminActivityActionUpdatedConfig => 'نوێکردنەوەی ڕێکخستن';

  @override
  String get adminActivityActionAddedCity => 'زیادکردنی شار';

  @override
  String get adminActivityActionRemovedCity => 'سڕینەوەی شار';

  @override
  String get adminActivityActionAddedAdmin => 'زیادکردنی ئەدمین';

  @override
  String get adminActivityActionUpdatedCredentials =>
      'نوێکردنەوەی زانیاری سیستەم';

  @override
  String get adminMessagesTitle => 'نامەکان و سکاڵاکان';

  @override
  String get adminMessagesSubtitle => 'پەیوەندی بەکارهێنەران و پشتگیری';

  @override
  String get adminMessagesFilterAll => 'هەموو';

  @override
  String get adminMessagesFilterOpen => 'کراوە';

  @override
  String get adminMessagesFilterResolved => 'چارەسەرکراو';

  @override
  String get adminMessagesStatusOpen => 'کراوە';

  @override
  String get adminMessagesStatusResolved => 'چارەسەرکراو';

  @override
  String get adminMessagesSend => 'ارسال';

  @override
  String get adminMessagesSelectTicket => 'سکاڵایەک هەڵبژێرە بۆ بینینی گفتوگۆ';

  @override
  String get adminMessagesResolve => 'نیشانکردن وەک چارەسەرکراو';

  @override
  String get adminMessagesReopen => 'دووبارە کردنەوە';

  @override
  String get adminMessagesReplyHint => 'وەڵام بنووسە…';

  @override
  String get adminMessagesBackToList => 'گەڕانەوە بۆ لیست';

  @override
  String get navFlaggedAds => 'ڕاپۆرتە پێشێلکارییەکان';

  @override
  String get adminFlaggedSubtitle => 'ڕیکلامە ڕاپۆرتکراوەکان پێداچوونەوە بکە';

  @override
  String get adminFlaggedReasonLabel => 'هۆکار';

  @override
  String get adminFlaggedReportedByLabel => 'ڕاپۆرتکراو لەلایەن';

  @override
  String get adminFlaggedViewAd => 'بینینی ڕیکلام';

  @override
  String get adminFlaggedDeleteAd => 'سڕینەوەی ڕیکلام';

  @override
  String get adminFlaggedIgnore => 'پشتگوێخستن';

  @override
  String get adminFlaggedEmpty => 'هیچ ڕاپۆرتێکی چاوەڕوان نییە.';

  @override
  String get adminFlaggedDeleteConfirm =>
      'ئایا دڵنیایت لە سڕینەوەی ئەم ڕیکلامە؟';

  @override
  String get adminFlaggedDeleteSuccess =>
      'ڕیکلامەکە سڕایەوە و ڕاپۆرتەکە چارەسەرکرا.';

  @override
  String get adminFlaggedIgnoredSuccess => 'ڕاپۆرتەکە پشتگوێخرا.';

  @override
  String get adminFlaggedAdMissing => 'ڕیکلامەکە بەردەست نییە';

  @override
  String get flaggedReasonSold => 'سەیارەکە فرۆشراوە';

  @override
  String get flaggedReasonWrongPrice => 'نرخی هەڵەیە';

  @override
  String get flaggedReasonMisleading => 'زانیاری هەڵە';

  @override
  String get flaggedReasonSpam => 'سپام';

  @override
  String get next => 'دواتر';

  @override
  String addCarStepProgress(int current, int total) {
    return 'هەنگاوی $current لە $total';
  }

  @override
  String get addCarPublish => 'بڵاوکردنەوە';

  @override
  String get addCarExit => 'دەرچوون';

  @override
  String get addCarSave => 'پاشەکەوتکردن';

  @override
  String get addCarPublishing => 'خەریکی بڵاوکردنەوە...';

  @override
  String get addCarSaving => 'خەریکی پاشەکەوتکردن...';

  @override
  String get addCarPhotoProcessing => 'پشکنینی وێنە...';

  @override
  String get addCarMinPhotosRequired => 'تکایە لانیکەم ٤ وێنە هەڵبژێرە.';

  @override
  String get addCarUploadFailed => 'بارکردنی وێنەکان سەرکەوتوو نەبوو.';

  @override
  String get addCarSaveSuccess => 'گۆڕانکارییەکان بە سەرکەوتوویی پاشەکەوتکران';

  @override
  String get addCarDraftSavedSuccess =>
      'پێشکەوتن پاشەکەوتکرا. لە ڕیکلامەکانمدا دەتوانیت دواتر بەردەوام بیت.';

  @override
  String get addCarDraftEmpty =>
      'تکایە پێش پاشەکەوتکردن هەندێک وردەکاری زیاد بکە.';

  @override
  String get addCarPublishSuccess => 'ڕاگەیاندنەکەت بە سەرکەوتوویی بڵاوکرایەوە';

  @override
  String get addCarSaveFailed =>
      'پاشەکەوتکردن سەرکەوتوو نەبوو. دووبارە هەوڵ بدەرەوە.';

  @override
  String get addCarPublishFailed =>
      'بڵاوکردنەوە سەرکەوتوو نەبوو. دووبارە هەوڵ بدەرەوە.';

  @override
  String get addCarPhotoCheckFailed =>
      'پشکنینی وێنە سەرکەوتوو نەبوو. دووبارە هەوڵ بدەرەوە.';

  @override
  String get addCarStepLocationTitle => 'شوێن';

  @override
  String get addCarStepPhotosTitle => 'وێنەکان';

  @override
  String get addCarStepInfoTitle => 'زانیاری';

  @override
  String get addCarStepPlateTitle => 'تابلۆ';

  @override
  String get addCarStepDetailsTitle => 'وردەکاری';

  @override
  String get addCarStepTechnicalTitle => 'تەکنیکی';

  @override
  String get addCarStepInteriorTitle => 'ناوەوە';

  @override
  String get addCarStepConditionTitle => 'دۆخ';

  @override
  String get addCarStepPriceTitle => 'نرخ';

  @override
  String get addCarStepReviewTitle => 'پێداچوونەوە';

  @override
  String get addCarStepListingTitle => 'بڵاوکردنەوە';

  @override
  String get addCarStepPaymentTitle => 'پارەدان';

  @override
  String get addCarLocationHeading => 'ئۆتۆمبێلەکەت لە چ شوێنێکە؟';

  @override
  String get addCarLocationSubtitle => 'پارێزگا / ناوچە دیاری بکە';

  @override
  String get addCarProvinceLabel => 'پارێزگا';

  @override
  String get addCarProvincePlaceholder => 'پارێزگا هەڵبژێرە';

  @override
  String get addCarAreaLabel => 'ناوچە / شار';

  @override
  String get addCarAreaPlaceholder => 'ناوچە هەڵبژێرە';

  @override
  String get addCarPhotosHeading => 'وێنەکان بگرە';

  @override
  String get addCarPhotosSubtitle =>
      'بە لایەنی کەمەوە ٤ وێنەی ئۆتۆمبێلەکەت بگرە';

  @override
  String get addCarPhotoPrimary => 'سەرەکی';

  @override
  String get addCarBasicInfoHeading => 'زانیاری سەرەتایی ئۆتۆمبێل';

  @override
  String get addCarBasicInfoSubtitle =>
      'ئەو زانیارییانە هەڵبژێرە کە لەگەڵ ئۆتۆمبێلەکەت دەگونجێت';

  @override
  String get addCarBrandLabel => 'براند';

  @override
  String get addCarBrandPlaceholder => 'براند هەڵبژێرە';

  @override
  String get addCarModelLabel => 'مۆدێل';

  @override
  String get addCarModelPlaceholder => 'مۆدێل هەڵبژێرە';

  @override
  String get addCarColorLabel => 'ڕەنگ';

  @override
  String get addCarColorPlaceholder => 'ڕەنگ هەڵبژێرە';

  @override
  String get addCarYearLabel => 'ساڵی مۆدێل';

  @override
  String get addCarYearPlaceholder => 'ساڵ هەڵبژێرە';

  @override
  String get addCarTrimLabel => 'خاسڵەت';

  @override
  String get addCarTrimPlaceholder => 'خاسڵەت هەڵبژێرە';
}
