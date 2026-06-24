/// reCAPTCHA Enterprise site keys from Firebase Console
/// (Authentication → Settings → Fraud prevention → reCAPTCHA).
///
/// Firebase Auth fetches platform keys automatically when
/// [FirebaseAuth.initializeRecaptchaConfig] runs. The web key is also
/// referenced in [web/index.html] to preload the Enterprise script.
abstract final class RecaptchaEnterpriseConfig {
  static const String webSiteKey =
      '6Lci2CstAAAAAP4dOUHfxeVt2ai057KzVKnJYsQg';

  static const String androidSiteKey =
      '6LdCnCstAAAAANCY3shOSwhADc3nx0eyG9YDCbBT';

  static const String iosSiteKey =
      '6Le1eistAAAAAFqjxL0Hgdwzy7A4heuC6wRZUloy';
}
