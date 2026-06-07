import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ku.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ku'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ku, this message translates to:
  /// **'IQ Motors'**
  String get appTitle;

  /// No description provided for @myAccount.
  ///
  /// In ku, this message translates to:
  /// **'هەژمارەکەم'**
  String get myAccount;

  /// No description provided for @signOut.
  ///
  /// In ku, this message translates to:
  /// **'چوونەدەرەوە'**
  String get signOut;

  /// No description provided for @navAllModels.
  ///
  /// In ku, this message translates to:
  /// **'هەموو مۆدێلەکان'**
  String get navAllModels;

  /// No description provided for @navTuning.
  ///
  /// In ku, this message translates to:
  /// **'توونینگ و دەستکاریکراو'**
  String get navTuning;

  /// No description provided for @navShowrooms.
  ///
  /// In ku, this message translates to:
  /// **'پێشانگاکان'**
  String get navShowrooms;

  /// No description provided for @heroTitle.
  ///
  /// In ku, this message translates to:
  /// **'هێز بە شێوازێکی سادە.'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In ku, this message translates to:
  /// **'ئەزموونێکی نوێ بۆ دۆزینەوەی ئۆتۆمبێلە ئاست بەرزەکان.'**
  String get heroSubtitle;

  /// No description provided for @viewAll.
  ///
  /// In ku, this message translates to:
  /// **'هەموو'**
  String get viewAll;

  /// No description provided for @footerCopyright.
  ///
  /// In ku, this message translates to:
  /// **'© 2026 IQ Motors. گشت مافەکان پارێزراون.'**
  String get footerCopyright;

  /// No description provided for @selectLanguage.
  ///
  /// In ku, this message translates to:
  /// **'زمان هەڵبژێرە'**
  String get selectLanguage;

  /// No description provided for @languageKurdish.
  ///
  /// In ku, this message translates to:
  /// **'کوردی'**
  String get languageKurdish;

  /// No description provided for @languageArabic.
  ///
  /// In ku, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ku, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @back.
  ///
  /// In ku, this message translates to:
  /// **'گەڕانەوە'**
  String get back;

  /// No description provided for @signIn.
  ///
  /// In ku, this message translates to:
  /// **'چوونەژوورەوە'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In ku, this message translates to:
  /// **'دروستکردنی هەژمار'**
  String get createAccount;

  /// No description provided for @signInSubtitle.
  ///
  /// In ku, this message translates to:
  /// **'ژمارەی مۆبایل و وشەی نهێنیت بنووسە.'**
  String get signInSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ku, this message translates to:
  /// **'بەخێربێیت، جۆری هەژمارەکەت هەڵبژێرە بۆ دەستپێکردن.'**
  String get registerSubtitle;

  /// No description provided for @accountIndividual.
  ///
  /// In ku, this message translates to:
  /// **'کەسی ئاسایی'**
  String get accountIndividual;

  /// No description provided for @accountShowroom.
  ///
  /// In ku, this message translates to:
  /// **'پێشانگای ئۆتۆمبێل'**
  String get accountShowroom;

  /// No description provided for @emailSuperAdmin.
  ///
  /// In ku, this message translates to:
  /// **'ئیمەیڵ (بۆ بەڕێوەبەری سەرەکی)'**
  String get emailSuperAdmin;

  /// No description provided for @emailPlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'ئیمەیڵەکەت بنووسە'**
  String get emailPlaceholder;

  /// No description provided for @invalidEmail.
  ///
  /// In ku, this message translates to:
  /// **'ئیمەیڵ دروست نییە'**
  String get invalidEmail;

  /// No description provided for @phoneLabel.
  ///
  /// In ku, this message translates to:
  /// **'ژمارەی مۆبایل'**
  String get phoneLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In ku, this message translates to:
  /// **'ژمارەی مۆبایل پێویستە'**
  String get phoneRequired;

  /// No description provided for @phonePlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'0750 000 0000'**
  String get phonePlaceholder;

  /// No description provided for @workPhonePlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'0770 000 0000'**
  String get workPhonePlaceholder;

  /// No description provided for @passwordLabel.
  ///
  /// In ku, this message translates to:
  /// **'وشەی نهێنی (Password)'**
  String get passwordLabel;

  /// No description provided for @passwordRequired.
  ///
  /// In ku, this message translates to:
  /// **'وشەی نهێنی پێویستە'**
  String get passwordRequired;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'وشەی نهێنییەکەت بنووسە'**
  String get passwordPlaceholder;

  /// No description provided for @passwordSetPlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'وشەی نهێنییەکەت دابنێ'**
  String get passwordSetPlaceholder;

  /// No description provided for @passwordMinLength.
  ///
  /// In ku, this message translates to:
  /// **'وشەی نهێنی دەبێت لانیکەم ٦ پیت بێت'**
  String get passwordMinLength;

  /// No description provided for @fullName.
  ///
  /// In ku, this message translates to:
  /// **'ناوی تەواو'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In ku, this message translates to:
  /// **'ناوی تەواو پێویستە'**
  String get fullNameRequired;

  /// No description provided for @fullNamePlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'ناوی خۆت بنووسە'**
  String get fullNamePlaceholder;

  /// No description provided for @otpRequired.
  ///
  /// In ku, this message translates to:
  /// **'کۆدی سەلماندن پێویستە'**
  String get otpRequired;

  /// No description provided for @otpInvalid.
  ///
  /// In ku, this message translates to:
  /// **'کۆدەکە دروست نییە'**
  String get otpInvalid;

  /// No description provided for @otpPlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'کۆدی سەلماندن'**
  String get otpPlaceholder;

  /// No description provided for @sendCode.
  ///
  /// In ku, this message translates to:
  /// **'ناردنی کۆد'**
  String get sendCode;

  /// No description provided for @showroomName.
  ///
  /// In ku, this message translates to:
  /// **'ناوی پێشانگا'**
  String get showroomName;

  /// No description provided for @showroomNameRequired.
  ///
  /// In ku, this message translates to:
  /// **'ناوی پێشانگا پێویستە'**
  String get showroomNameRequired;

  /// No description provided for @showroomNamePlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'بۆ نموونە: پێشانگای ڤی ئای پی'**
  String get showroomNamePlaceholder;

  /// No description provided for @ownerName.
  ///
  /// In ku, this message translates to:
  /// **'ناوی خاوەن پێشانگا / بەڕێوەبەر'**
  String get ownerName;

  /// No description provided for @ownerRequired.
  ///
  /// In ku, this message translates to:
  /// **'ناوی بەرپرس پێویستە'**
  String get ownerRequired;

  /// No description provided for @ownerPlaceholder.
  ///
  /// In ku, this message translates to:
  /// **'ناوی تەواوی بەرپرسی هەژمارەکە'**
  String get ownerPlaceholder;

  /// No description provided for @workPhoneLabel.
  ///
  /// In ku, this message translates to:
  /// **'ژمارەی مۆبایلی کار'**
  String get workPhoneLabel;

  /// No description provided for @cityLocation.
  ///
  /// In ku, this message translates to:
  /// **'شار / شوێن'**
  String get cityLocation;

  /// No description provided for @selectCityLocation.
  ///
  /// In ku, this message translates to:
  /// **'شار / شوێن هەڵبژێرە'**
  String get selectCityLocation;

  /// No description provided for @selectCityRequired.
  ///
  /// In ku, this message translates to:
  /// **'شارەکەت هەڵبژێرە'**
  String get selectCityRequired;

  /// No description provided for @selectCityHint.
  ///
  /// In ku, this message translates to:
  /// **'شارەکەت هەڵبژێرە...'**
  String get selectCityHint;

  /// No description provided for @register.
  ///
  /// In ku, this message translates to:
  /// **'تۆمارکردن'**
  String get register;

  /// No description provided for @submitShowroomRequest.
  ///
  /// In ku, this message translates to:
  /// **'ناردنی داواکاری'**
  String get submitShowroomRequest;

  /// No description provided for @noAccount.
  ///
  /// In ku, this message translates to:
  /// **'هەژمارت نییە؟ '**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In ku, this message translates to:
  /// **'پێشتر هەژمارت هەیە؟ '**
  String get haveAccount;

  /// No description provided for @enterPhoneFirst.
  ///
  /// In ku, this message translates to:
  /// **'سەرەتا ژمارەی مۆبایل بنووسە'**
  String get enterPhoneFirst;

  /// No description provided for @verificationCodeSent.
  ///
  /// In ku, this message translates to:
  /// **'کۆدی سەلماندن نێردرا بۆ {phone}'**
  String verificationCodeSent(String phone);

  /// No description provided for @authInvalidPhone.
  ///
  /// In ku, this message translates to:
  /// **'ژمارەی مۆبایل دروست نییە. نموونە: 0750 000 0000'**
  String get authInvalidPhone;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In ku, this message translates to:
  /// **'تۆمارکردن سەرکەوتوو نەبوو. دووبارە هەوڵ بدەرەوە.'**
  String get authRegistrationFailed;

  /// No description provided for @authSendCodeFirst.
  ///
  /// In ku, this message translates to:
  /// **'سەرەتا کۆدی سەلماندن بنێرە'**
  String get authSendCodeFirst;

  /// No description provided for @authPhoneAutoVerified.
  ///
  /// In ku, this message translates to:
  /// **'ژمارەی مۆبایل بە شێوەی خۆکار سەلماندرا'**
  String get authPhoneAutoVerified;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In ku, this message translates to:
  /// **'ئەم ژمارەی مۆبایلە پێشتر تۆمار کراوە. چوونەژوورەوە هەوڵ بدە.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In ku, this message translates to:
  /// **'وشەی نهێنی زۆر لاوازە. لانیکەم ٦ پیت بەکاربهێنە.'**
  String get authWeakPassword;

  /// No description provided for @authWrongCredentials.
  ///
  /// In ku, this message translates to:
  /// **'ژمارەی مۆبایل یان وشەی نهێنی هەڵەیە.'**
  String get authWrongCredentials;

  /// No description provided for @authTooManyRequests.
  ///
  /// In ku, this message translates to:
  /// **'هەوڵی زۆر. کەمێک چاوەڕێ بکە و دووبارە هەوڵ بدەرەوە.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In ku, this message translates to:
  /// **'پەیوەندی ئینتەرنێت نییە. دووبارە هەوڵ بدەرەوە.'**
  String get authNetworkError;

  /// No description provided for @authGenericError.
  ///
  /// In ku, this message translates to:
  /// **'هەڵەیەک ڕوویدا. دووبارە هەوڵ بدەرەوە.'**
  String get authGenericError;

  /// No description provided for @authVerificationExpired.
  ///
  /// In ku, this message translates to:
  /// **'کۆدی سەلماندن بەسەرچوو. کۆدێکی نوێ بنێرە.'**
  String get authVerificationExpired;

  /// No description provided for @authCaptchaFailed.
  ///
  /// In ku, this message translates to:
  /// **'سەلماندنی ئاسایش سەرکەوتوو نەبوو. پەڕەکە نوێ بکەرەوە و دووبارە هەوڵ بدەرەوە.'**
  String get authCaptchaFailed;

  /// No description provided for @cityErbil.
  ///
  /// In ku, this message translates to:
  /// **'هەولێر'**
  String get cityErbil;

  /// No description provided for @citySulaymaniyah.
  ///
  /// In ku, this message translates to:
  /// **'سلێمانی'**
  String get citySulaymaniyah;

  /// No description provided for @cityBaghdad.
  ///
  /// In ku, this message translates to:
  /// **'بەغداد'**
  String get cityBaghdad;

  /// No description provided for @cityDohuk.
  ///
  /// In ku, this message translates to:
  /// **'دهۆک'**
  String get cityDohuk;

  /// No description provided for @cityKirkuk.
  ///
  /// In ku, this message translates to:
  /// **'کەرکوک'**
  String get cityKirkuk;

  /// No description provided for @cityMosul.
  ///
  /// In ku, this message translates to:
  /// **'موسڵ'**
  String get cityMosul;

  /// No description provided for @cityBasra.
  ///
  /// In ku, this message translates to:
  /// **'بەسڕا'**
  String get cityBasra;

  /// No description provided for @cityMaysan.
  ///
  /// In ku, this message translates to:
  /// **'میسان'**
  String get cityMaysan;

  /// No description provided for @cityNajaf.
  ///
  /// In ku, this message translates to:
  /// **'نەجەف'**
  String get cityNajaf;

  /// No description provided for @cityKarbala.
  ///
  /// In ku, this message translates to:
  /// **'کەربەلا'**
  String get cityKarbala;

  /// No description provided for @cityAnbar.
  ///
  /// In ku, this message translates to:
  /// **'ئەنبار'**
  String get cityAnbar;

  /// No description provided for @citySalahuddin.
  ///
  /// In ku, this message translates to:
  /// **'سەلاحەدین'**
  String get citySalahuddin;

  /// No description provided for @cityBabylon.
  ///
  /// In ku, this message translates to:
  /// **'بابل'**
  String get cityBabylon;

  /// No description provided for @cityDiyala.
  ///
  /// In ku, this message translates to:
  /// **'دیالە'**
  String get cityDiyala;

  /// No description provided for @cityWasit.
  ///
  /// In ku, this message translates to:
  /// **'واست'**
  String get cityWasit;

  /// No description provided for @cityMuthanna.
  ///
  /// In ku, this message translates to:
  /// **'موسەنا'**
  String get cityMuthanna;

  /// No description provided for @cityQadisiyyah.
  ///
  /// In ku, this message translates to:
  /// **'قادسیە'**
  String get cityQadisiyyah;

  /// No description provided for @cityHalabja.
  ///
  /// In ku, this message translates to:
  /// **'هەڵەبجە'**
  String get cityHalabja;

  /// No description provided for @cityDhiQar.
  ///
  /// In ku, this message translates to:
  /// **'زیقار'**
  String get cityDhiQar;

  /// No description provided for @locationDefaultRegion.
  ///
  /// In ku, this message translates to:
  /// **'هەولێر، سلێمانی و ٣ شاری تر'**
  String get locationDefaultRegion;

  /// No description provided for @locationAllCities.
  ///
  /// In ku, this message translates to:
  /// **'هەموو شارەکان'**
  String get locationAllCities;

  /// No description provided for @locationSearch.
  ///
  /// In ku, this message translates to:
  /// **'گەڕان'**
  String get locationSearch;

  /// No description provided for @locationApply.
  ///
  /// In ku, this message translates to:
  /// **'جێبەجێکردن'**
  String get locationApply;

  /// No description provided for @locationTwoCities.
  ///
  /// In ku, this message translates to:
  /// **'{city1}، {city2}'**
  String locationTwoCities(String city1, String city2);

  /// No description provided for @locationCitiesAndMore.
  ///
  /// In ku, this message translates to:
  /// **'{city1}، {city2} و {count} شاری تر'**
  String locationCitiesAndMore(String city1, String city2, String count);

  /// No description provided for @selectCity.
  ///
  /// In ku, this message translates to:
  /// **'شار هەڵبژێرە'**
  String get selectCity;

  /// No description provided for @advancedSearch.
  ///
  /// In ku, this message translates to:
  /// **'گەڕانی پێشکەوتوو'**
  String get advancedSearch;

  /// No description provided for @filterModel.
  ///
  /// In ku, this message translates to:
  /// **'مۆدێل'**
  String get filterModel;

  /// No description provided for @filterYear.
  ///
  /// In ku, this message translates to:
  /// **'ساڵ'**
  String get filterYear;

  /// No description provided for @filterMileage.
  ///
  /// In ku, this message translates to:
  /// **'ماوەی ڕۆیشتن'**
  String get filterMileage;

  /// No description provided for @filterPrice.
  ///
  /// In ku, this message translates to:
  /// **'نرخ'**
  String get filterPrice;

  /// No description provided for @filterCondition.
  ///
  /// In ku, this message translates to:
  /// **'بارودۆخ'**
  String get filterCondition;

  /// No description provided for @filterEngineType.
  ///
  /// In ku, this message translates to:
  /// **'جۆری بزوێنەر'**
  String get filterEngineType;

  /// No description provided for @filterAllModels.
  ///
  /// In ku, this message translates to:
  /// **'هەموو مۆدێلەکان'**
  String get filterAllModels;

  /// No description provided for @filterAllYears.
  ///
  /// In ku, this message translates to:
  /// **'هەموو ساڵەکان'**
  String get filterAllYears;

  /// No description provided for @filterAllMileages.
  ///
  /// In ku, this message translates to:
  /// **'هەموو ماوەکان'**
  String get filterAllMileages;

  /// No description provided for @filterAllPrices.
  ///
  /// In ku, this message translates to:
  /// **'هەموو نرخەکان'**
  String get filterAllPrices;

  /// No description provided for @modelCamry.
  ///
  /// In ku, this message translates to:
  /// **'کامری'**
  String get modelCamry;

  /// No description provided for @modelLandCruiser.
  ///
  /// In ku, this message translates to:
  /// **'لاند کروزەر'**
  String get modelLandCruiser;

  /// No description provided for @modelPatrol.
  ///
  /// In ku, this message translates to:
  /// **'پاترۆڵ'**
  String get modelPatrol;

  /// No description provided for @mileage0.
  ///
  /// In ku, this message translates to:
  /// **'٠ km'**
  String get mileage0;

  /// No description provided for @mileage10k.
  ///
  /// In ku, this message translates to:
  /// **'تا ١٠،٠٠٠ km'**
  String get mileage10k;

  /// No description provided for @mileage50k.
  ///
  /// In ku, this message translates to:
  /// **'تا ٥٠،٠٠٠ km'**
  String get mileage50k;

  /// No description provided for @mileage100k.
  ///
  /// In ku, this message translates to:
  /// **'تا ١٠٠،٠٠٠ km'**
  String get mileage100k;

  /// No description provided for @mileage100kPlus.
  ///
  /// In ku, this message translates to:
  /// **'١٠٠،٠٠٠+ km'**
  String get mileage100kPlus;

  /// No description provided for @price20k.
  ///
  /// In ku, this message translates to:
  /// **'تا \$٢٠،٠٠٠'**
  String get price20k;

  /// No description provided for @price50k.
  ///
  /// In ku, this message translates to:
  /// **'تا \$٥٠،٠٠٠'**
  String get price50k;

  /// No description provided for @price100k.
  ///
  /// In ku, this message translates to:
  /// **'تا \$١٠٠،٠٠٠'**
  String get price100k;

  /// No description provided for @price100kPlus.
  ///
  /// In ku, this message translates to:
  /// **'\$١٠٠،٠٠٠+'**
  String get price100kPlus;

  /// No description provided for @conditionNew.
  ///
  /// In ku, this message translates to:
  /// **'نوێ'**
  String get conditionNew;

  /// No description provided for @conditionUsed.
  ///
  /// In ku, this message translates to:
  /// **'بەکارهاتوو'**
  String get conditionUsed;

  /// No description provided for @enginePetrol.
  ///
  /// In ku, this message translates to:
  /// **'بەنزین'**
  String get enginePetrol;

  /// No description provided for @engineHybrid.
  ///
  /// In ku, this message translates to:
  /// **'هایبرید'**
  String get engineHybrid;

  /// No description provided for @clearFilters.
  ///
  /// In ku, this message translates to:
  /// **'سڕینەوە'**
  String get clearFilters;

  /// No description provided for @showCarsCount.
  ///
  /// In ku, this message translates to:
  /// **'پیشاندانی {count} ئۆتۆمبێل'**
  String showCarsCount(String count);

  /// No description provided for @filterTitle.
  ///
  /// In ku, this message translates to:
  /// **'جیاکاری'**
  String get filterTitle;

  /// No description provided for @filterReset.
  ///
  /// In ku, this message translates to:
  /// **'ڕێکخستنەوە'**
  String get filterReset;

  /// No description provided for @filterBrands.
  ///
  /// In ku, this message translates to:
  /// **'براندەکان'**
  String get filterBrands;

  /// No description provided for @filterTrim.
  ///
  /// In ku, this message translates to:
  /// **'خاسڵەت'**
  String get filterTrim;

  /// No description provided for @filterFromYear.
  ///
  /// In ku, this message translates to:
  /// **'لە ساڵی'**
  String get filterFromYear;

  /// No description provided for @filterToYear.
  ///
  /// In ku, this message translates to:
  /// **'بۆ ساڵی'**
  String get filterToYear;

  /// No description provided for @filterMinPrice.
  ///
  /// In ku, this message translates to:
  /// **'کەمترین نرخ'**
  String get filterMinPrice;

  /// No description provided for @filterMaxPrice.
  ///
  /// In ku, this message translates to:
  /// **'زۆرترین نرخ'**
  String get filterMaxPrice;

  /// No description provided for @filterMinMileage.
  ///
  /// In ku, this message translates to:
  /// **'کەمترین کیلۆمەتر'**
  String get filterMinMileage;

  /// No description provided for @filterMaxMileage.
  ///
  /// In ku, this message translates to:
  /// **'زۆرترین کیلۆمەتر'**
  String get filterMaxMileage;

  /// No description provided for @filterPlateCity.
  ///
  /// In ku, this message translates to:
  /// **'شاری تابلۆ'**
  String get filterPlateCity;

  /// No description provided for @filterPlateType.
  ///
  /// In ku, this message translates to:
  /// **'جۆری تابلۆ'**
  String get filterPlateType;

  /// No description provided for @filterConditionSection.
  ///
  /// In ku, this message translates to:
  /// **'ڕەوش'**
  String get filterConditionSection;

  /// No description provided for @filterAll.
  ///
  /// In ku, this message translates to:
  /// **'هەموو'**
  String get filterAll;

  /// No description provided for @filterEngineSize.
  ///
  /// In ku, this message translates to:
  /// **'قەبارەی بزوێنەر'**
  String get filterEngineSize;

  /// No description provided for @filterCylinders.
  ///
  /// In ku, this message translates to:
  /// **'پستۆن'**
  String get filterCylinders;

  /// No description provided for @filterImportCountry.
  ///
  /// In ku, this message translates to:
  /// **'وڵاتی هاوردە'**
  String get filterImportCountry;

  /// No description provided for @filterColor.
  ///
  /// In ku, this message translates to:
  /// **'ڕەنگ'**
  String get filterColor;

  /// No description provided for @filterFuelType.
  ///
  /// In ku, this message translates to:
  /// **'سوتەمەنی'**
  String get filterFuelType;

  /// No description provided for @filterElectric.
  ///
  /// In ku, this message translates to:
  /// **'کارەبای'**
  String get filterElectric;

  /// No description provided for @filterTransmission.
  ///
  /// In ku, this message translates to:
  /// **'گێڕ'**
  String get filterTransmission;

  /// No description provided for @filterManual.
  ///
  /// In ku, this message translates to:
  /// **'دەستی'**
  String get filterManual;

  /// No description provided for @filterSeatMaterial.
  ///
  /// In ku, this message translates to:
  /// **'ماددەی کورسییەکان'**
  String get filterSeatMaterial;

  /// No description provided for @filterSearchModel.
  ///
  /// In ku, this message translates to:
  /// **'گەڕان بەدوای مۆدێل'**
  String get filterSearchModel;

  /// No description provided for @filterShowResults.
  ///
  /// In ku, this message translates to:
  /// **'دیارخستنی {count} ئۆتۆمبێلەکان'**
  String filterShowResults(String count);

  /// No description provided for @trimBase.
  ///
  /// In ku, this message translates to:
  /// **'ستاندارد'**
  String get trimBase;

  /// No description provided for @trimSport.
  ///
  /// In ku, this message translates to:
  /// **'وەرزشی'**
  String get trimSport;

  /// No description provided for @trimLuxury.
  ///
  /// In ku, this message translates to:
  /// **'لوکس'**
  String get trimLuxury;

  /// No description provided for @plateTypePrivate.
  ///
  /// In ku, this message translates to:
  /// **'تایبەت'**
  String get plateTypePrivate;

  /// No description provided for @plateTypeTemporary.
  ///
  /// In ku, this message translates to:
  /// **'کاتی'**
  String get plateTypeTemporary;

  /// No description provided for @plateTypeCommercial.
  ///
  /// In ku, this message translates to:
  /// **'بازرگانی'**
  String get plateTypeCommercial;

  /// No description provided for @cylinders4.
  ///
  /// In ku, this message translates to:
  /// **'٤ پستۆن'**
  String get cylinders4;

  /// No description provided for @cylinders6.
  ///
  /// In ku, this message translates to:
  /// **'٦ پستۆن'**
  String get cylinders6;

  /// No description provided for @cylinders8.
  ///
  /// In ku, this message translates to:
  /// **'٨ پستۆن'**
  String get cylinders8;

  /// No description provided for @importUae.
  ///
  /// In ku, this message translates to:
  /// **'ئیمارات'**
  String get importUae;

  /// No description provided for @importUsa.
  ///
  /// In ku, this message translates to:
  /// **'ئەمریکا'**
  String get importUsa;

  /// No description provided for @importEurope.
  ///
  /// In ku, this message translates to:
  /// **'ئەوروپا'**
  String get importEurope;

  /// No description provided for @importGcc.
  ///
  /// In ku, this message translates to:
  /// **'GCC'**
  String get importGcc;

  /// No description provided for @importLocal.
  ///
  /// In ku, this message translates to:
  /// **'ناوخۆیی'**
  String get importLocal;

  /// No description provided for @seatFabric.
  ///
  /// In ku, this message translates to:
  /// **'قوماش'**
  String get seatFabric;

  /// No description provided for @seatLeather.
  ///
  /// In ku, this message translates to:
  /// **'جلد'**
  String get seatLeather;

  /// No description provided for @seatSemiLeather.
  ///
  /// In ku, this message translates to:
  /// **'نیو جلد'**
  String get seatSemiLeather;

  /// No description provided for @seatAlcantaraLeather.
  ///
  /// In ku, this message translates to:
  /// **'شامۆ/جلد'**
  String get seatAlcantaraLeather;

  /// No description provided for @seatAlcantara.
  ///
  /// In ku, this message translates to:
  /// **'شامۆ'**
  String get seatAlcantara;

  /// No description provided for @brandTitle.
  ///
  /// In ku, this message translates to:
  /// **'مارکەی ئۆتۆمبێل'**
  String get brandTitle;

  /// No description provided for @brandSearchHint.
  ///
  /// In ku, this message translates to:
  /// **'گەڕان بە مارکە...'**
  String get brandSearchHint;

  /// No description provided for @noBrandsFound.
  ///
  /// In ku, this message translates to:
  /// **'هیچ مارکەیەک نەدۆزرایەوە'**
  String get noBrandsFound;

  /// No description provided for @specEngine.
  ///
  /// In ku, this message translates to:
  /// **'بزوێنەر'**
  String get specEngine;

  /// No description provided for @specMileage.
  ///
  /// In ku, this message translates to:
  /// **'ڕۆیشتوو'**
  String get specMileage;

  /// No description provided for @specTransmission.
  ///
  /// In ku, this message translates to:
  /// **'گێڕ'**
  String get specTransmission;

  /// No description provided for @specLocation.
  ///
  /// In ku, this message translates to:
  /// **'شوێن'**
  String get specLocation;

  /// No description provided for @carDetailsTitle.
  ///
  /// In ku, this message translates to:
  /// **'زانیاری ئۆتۆمبێل'**
  String get carDetailsTitle;

  /// No description provided for @description.
  ///
  /// In ku, this message translates to:
  /// **'وەسف'**
  String get description;

  /// No description provided for @features.
  ///
  /// In ku, this message translates to:
  /// **'تایبەتمەندیەکان'**
  String get features;

  /// No description provided for @technicalDetails.
  ///
  /// In ku, this message translates to:
  /// **'وردەکاری تەکنیکی'**
  String get technicalDetails;

  /// No description provided for @specYear.
  ///
  /// In ku, this message translates to:
  /// **'ساڵ'**
  String get specYear;

  /// No description provided for @specType.
  ///
  /// In ku, this message translates to:
  /// **'جۆر'**
  String get specType;

  /// No description provided for @specColor.
  ///
  /// In ku, this message translates to:
  /// **'ڕەنگ'**
  String get specColor;

  /// No description provided for @contactSeller.
  ///
  /// In ku, this message translates to:
  /// **'پەیوەندی بە فرۆشیار'**
  String get contactSeller;

  /// No description provided for @whatsapp.
  ///
  /// In ku, this message translates to:
  /// **'واتسئاپ'**
  String get whatsapp;

  /// No description provided for @phoneCall.
  ///
  /// In ku, this message translates to:
  /// **'پەیوەندی تەلەفۆنی'**
  String get phoneCall;

  /// No description provided for @saveToWishlist.
  ///
  /// In ku, this message translates to:
  /// **'پاشەکەوتکردن'**
  String get saveToWishlist;

  /// No description provided for @removeFromWishlist.
  ///
  /// In ku, this message translates to:
  /// **'لابردن لە دڵخواز'**
  String get removeFromWishlist;

  /// No description provided for @sellerDefault.
  ///
  /// In ku, this message translates to:
  /// **'فرۆشیار'**
  String get sellerDefault;

  /// No description provided for @transmissionAutomatic.
  ///
  /// In ku, this message translates to:
  /// **'ئۆتۆماتیک'**
  String get transmissionAutomatic;

  /// No description provided for @dummyCarDescription.
  ///
  /// In ku, this message translates to:
  /// **'کادیلاک Escalade-V 2024 بە تەواوی نوێ و بە بەرزترین ئاستی VIP. ئۆتۆمبێلەکە بە تەواوی پاکەتە و هیچ ڕۆیشتوویەکی نییە. گونجاوە بۆ بازاڕی کوردستان و عێراق بە پێشانگای پشتڕاستکراو.'**
  String get dummyCarDescription;

  /// No description provided for @dummyFeature1.
  ///
  /// In ku, this message translates to:
  /// **'پاکێجی VIP تەواو'**
  String get dummyFeature1;

  /// No description provided for @dummyFeature2.
  ///
  /// In ku, this message translates to:
  /// **'شاشەی OLED 38 ئینچ'**
  String get dummyFeature2;

  /// No description provided for @dummyFeature3.
  ///
  /// In ku, this message translates to:
  /// **'کورسی سەرەکی گەرم و سارد'**
  String get dummyFeature3;

  /// No description provided for @dummyFeature4.
  ///
  /// In ku, this message translates to:
  /// **'سیستەمی دەنگی AKG'**
  String get dummyFeature4;

  /// No description provided for @dummyFeature5.
  ///
  /// In ku, this message translates to:
  /// **'کامێرای 360 پلە'**
  String get dummyFeature5;

  /// No description provided for @dummyFeature6.
  ///
  /// In ku, this message translates to:
  /// **'سقف پانۆراما'**
  String get dummyFeature6;

  /// No description provided for @dummyFeature7.
  ///
  /// In ku, this message translates to:
  /// **'شاشەی پشت بۆ گەشتیاران'**
  String get dummyFeature7;

  /// No description provided for @dummyFeature8.
  ///
  /// In ku, this message translates to:
  /// **'سەرمایەگرتنی سێ ڕیز'**
  String get dummyFeature8;

  /// No description provided for @dummyColorMatteWhite.
  ///
  /// In ku, this message translates to:
  /// **'سپی مەت'**
  String get dummyColorMatteWhite;

  /// No description provided for @dummySellerName.
  ///
  /// In ku, this message translates to:
  /// **'ئارام محەمەد'**
  String get dummySellerName;

  /// No description provided for @dummySellerShowroom.
  ///
  /// In ku, this message translates to:
  /// **'پێشانگای ڤی ئای پی'**
  String get dummySellerShowroom;

  /// No description provided for @dummySellerListings.
  ///
  /// In ku, this message translates to:
  /// **'٤٢ ڕیکلامی چالاک'**
  String get dummySellerListings;

  /// No description provided for @superAdminBadge.
  ///
  /// In ku, this message translates to:
  /// **'Super Admin'**
  String get superAdminBadge;

  /// No description provided for @superAdminTitle.
  ///
  /// In ku, this message translates to:
  /// **'بەڕێوەبەری سەرەکی'**
  String get superAdminTitle;

  /// No description provided for @welcomeAdmin.
  ///
  /// In ku, this message translates to:
  /// **'بەخێربێیت، {name}'**
  String welcomeAdmin(String name);

  /// No description provided for @adminSubtitle.
  ///
  /// In ku, this message translates to:
  /// **'پێداچوونەوە بە ڕیکلامە چاوەڕوانەکان و ئامارەکانی پلاتفۆرم.'**
  String get adminSubtitle;

  /// No description provided for @navDashboard.
  ///
  /// In ku, this message translates to:
  /// **'داشبۆرد'**
  String get navDashboard;

  /// No description provided for @navApprovals.
  ///
  /// In ku, this message translates to:
  /// **'پەسەندکردنەکان'**
  String get navApprovals;

  /// No description provided for @navUsers.
  ///
  /// In ku, this message translates to:
  /// **'بەکارهێنەران'**
  String get navUsers;

  /// No description provided for @navReports.
  ///
  /// In ku, this message translates to:
  /// **'ڕاپۆرتەکان'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In ku, this message translates to:
  /// **'ڕێکخستن'**
  String get navSettings;

  /// No description provided for @statPendingApproval.
  ///
  /// In ku, this message translates to:
  /// **'چاوەڕوانی پەسەندکردن'**
  String get statPendingApproval;

  /// No description provided for @statTotalUsers.
  ///
  /// In ku, this message translates to:
  /// **'کۆی بەکارهێنەران'**
  String get statTotalUsers;

  /// No description provided for @statActiveListings.
  ///
  /// In ku, this message translates to:
  /// **'ڕیکلامی چالاک'**
  String get statActiveListings;

  /// No description provided for @statRegisteredShowrooms.
  ///
  /// In ku, this message translates to:
  /// **'پێشانگای تۆمارکراو'**
  String get statRegisteredShowrooms;

  /// No description provided for @pendingListingsTitle.
  ///
  /// In ku, this message translates to:
  /// **'ڕیکلامەکانی چاوەڕوان'**
  String get pendingListingsTitle;

  /// No description provided for @pendingListingsSubtitle.
  ///
  /// In ku, this message translates to:
  /// **'پێداچوونەوە بکە پێش بڵاوکردنەوە لە ماڵپەڕەکەدا.'**
  String get pendingListingsSubtitle;

  /// No description provided for @newCount.
  ///
  /// In ku, this message translates to:
  /// **'{count} نوێ'**
  String newCount(int count);

  /// No description provided for @tableCar.
  ///
  /// In ku, this message translates to:
  /// **'ئۆتۆمبێل'**
  String get tableCar;

  /// No description provided for @tablePublisher.
  ///
  /// In ku, this message translates to:
  /// **'بڵاوکەرەوە'**
  String get tablePublisher;

  /// No description provided for @tablePrice.
  ///
  /// In ku, this message translates to:
  /// **'نرخ'**
  String get tablePrice;

  /// No description provided for @tableActions.
  ///
  /// In ku, this message translates to:
  /// **'کردارەکان'**
  String get tableActions;

  /// No description provided for @publisherShowroom.
  ///
  /// In ku, this message translates to:
  /// **'پێشانگا'**
  String get publisherShowroom;

  /// No description provided for @publisherIndividual.
  ///
  /// In ku, this message translates to:
  /// **'کەسی'**
  String get publisherIndividual;

  /// No description provided for @actionView.
  ///
  /// In ku, this message translates to:
  /// **'بینین'**
  String get actionView;

  /// No description provided for @actionReject.
  ///
  /// In ku, this message translates to:
  /// **'ڕەتکردنەوە'**
  String get actionReject;

  /// No description provided for @actionApprove.
  ///
  /// In ku, this message translates to:
  /// **'پەسەندکردن'**
  String get actionApprove;

  /// No description provided for @dummyPublisherVipShowroom.
  ///
  /// In ku, this message translates to:
  /// **'پێشانگای ڤی ئای پی'**
  String get dummyPublisherVipShowroom;

  /// No description provided for @dummyPublisherAras.
  ///
  /// In ku, this message translates to:
  /// **'ئاراس محەمەد'**
  String get dummyPublisherAras;

  /// No description provided for @dummyPublisherAlofShowroom.
  ///
  /// In ku, this message translates to:
  /// **'پێشانگای ئەلۆف'**
  String get dummyPublisherAlofShowroom;

  /// No description provided for @dummyPublisherHiwa.
  ///
  /// In ku, this message translates to:
  /// **'هیوا جەمیل'**
  String get dummyPublisherHiwa;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ku'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ku':
      return AppLocalizationsKu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
