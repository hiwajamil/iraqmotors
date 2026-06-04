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
  String get heroSubtitle => 'تجربة جديدة لاكتشاف السيارات الفاخرة في كردستان.';

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
  String get invalidEmail => 'البريد الإلكتروني غير صالح';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get phonePlaceholder => '0750 000 0000';

  @override
  String get workPhonePlaceholder => '0770 000 0000';

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
  String get authInvalidPhone => 'رقم الهاتف غير صالح. مثال: 0750 000 0000';

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
  String get authTooManyRequests =>
      'محاولات كثيرة. انتظر قليلاً وحاول مرة أخرى.';

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
  String get locationDefaultRegion => 'أربيل، السليمانية و3 مدن أخرى';

  @override
  String get locationAllCities => 'جميع المدن';

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get advancedSearch => 'بحث متقدم';

  @override
  String get filterModel => 'الموديل';

  @override
  String get filterYear => 'السنة';

  @override
  String get filterMileage => 'المسافة المقطوعة';

  @override
  String get filterPrice => 'السعر';

  @override
  String get filterCondition => 'الحالة';

  @override
  String get filterEngineType => 'نوع المحرك';

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
}
