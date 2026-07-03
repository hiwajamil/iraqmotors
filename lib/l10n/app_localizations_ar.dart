// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'IQ Motors';

  @override
  String get myAccount => 'حسابي';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get navAllModels => 'جميع الموديلات';

  @override
  String get navTuning => 'التعديل والضبط';

  @override
  String get navShowrooms => 'المعارض';

  @override
  String get heroTitle => 'القوة ببساطة.';

  @override
  String get heroSubtitle => 'تجربة جديدة لاكتشاف السيارات الفاخرة.';

  @override
  String get viewAll => 'الكل';

  @override
  String get footerCopyright => '© 2026 IQ Motors. جميع الحقوق محفوظة.';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get back => 'رجوع';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get signInSubtitle => 'أدخل رقم هاتفك وكلمة المرور.';

  @override
  String get registerSubtitle => 'مرحباً، اختر نوع حسابك للبدء.';

  @override
  String get accountIndividual => 'فرد';

  @override
  String get accountShowroom => 'معرض سيارات';

  @override
  String get emailSuperAdmin => 'البريد الإلكتروني (للمشرف العام)';

  @override
  String get emailPlaceholder => 'أدخل بريدك الإلكتروني';

  @override
  String get invalidEmail => 'البريد الإلكتروني غير صالح';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get phonePlaceholder => '750 000 0000';

  @override
  String get workPhonePlaceholder => '770 000 0000';

  @override
  String get passwordLabel => 'كلمة المرور (Password)';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordPlaceholder => 'أدخل كلمة المرور';

  @override
  String get passwordSetPlaceholder => 'عيّن كلمة المرور';

  @override
  String get passwordMinLength => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get fullNamePlaceholder => 'أدخل اسمك';

  @override
  String get otpRequired => 'رمز التحقق مطلوب';

  @override
  String get otpInvalid => 'رمز التحقق غير صالح';

  @override
  String get otpPlaceholder => 'رمز التحقق';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get showroomName => 'اسم المعرض';

  @override
  String get showroomNameRequired => 'اسم المعرض مطلوب';

  @override
  String get showroomNamePlaceholder => 'مثال: معرض VIP';

  @override
  String get ownerName => 'اسم المالك / المدير';

  @override
  String get ownerRequired => 'اسم المسؤول مطلوب';

  @override
  String get ownerPlaceholder => 'الاسم الكامل لمسؤول الحساب';

  @override
  String get workPhoneLabel => 'هاتف العمل';

  @override
  String get cityLocation => 'المدينة / الموقع';

  @override
  String get selectCityLocation => 'اختر المدينة / الموقع';

  @override
  String get selectCityRequired => 'اختر مدينتك';

  @override
  String get selectCityHint => 'اختر مدينتك...';

  @override
  String get register => 'التسجيل';

  @override
  String get submitShowroomRequest => 'إرسال الطلب';

  @override
  String get noAccount => 'ليس لديك حساب؟ ';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get enterPhoneFirst => 'أدخل رقم الهاتف أولاً';

  @override
  String verificationCodeSent(String phone) {
    return 'تم إرسال رمز التحقق إلى $phone';
  }

  @override
  String get authInvalidPhone => 'رقم الهاتف غير صالح. مثال: 750 000 0000';

  @override
  String get authRegistrationFailed => 'فشل التسجيل. يرجى المحاولة مرة أخرى.';

  @override
  String get authSendCodeFirst => 'أرسل رمز التحقق أولاً';

  @override
  String get authPhoneAutoVerified => 'تم التحقق من رقم الهاتف تلقائياً';

  @override
  String get authEmailAlreadyInUse =>
      'رقم الهاتف مسجل مسبقاً. جرّب تسجيل الدخول.';

  @override
  String get authWeakPassword => 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.';

  @override
  String get authWrongCredentials => 'رقم الهاتف أو كلمة المرور غير صحيحة.';

  @override
  String get authAccountNotFoundPrompt =>
      'لم يتم العثور على هذا الحساب. هل تريد إنشاء حساب جديد؟';

  @override
  String get authCreateNewAccount => 'إنشاء حساب';

  @override
  String get authTooManyRequests =>
      'محاولات كثيرة. انتظر قليلاً وحاول مرة أخرى.';

  @override
  String get authDeviceBlocked =>
      'تم حظر هذا الجهاز مؤقتاً بسبب محاولات تحقق كثيرة. انتظر بضع ساعات، جرّب متصفحاً آخر، أو استخدم رقم الاختبار 7722141988 بالرمز 112233.';

  @override
  String get authNetworkError => 'لا يوجد اتصال بالإنترنت. حاول مرة أخرى.';

  @override
  String get authGenericError => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get authVerificationExpired =>
      'انتهت صلاحية رمز التحقق. أرسل رمزاً جديداً.';

  @override
  String get authCaptchaFailed =>
      'فشل التحقق الأمني. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get authInvalidAppCredential =>
      'التحقق من الهاتف غير متاح على هذا النطاق. استخدم iqmotors.net أو iqmotors-d588d.web.app، أو أضف النطاق في Firebase Console → Authentication → Settings → Authorized domains.';

  @override
  String get authBillingRequired =>
      'يتطلب إرسال رمز SMS خطة Blaze في Firebase. تواصل مع مسؤول التطبيق.';

  @override
  String get authPhoneAuthDisabled =>
      'تسجيل الدخول بالهاتف معطّل في Firebase. فعّل مزود Phone في لوحة Firebase.';

  @override
  String get cityErbil => 'أربيل';

  @override
  String get citySulaymaniyah => 'السليمانية';

  @override
  String get cityBaghdad => 'بغداد';

  @override
  String get cityDohuk => 'دهوك';

  @override
  String get cityKirkuk => 'كركوك';

  @override
  String get cityMosul => 'الموصل';

  @override
  String get cityBasra => 'البصرة';

  @override
  String get cityMaysan => 'ميسان';

  @override
  String get cityNajaf => 'النجف';

  @override
  String get cityKarbala => 'كربلاء';

  @override
  String get cityAnbar => 'الأنبار';

  @override
  String get citySalahuddin => 'صلاح الدين';

  @override
  String get cityBabylon => 'بابل';

  @override
  String get cityDiyala => 'ديالى';

  @override
  String get cityWasit => 'واسط';

  @override
  String get cityMuthanna => 'المثنى';

  @override
  String get cityQadisiyyah => 'القادسية';

  @override
  String get cityHalabja => 'حلبجة';

  @override
  String get cityDhiQar => 'ذي قار';

  @override
  String get locationDefaultRegion => 'أربيل، السليمانية و3 مدن أخرى';

  @override
  String get locationAllCities => 'جميع المدن';

  @override
  String get locationSearch => 'بحث';

  @override
  String get locationApply => 'تطبيق';

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
    return '$city1، $city2 و$count مدن أخرى';
  }

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get advancedSearch => 'بحث متقدم';

  @override
  String get filterModel => 'الموديل';

  @override
  String get filterModelPlaceholder => 'مثال: BMW X7';

  @override
  String get filterYear => 'السنة';

  @override
  String get filterYearPlaceholder => 'مثال: ٢٠٢٤';

  @override
  String get filterMileage => 'المسافة المقطوعة';

  @override
  String get filterMileagePlaceholder => 'مثال: حتى ٥٠،٠٠٠ km';

  @override
  String get filterPrice => 'السعر';

  @override
  String get filterPricePlaceholder => 'مثال: حتى \$٥٠،٠٠٠';

  @override
  String get filterCondition => 'الحالة';

  @override
  String get filterConditionPlaceholder => 'مثال: مستعملة';

  @override
  String get filterEngineType => 'نوع المحرك';

  @override
  String get filterEngineTypePlaceholder => 'مثال: بنزين';

  @override
  String get filterAllModels => 'جميع الموديلات';

  @override
  String get filterAllYears => 'جميع السنوات';

  @override
  String get filterAllMileages => 'جميع المسافات';

  @override
  String get filterAllPrices => 'جميع الأسعار';

  @override
  String get modelCamry => 'كامري';

  @override
  String get modelLandCruiser => 'لاند كروزر';

  @override
  String get modelPatrol => 'باترول';

  @override
  String get mileage0 => '0 km';

  @override
  String get mileage10k => 'حتى 10,000 km';

  @override
  String get mileage50k => 'حتى 50,000 km';

  @override
  String get mileage100k => 'حتى 100,000 km';

  @override
  String get mileage100kPlus => '100,000+ km';

  @override
  String get price20k => 'حتى \$20,000';

  @override
  String get price50k => 'حتى \$50,000';

  @override
  String get price100k => 'حتى \$100,000';

  @override
  String get price100kPlus => '\$100,000+';

  @override
  String get conditionNew => 'جديد';

  @override
  String get conditionUsed => 'مستعمل';

  @override
  String get enginePetrol => 'بنزين';

  @override
  String get engineHybrid => 'هجين';

  @override
  String get clearFilters => 'مسح';

  @override
  String showCarsCount(String count) {
    return 'عرض $count سيارة';
  }

  @override
  String get filterTitle => 'تصفية';

  @override
  String get filterReset => 'إعادة تعيين';

  @override
  String get filterBrands => 'العلامات التجارية';

  @override
  String get filterTrim => 'الفئة';

  @override
  String get filterFromYear => 'من سنة';

  @override
  String get filterToYear => 'إلى سنة';

  @override
  String get filterMinPrice => 'أقل سعر';

  @override
  String get filterMaxPrice => 'أعلى سعر';

  @override
  String get filterMinMileage => 'أقل مسافة';

  @override
  String get filterMaxMileage => 'أعلى مسافة';

  @override
  String get filterPlateCity => 'مدينة اللوحة';

  @override
  String get filterPlateType => 'نوع اللوحة';

  @override
  String get filterConditionSection => 'الحالة';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterEngineSize => 'حجم المحرك';

  @override
  String get filterCylinders => 'الأسطوانات';

  @override
  String get filterImportCountry => 'بلد الاستيراد';

  @override
  String get filterColor => 'اللون';

  @override
  String get filterFuelType => 'نوع الوقود';

  @override
  String get filterElectric => 'كهربائي';

  @override
  String get filterTransmission => 'ناقل الحركة';

  @override
  String get filterManual => 'يدوي';

  @override
  String get filterSeatMaterial => 'مادة المقاعد';

  @override
  String get filterSearchModel => 'البحث عن موديل';

  @override
  String filterShowResults(String count) {
    return 'عرض $count سيارة';
  }

  @override
  String get trimBase => 'ستاندارد';

  @override
  String get trimSport => 'رياضي';

  @override
  String get trimLuxury => 'فاخر';

  @override
  String get plateTypePrivate => 'خاص';

  @override
  String get plateTypeTemporary => 'مؤقت';

  @override
  String get plateTypeCommercial => 'تجاري';

  @override
  String get cylinders4 => '4 أسطوانات';

  @override
  String get cylinders6 => '6 أسطوانات';

  @override
  String get cylinders8 => '8 أسطوانات';

  @override
  String get importUae => 'الإمارات';

  @override
  String get importUsa => 'أمريكا';

  @override
  String get importEurope => 'أوروبا';

  @override
  String get importGcc => 'GCC';

  @override
  String get importLocal => 'محلي';

  @override
  String get seatFabric => 'قماش';

  @override
  String get seatLeather => 'جلد';

  @override
  String get seatSemiLeather => 'نصف جلد';

  @override
  String get seatAlcantaraLeather => 'ألكانتara/جلد';

  @override
  String get seatAlcantara => 'ألكانتara';

  @override
  String get brandTitle => 'ماركة السيارة';

  @override
  String get brandSearchHint => 'البحث عن ماركة...';

  @override
  String get noBrandsFound => 'لم يتم العثور على ماركات';

  @override
  String get specEngine => 'المحرك';

  @override
  String get specMileage => 'المسافة';

  @override
  String get sellerPriceLabel => 'سعر البائع:';

  @override
  String get latestBidLabel => 'أعلى عرض:';

  @override
  String get placeYourBid => 'قدّم عرضك';

  @override
  String get enterBidAmount => 'أدخل مبلغ عرضك';

  @override
  String get submitBid => 'إرسال';

  @override
  String get bidTooLowError => 'يرجى إدخال مبلغ أعلى من آخر عرض';

  @override
  String get bidSuccessMessage => 'تم تقديم عرضك بنجاح!';

  @override
  String bidOwnerNotification(String amount, String carName) {
    return 'تم تقديم سعر جديد بقيمة $amount على $carName';
  }

  @override
  String get specTransmission => 'ناقل الحركة';

  @override
  String get specLocation => 'الموقع';

  @override
  String get carDetailsTitle => 'تفاصيل السيارة';

  @override
  String get description => 'الوصف';

  @override
  String get features => 'المميزات';

  @override
  String get technicalDetails => 'المواصفات التقنية';

  @override
  String get specYear => 'السنة';

  @override
  String get specType => 'النوع';

  @override
  String get specColor => 'اللون';

  @override
  String get contactSeller => 'التواصل مع البائع';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get phoneCall => 'اتصال هاتفي';

  @override
  String get saveToWishlist => 'حفظ';

  @override
  String get removeFromWishlist => 'إزالة من المفضلة';

  @override
  String get sellerDefault => 'البائع';

  @override
  String get transmissionAutomatic => 'أوتوماتيك';

  @override
  String get dummyCarDescription =>
      'كادillac Escalade-V 2024 جديدة بالكامل وبأعلى مستوى VIP. السيارة في حالة ممتازة بدون أي مسافة مقطوعة. مناسبة لسوق كردستان والعراق مع معرض موثق.';

  @override
  String get dummyFeature1 => 'باقة VIP كاملة';

  @override
  String get dummyFeature2 => 'شاشة OLED 38 بوصة';

  @override
  String get dummyFeature3 => 'مقعد أمامي مدفأ ومبرد';

  @override
  String get dummyFeature4 => 'نظام صوت AKG';

  @override
  String get dummyFeature5 => 'كاميرا 360 درجة';

  @override
  String get dummyFeature6 => 'سقف بانورامي';

  @override
  String get dummyFeature7 => 'شاشة خلفية للركاب';

  @override
  String get dummyFeature8 => 'تدفئة ثلاثية الصفوف';

  @override
  String get dummyColorMatteWhite => 'أبيض مطفي';

  @override
  String get dummySellerName => 'آرام محمد';

  @override
  String get dummySellerShowroom => 'معرض VIP';

  @override
  String get dummySellerListings => '42 إعلان نشط';

  @override
  String get superAdminBadge => 'Super Admin';

  @override
  String get superAdminTitle => 'المشرف العام';

  @override
  String welcomeAdmin(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get adminSubtitle => 'راجع الإعلانات المعلقة وإحصائيات المنصة.';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navApprovals => 'الموافقات';

  @override
  String get navUsers => 'المستخدمون';

  @override
  String get navReports => 'التقارير';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get statPendingApproval => 'في انتظار الموافقة';

  @override
  String get statTotalUsers => 'إجمالي المستخدمين';

  @override
  String get statActiveListings => 'إعلانات نشطة';

  @override
  String get statRegisteredShowrooms => 'معارض مسجلة';

  @override
  String get pendingListingsTitle => 'الإعلانات المعلقة';

  @override
  String get pendingListingsSubtitle => 'راجع قبل النشر على الموقع.';

  @override
  String newCount(int count) {
    return '$count جديد';
  }

  @override
  String get tableCar => 'السيارة';

  @override
  String get tablePublisher => 'الناشر';

  @override
  String get tablePrice => 'السعر';

  @override
  String get tableActions => 'الإجراءات';

  @override
  String get publisherShowroom => 'معرض';

  @override
  String get publisherIndividual => 'فرد';

  @override
  String get actionView => 'عرض';

  @override
  String get actionReject => 'رفض';

  @override
  String get actionApprove => 'موافقة';

  @override
  String get dummyPublisherVipShowroom => 'معرض VIP';

  @override
  String get dummyPublisherAras => 'آراس محمد';

  @override
  String get dummyPublisherAlofShowroom => 'معرض Alof';

  @override
  String get dummyPublisherHiwa => 'Hiwa Jamil';

  @override
  String get userDashboardTitle => 'لوحة المستخدم';

  @override
  String get navHomeScreen => 'الصفحة الرئيسية';

  @override
  String get navMyFavorites => 'مفضلتي';

  @override
  String get navMyAds => 'إعلاناتي';

  @override
  String get navMessages => 'الرسائل';

  @override
  String get userAccountPersonal => 'حساب شخصي';

  @override
  String get favoritesSectionTitle => 'مفضلتي (محفوظة)';

  @override
  String get homeFeedEmpty => 'لا توجد سيارات متاحة في الوقت الحالي';

  @override
  String get homeFeedLoadError =>
      'تعذر تحميل الإعلانات. يرجى المحاولة مرة أخرى.';

  @override
  String get homeBrowseBrands => 'تصفح حسب العلامة التجارية';

  @override
  String get homeAvailableListings => 'السيارات المتاحة';

  @override
  String get homeRecommendedForYou => 'موصى به لك';

  @override
  String get homeTrendingCars => 'السيارات الرائجة';

  @override
  String get favoritesEmpty => 'لا توجد سيارات محفوظة';

  @override
  String get myAdsEmpty => 'ليس لديك إعلانات';

  @override
  String get viewAllListings => 'عرض الكل';

  @override
  String get deleteAdTitle => 'حذف الإعلان';

  @override
  String get deleteAdConfirm =>
      'هل أنت متأكد من حذف هذا الإعلان؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancelAction => 'إلغاء';

  @override
  String get deleteAction => 'حذف';

  @override
  String get adDeletedSuccess => 'تم حذف الإعلان بنجاح';

  @override
  String get sell => 'بيع';

  @override
  String get sellCarButton => 'بيع سيارة';

  @override
  String get editAction => 'تعديل';

  @override
  String get adStatusActive => 'نشط';

  @override
  String get adStatusInactive => 'غير نشط';

  @override
  String get adStatusSold => 'مباع';

  @override
  String get adStatusDraft => 'مسودة';

  @override
  String get adCompleteDraft => 'أكمله';

  @override
  String get soldAction => 'مباع';

  @override
  String get markAsSoldTitle => 'تحديد كمباع';

  @override
  String get markAsSoldConfirm =>
      'هل تريد تحديد هذا الإعلان كمباع؟ سيرى المشترون شارة مباع على الإعلان.';

  @override
  String get adMarkedSoldSuccess => 'تم تحديد الإعلان كمباع';

  @override
  String adPostedAt(String date) {
    return 'تاريخ النشر: $date';
  }

  @override
  String adDaysRemaining(int days) {
    return 'مدة الإعلان: $days يوم متبقي';
  }

  @override
  String get soldBadgeLabel => 'مباع';

  @override
  String get carSoldNoBids => 'تم بيع هذه السيارة';

  @override
  String get offersAction => 'العروض';

  @override
  String get bidHistoryTitle => 'سجل العروض';

  @override
  String get bidHistoryEmpty => 'لم يتم تقديم أي عروض بعد';

  @override
  String get bidHistoryBidderName => 'اسم المزايد';

  @override
  String get bidHistoryBidderPhone => 'رقم الهاتف';

  @override
  String get bidHistoryAmount => 'مبلغ العرض';

  @override
  String get bidHistoryDate => 'التاريخ والوقت';

  @override
  String get carFallbackTitle => 'مركبة';

  @override
  String get messagesEmpty => 'لا توجد رسائل';

  @override
  String get settingsComingSoon => 'الإعدادات قريباً';

  @override
  String get adminApprovalsByCitySubtitle =>
      'نظرة عامة على الإعلانات حسب المحافظة';

  @override
  String get adminUsersByCitySubtitle => 'المستخدمون حسب المحافظة';

  @override
  String get adminShowroomsByCitySubtitle => 'المعارض حسب المحافظة';

  @override
  String get adminStatApproved => 'موافق عليه';

  @override
  String get adminStatPendingReview => 'قيد المراجعة';

  @override
  String get adminStatExpired => 'منتهي';

  @override
  String get adminRetry => 'إعادة المحاولة';

  @override
  String get adminNoUsersInCity => 'لا يوجد مستخدمون في هذه المدينة.';

  @override
  String get adminNoShowroomsInCity => 'لا توجد معارض في هذه المدينة.';

  @override
  String get adminNoPendingListings => 'لا توجد إعلانات قيد المراجعة.';

  @override
  String get adminSectionComingSoon => 'هذا القسم قريباً.';

  @override
  String get adminAdCountLabel => 'عدد الإعلانات';

  @override
  String get adminActiveAdCountLabel => 'إعلانات نشطة';

  @override
  String get adminTotalAdCountLabel => 'إجمالي الإعلانات';

  @override
  String get adminUserCountLabel => 'مستخدم';

  @override
  String get adminShowroomCountLabel => 'معرض';

  @override
  String get adminRejectAdTitle => 'رفض الإعلان';

  @override
  String get adminRejectAdConfirm => 'هل أنت متأكد من رفض هذا الإعلان؟';

  @override
  String get adminAdApprovedSuccess => 'تمت الموافقة على الإعلان بنجاح';

  @override
  String get adminAdRejectedSuccess => 'تم رفض الإعلان';

  @override
  String get adminDescriptionLabel => 'الوصف';

  @override
  String get adminReportsSubtitle => 'تحليلات المنصة ونظرة عامة على الإيرادات';

  @override
  String get adminDailyActiveUsers => 'المستخدمون النشطون يومياً';

  @override
  String get adminDailyNewAds => 'إعلانات جديدة';

  @override
  String get adminLast30Days => 'آخر 30 يوماً';

  @override
  String get adminTotalRevenue => 'إجمالي الإيرادات';

  @override
  String get adminRevenueFromBoost => 'من باقات التعزيز';

  @override
  String get adminRevenueCard => 'بطاقة';

  @override
  String get adminRevenueEWallet => 'محفظة إلكترونية';

  @override
  String get adminCityPerformance => 'أداء المدن';

  @override
  String get adminCityColumn => 'المدينة';

  @override
  String get adminTotalAdsColumn => 'إجمالي الإعلانات';

  @override
  String get adminApprovedAdsColumn => 'موافق عليه';

  @override
  String get adminDateRangeLabel => 'نطاق التاريخ';

  @override
  String get adminTodaysActiveUsers => 'المستخدمون النشطون اليوم';

  @override
  String get adminTotalAppDownloads => 'إجمالي تنزيلات التطبيق';

  @override
  String get adminVisitorTraffic => 'حركة الزوار';

  @override
  String get adminCityMetricAds => 'إعلانات';

  @override
  String get adminCityMetricVisitors => 'زوار';

  @override
  String get adminGenerateReport => 'إنشاء التقرير';

  @override
  String get adminReportsEmptyHint =>
      'حدد نطاق التاريخ واضغط على إنشاء التقرير لعرض التحليلات.';

  @override
  String get adminSettingsSubtitle => 'إدارة إعدادات المنصة والوصول';

  @override
  String get adminSettingsGeneral => 'الإعدادات العامة';

  @override
  String get adminSettingsPackages => 'أسعار الباقات';

  @override
  String get adminSettingsCities => 'المدن والمناطق';

  @override
  String get adminSettingsSecurity => 'الأمان والمشرفون';

  @override
  String get adminSettingsBoostPrice => 'سعر باقة Boost (د.ع)';

  @override
  String get adminSettingsSuperBoostPrice => 'سعر Super Boost (د.ع)';

  @override
  String get adminSettingsSaveChanges => 'حفظ التغييرات';

  @override
  String get adminSettingsSavedSuccess => 'تم حفظ الإعدادات بنجاح';

  @override
  String get adminSettingsActiveCities => 'المدن النشطة';

  @override
  String get adminSettingsAddCity => 'إضافة مدينة';

  @override
  String get adminSettingsNewCityHint => 'اسم المدينة';

  @override
  String get adminSettingsAdmins => 'مشرفو المنصة';

  @override
  String get adminSettingsAddAdmin => 'إضافة مشرف';

  @override
  String get adminSettingsAdminEmail => 'البريد الإلكتروني';

  @override
  String get adminSettingsAdminPhone => 'الهاتف';

  @override
  String get adminSettingsAdminName => 'الاسم';

  @override
  String get adminSettingsSystemCredentials => 'بيانات اعتماد النظام';

  @override
  String get adminSettingsR2Endpoint => 'رابط R2';

  @override
  String get adminSettingsR2AccessKey => 'مفتاح وصول R2';

  @override
  String get adminSettingsR2SecretKey => 'المفتاح السري R2';

  @override
  String get adminSettingsR2Bucket => 'اسم bucket R2';

  @override
  String get adminSettingsR2PublicBaseUrl =>
      'رابط R2 العام (https://pub-xxxx.r2.dev)';

  @override
  String get adminSettingsGeneralInfo => 'معلومات المنصة';

  @override
  String get adminSettingsAppName => 'IQ Motors';

  @override
  String get adminSettingsAppVersion => 'الإصدار 1.0.0';

  @override
  String get adminSettingsRemove => 'إزالة';

  @override
  String get adminSettingsAddCityTitle => 'إضافة مدينة';

  @override
  String get adminSettingsAddAdminTitle => 'إضافة مشرف';

  @override
  String get adminSettingsCredentialsNote =>
      'مرئي للمشرف العام فقط. يُخزَّن في Firestore system_config.';

  @override
  String get navActivity => 'سجل النشاط';

  @override
  String get adminActivitySubtitle => 'سجل إجراءات المشرفين وسجل التدقيق';

  @override
  String get adminActivitySearchHint => 'البحث بالاسم أو نوع الإجراء';

  @override
  String get adminActivityEmpty => 'لا يوجد نشاط مسجل بعد.';

  @override
  String get adminActivityNoResults => 'لم يتم العثور على نتائج.';

  @override
  String get adminActivityPerformedBy => 'بواسطة';

  @override
  String get adminActivityJustNow => 'الآن';

  @override
  String adminActivityMinutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String adminActivityHoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String adminActivityDaysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get adminActivityActionApproved => 'الموافقة على إعلان';

  @override
  String get adminActivityActionRejected => 'رفض إعلان';

  @override
  String get adminActivityActionDeleted => 'حذف إعلان';

  @override
  String get adminActivityActionUpdatedPrice => 'تحديث سعر الباقة';

  @override
  String get adminActivityActionUpdatedConfig => 'تحديث الإعدادات';

  @override
  String get adminActivityActionAddedCity => 'إضافة مدينة';

  @override
  String get adminActivityActionRemovedCity => 'إزالة مدينة';

  @override
  String get adminActivityActionAddedAdmin => 'إضافة مشرف';

  @override
  String get adminActivityActionUpdatedCredentials => 'تحديث بيانات الاعتماد';

  @override
  String get adminMessagesTitle => 'الرسائل والشكاوى';

  @override
  String get adminMessagesSubtitle => 'تذاكر دعم المستخدمين ومحادثاتهم';

  @override
  String get adminMessagesFilterAll => 'الكل';

  @override
  String get adminMessagesFilterOpen => 'مفتوح';

  @override
  String get adminMessagesFilterResolved => 'تم الحل';

  @override
  String get adminMessagesStatusOpen => 'مفتوح';

  @override
  String get adminMessagesStatusResolved => 'تم الحل';

  @override
  String get adminMessagesSend => 'إرسال';

  @override
  String get adminMessagesSelectTicket => 'اختر تذكرة لعرض المحادثة';

  @override
  String get adminMessagesResolve => 'تحديد كمحلول';

  @override
  String get adminMessagesReopen => 'إعادة فتح';

  @override
  String get adminMessagesReplyHint => 'اكتب رداً…';

  @override
  String get adminMessagesBackToList => 'العودة إلى القائمة';

  @override
  String get navFlaggedAds => 'بلاغات الإعلانات';

  @override
  String get adminFlaggedSubtitle =>
      'مراجعة الإعلانات التي أبلغ عنها المستخدمون';

  @override
  String get adminFlaggedReasonLabel => 'السبب';

  @override
  String get adminFlaggedReportedByLabel => 'بلّغ بواسطة';

  @override
  String get adminFlaggedViewAd => 'عرض الإعلان';

  @override
  String get adminFlaggedDeleteAd => 'حذف الإعلان';

  @override
  String get adminFlaggedIgnore => 'تجاهل البلاغ';

  @override
  String get adminFlaggedEmpty => 'لا توجد بلاغات معلّقة.';

  @override
  String get adminFlaggedDeleteConfirm => 'هل أنت متأكد من حذف هذا الإعلان؟';

  @override
  String get adminFlaggedDeleteSuccess => 'تم حذف الإعلان وإغلاق البلاغ.';

  @override
  String get adminFlaggedIgnoredSuccess => 'تم تجاهل البلاغ.';

  @override
  String get adminFlaggedAdMissing => 'الإعلان لم يعد متاحاً';

  @override
  String get flaggedReasonSold => 'السيارة مباعة بالفعل';

  @override
  String get flaggedReasonWrongPrice => 'السعر غير صحيح';

  @override
  String get flaggedReasonMisleading => 'معلومات مضللة';

  @override
  String get flaggedReasonSpam => 'رسائل مزعجة';

  @override
  String get next => 'التالي';

  @override
  String addCarStepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get addCarPublish => 'نشر';

  @override
  String get addCarExit => 'خروج';

  @override
  String get addCarSave => 'حفظ';

  @override
  String get addCarPublishing => 'جارٍ النشر...';

  @override
  String get addCarSaving => 'جارٍ الحفظ...';

  @override
  String get addCarPhotoProcessing => 'جارٍ معالجة الصورة...';

  @override
  String get addCarMinPhotosRequired => 'يرجى اختيار 4 صور على الأقل.';

  @override
  String get addCarUploadFailed => 'فشل رفع الصور.';

  @override
  String get addCarSaveSuccess => 'تم حفظ التغييرات بنجاح';

  @override
  String get addCarDraftSavedSuccess =>
      'تم حفظ التقدم. يمكنك المتابعة لاحقاً من إعلاناتي.';

  @override
  String get addCarDraftEmpty => 'يرجى إضافة بعض التفاصيل قبل الحفظ.';

  @override
  String get addCarPublishSuccess => 'تم نشر إعلانك بنجاح';

  @override
  String get addCarSaveFailed => 'فشل الحفظ. يرجى المحاولة مرة أخرى.';

  @override
  String get addCarPublishFailed => 'فشل النشر. يرجى المحاولة مرة أخرى.';

  @override
  String get addCarPhotoCheckFailed =>
      'فشل فحص الصورة. يرجى المحاولة مرة أخرى.';

  @override
  String get addCarStepLocationTitle => 'الموقع';

  @override
  String get addCarStepPhotosTitle => 'الصور';

  @override
  String get addCarStepInfoTitle => 'المعلومات';

  @override
  String get addCarStepPlateTitle => 'اللوحة';

  @override
  String get addCarStepDetailsTitle => 'التفاصيل';

  @override
  String get addCarStepTechnicalTitle => 'تقني';

  @override
  String get addCarStepInteriorTitle => 'الداخلية';

  @override
  String get addCarStepConditionTitle => 'الحالة';

  @override
  String get addCarStepPriceTitle => 'السعر';

  @override
  String get addCarStepReviewTitle => 'مراجعة';

  @override
  String get addCarStepListingTitle => 'النشر';

  @override
  String get addCarStepPaymentTitle => 'الدفع';

  @override
  String get addCarLocationHeading => 'أين تقع سيارتك؟';

  @override
  String get addCarLocationSubtitle => 'اختر المحافظة / المنطقة';

  @override
  String get addCarProvinceLabel => 'المحافظة';

  @override
  String get addCarProvincePlaceholder => 'اختر المحافظة';

  @override
  String get addCarAreaLabel => 'المنطقة / المدينة';

  @override
  String get addCarAreaPlaceholder => 'اختر المنطقة';

  @override
  String get addCarPhotosHeading => 'التقط الصور';

  @override
  String get addCarPhotosSubtitle => 'التقط 4 صور على الأقل لسيارتك';

  @override
  String get addCarPhotoPrimary => 'رئيسية';

  @override
  String get addCarBasicInfoHeading => 'المعلومات الأساسية للسيارة';

  @override
  String get addCarBasicInfoSubtitle => 'اختر التفاصيل التي تطابق سيارتك';

  @override
  String get addCarBrandLabel => 'العلامة';

  @override
  String get addCarBrandPlaceholder => 'اختر العلامة';

  @override
  String get addCarModelLabel => 'الموديل';

  @override
  String get addCarModelPlaceholder => 'اختر الموديل';

  @override
  String get addCarColorLabel => 'اللون';

  @override
  String get addCarColorPlaceholder => 'اختر اللون';

  @override
  String get addCarYearLabel => 'سنة الموديل';

  @override
  String get addCarYearPlaceholder => 'اختر السنة';

  @override
  String get addCarTrimLabel => 'الفئة';

  @override
  String get addCarTrimPlaceholder => 'اختر الفئة';
}
