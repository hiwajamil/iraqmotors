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
  String get phonePlaceholder => '0750 000 0000';

  @override
  String get workPhonePlaceholder => '0770 000 0000';

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
      'ژمارەی مۆبایل دروست نییە. نموونە: 0750 000 0000';

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
  String get authTooManyRequests =>
      'هەوڵی زۆر. کەمێک چاوەڕێ بکە و دووبارە هەوڵ بدەرەوە.';

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
  String locationCitiesAndMore(String city1, String city2, String count) {
    return '$city1، $city2 و $count شاری تر';
  }

  @override
  String get selectCity => 'شار هەڵبژێرە';

  @override
  String get advancedSearch => 'گەڕانی پێشکەوتوو';

  @override
  String get filterModel => 'مۆدێل';

  @override
  String get filterYear => 'ساڵ';

  @override
  String get filterMileage => 'ماوەی ڕۆیشتن';

  @override
  String get filterPrice => 'نرخ';

  @override
  String get filterCondition => 'بارودۆخ';

  @override
  String get filterEngineType => 'جۆری بزوێنەر';

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
}
