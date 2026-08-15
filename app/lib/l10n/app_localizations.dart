import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CallMe!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct, decentralized and secure communication.'**
  String get welcomeSubtitle;

  /// No description provided for @supportCardTitle.
  ///
  /// In en, this message translates to:
  /// **'CallMe is a initiative focused on guaranteeing gamers group calls through P2P networks.'**
  String get supportCardTitle;

  /// No description provided for @supportCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Developing and maintaining decentralized technologies requires a lot of coffee and sleepless nights. Consider supporting the project! Any amount help!'**
  String get supportCardSubtitle;

  /// No description provided for @supportButton.
  ///
  /// In en, this message translates to:
  /// **'Support Development'**
  String get supportButton;

  /// No description provided for @helperText.
  ///
  /// In en, this message translates to:
  /// **'Create your own space or join your friends in the bottom bar.'**
  String get helperText;

  /// No description provided for @createServer.
  ///
  /// In en, this message translates to:
  /// **'Create Server'**
  String get createServer;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português (Brasil)'**
  String get languagePortuguese;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get tabAppearance;

  /// No description provided for @tabAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get tabAudio;

  /// No description provided for @tabSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get tabSecurity;

  /// No description provided for @tabNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get tabNetwork;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY NAME'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get profileDisplayNameHint;

  /// No description provided for @profileLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'APP LANGUAGE'**
  String get profileLanguageLabel;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileSaveSuccess;

  /// No description provided for @appearanceAppThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'APP THEME'**
  String get appearanceAppThemeLabel;

  /// No description provided for @appearanceAccentColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get appearanceAccentColorTitle;

  /// No description provided for @appearanceAccentColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Changes the main color of CallMe buttons, icons and highlights.'**
  String get appearanceAccentColorDesc;

  /// No description provided for @appearanceCustomColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get appearanceCustomColorTitle;

  /// No description provided for @appearanceTypographyLabel.
  ///
  /// In en, this message translates to:
  /// **'TYPOGRAPHY'**
  String get appearanceTypographyLabel;

  /// No description provided for @appearanceAppFontTitle.
  ///
  /// In en, this message translates to:
  /// **'App Font'**
  String get appearanceAppFontTitle;

  /// No description provided for @appearanceAppFontDesc.
  ///
  /// In en, this message translates to:
  /// **'Changes the text style across the entire interface.'**
  String get appearanceAppFontDesc;

  /// No description provided for @appearanceVoiceIndicatorLabel.
  ///
  /// In en, this message translates to:
  /// **'VOICE INDICATOR'**
  String get appearanceVoiceIndicatorLabel;

  /// No description provided for @appearanceIndicatorColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Indicator Color'**
  String get appearanceIndicatorColorTitle;

  /// No description provided for @appearanceIndicatorColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Color of the card when a user is speaking in the call.'**
  String get appearanceIndicatorColorDesc;

  /// No description provided for @appearanceNeonEffectTitle.
  ///
  /// In en, this message translates to:
  /// **'Neon Effect'**
  String get appearanceNeonEffectTitle;

  /// No description provided for @appearanceNeonEffectDesc.
  ///
  /// In en, this message translates to:
  /// **'Enables a glow around the card when the user speaks.'**
  String get appearanceNeonEffectDesc;

  /// No description provided for @appearanceBackgroundImagesLabel.
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND IMAGES'**
  String get appearanceBackgroundImagesLabel;

  /// No description provided for @appearanceAppBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'App Background'**
  String get appearanceAppBackgroundTitle;

  /// No description provided for @appearanceAppBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize the image that appears behind all screens.'**
  String get appearanceAppBackgroundDesc;

  /// No description provided for @appearanceNotifBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Background'**
  String get appearanceNotifBackgroundTitle;

  /// No description provided for @appearanceNotifBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Exclusive image that appears in the expandable notification during a voice call.'**
  String get appearanceNotifBackgroundDesc;

  /// No description provided for @btnSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get btnSelectImage;

  /// No description provided for @imageConfigured.
  ///
  /// In en, this message translates to:
  /// **'Image configured'**
  String get imageConfigured;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue (Default)'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @audioProcessingLabel.
  ///
  /// In en, this message translates to:
  /// **'AUDIO PROCESSING (WEBRTC)'**
  String get audioProcessingLabel;

  /// No description provided for @audioFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Filters (Gamers)'**
  String get audioFiltersTitle;

  /// No description provided for @audioFiltersDesc.
  ///
  /// In en, this message translates to:
  /// **'Disable the filters below if your audio is too low while playing games or listening to music. This will make WebRTC send raw audio at max volume.'**
  String get audioFiltersDesc;

  /// No description provided for @audioAgcTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Gain Control (AGC)'**
  String get audioAgcTitle;

  /// No description provided for @audioAgcDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically lowers your microphone when it detects loud game sound.'**
  String get audioAgcDesc;

  /// No description provided for @audioNoiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Noise Suppression'**
  String get audioNoiseTitle;

  /// No description provided for @audioNoiseDesc.
  ///
  /// In en, this message translates to:
  /// **'Removes background noises (like fan or game sound).'**
  String get audioNoiseDesc;

  /// No description provided for @audioEchoTitle.
  ///
  /// In en, this message translates to:
  /// **'Echo Cancellation'**
  String get audioEchoTitle;

  /// No description provided for @audioEchoDesc.
  ///
  /// In en, this message translates to:
  /// **'Prevents others from hearing their own voice coming from your speaker.'**
  String get audioEchoDesc;

  /// No description provided for @securityExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Account'**
  String get securityExportTitle;

  /// No description provided for @securityExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your data in a binary file so you don\'t lose your identity in case of formatting.'**
  String get securityExportDesc;

  /// No description provided for @securityExportPassHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password for the backup'**
  String get securityExportPassHint;

  /// No description provided for @securityExportPassConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get securityExportPassConfirmHint;

  /// No description provided for @securityExportBtn.
  ///
  /// In en, this message translates to:
  /// **'Generate Security File'**
  String get securityExportBtn;

  /// No description provided for @securityExportErrShort.
  ///
  /// In en, this message translates to:
  /// **'The password must have at least 4 characters.'**
  String get securityExportErrShort;

  /// No description provided for @securityExportErrMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get securityExportErrMatch;

  /// No description provided for @securityExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup generated and ready to share!'**
  String get securityExportSuccess;

  /// No description provided for @securityExportShareText.
  ///
  /// In en, this message translates to:
  /// **'My CallMe Backup'**
  String get securityExportShareText;

  /// No description provided for @securityExportErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error exporting: '**
  String get securityExportErrorPrefix;

  /// No description provided for @securityImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Account'**
  String get securityImportTitle;

  /// No description provided for @securityImportDesc.
  ///
  /// In en, this message translates to:
  /// **'Import your .clmbkp file to recover your identity and access your servers.'**
  String get securityImportDesc;

  /// No description provided for @securityImportSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get securityImportSelectFile;

  /// No description provided for @securityImportFileSelected.
  ///
  /// In en, this message translates to:
  /// **'File selected'**
  String get securityImportFileSelected;

  /// No description provided for @securityImportPassHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the backup password'**
  String get securityImportPassHint;

  /// No description provided for @securityImportBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Restore'**
  String get securityImportBtn;

  /// No description provided for @securityImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account restored successfully!'**
  String get securityImportSuccess;

  /// No description provided for @securityImportErrPass.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get securityImportErrPass;

  /// No description provided for @securityImportErrCorrupt.
  ///
  /// In en, this message translates to:
  /// **'Error: the file may be invalid or corrupted.'**
  String get securityImportErrCorrupt;

  /// No description provided for @networkDiagnosticLabel.
  ///
  /// In en, this message translates to:
  /// **'NETWORK DIAGNOSTIC'**
  String get networkDiagnosticLabel;

  /// No description provided for @networkDiagnosticDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover your network conditions and see how the app is handling WebRTC and NAT (CGNAT).'**
  String get networkDiagnosticDesc;

  /// No description provided for @networkDiagnosticRunning.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get networkDiagnosticRunning;

  /// No description provided for @networkDiagnosticBtn.
  ///
  /// In en, this message translates to:
  /// **'Run Diagnostic'**
  String get networkDiagnosticBtn;

  /// No description provided for @networkDiagnosticResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'RESULTS'**
  String get networkDiagnosticResultsLabel;

  /// No description provided for @networkLocalIpv4.
  ///
  /// In en, this message translates to:
  /// **'Local IPv4'**
  String get networkLocalIpv4;

  /// No description provided for @networkPublicIpv4.
  ///
  /// In en, this message translates to:
  /// **'Public IPv4'**
  String get networkPublicIpv4;

  /// No description provided for @networkPublicIpv6.
  ///
  /// In en, this message translates to:
  /// **'Public IPv6'**
  String get networkPublicIpv6;

  /// No description provided for @networkStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Network Status'**
  String get networkStatusLabel;

  /// No description provided for @networkStatusCgnat.
  ///
  /// In en, this message translates to:
  /// **'CGNAT (Strict)'**
  String get networkStatusCgnat;

  /// No description provided for @networkStatusNat.
  ///
  /// In en, this message translates to:
  /// **'NAT (Router)'**
  String get networkStatusNat;

  /// No description provided for @networkStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open (No NAT)'**
  String get networkStatusOpen;

  /// No description provided for @networkStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get networkStatusUnknown;

  /// No description provided for @networkExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'What does this mean?'**
  String get networkExplanationTitle;

  /// No description provided for @networkExpIpv6.
  ///
  /// In en, this message translates to:
  /// **'Your device has IPv6! This means CallMe can establish a direct P2P connection with excellent quality, bypassing any NAT.'**
  String get networkExpIpv6;

  /// No description provided for @networkExpOpen.
  ///
  /// In en, this message translates to:
  /// **'We didn\'t detect any NAT restrictions. Direct connections should work perfectly.'**
  String get networkExpOpen;

  /// No description provided for @networkExpNat.
  ///
  /// In en, this message translates to:
  /// **'You are behind a common NAT (probably a Wi-Fi router). WebRTC will try to punch through this NAT (Holepunching). Most of the time, direct connection works.'**
  String get networkExpNat;

  /// No description provided for @networkExpCgnat.
  ///
  /// In en, this message translates to:
  /// **'We detected Strict CGNAT (Mobile Carrier NAT). Traditional P2P WebRTC cannot bypass this. But don\'t worry! CallMe is using the Stealth Relay network (MQTT) to ensure your voice reaches its destination.'**
  String get networkExpCgnat;

  /// No description provided for @networkExpUnknown.
  ///
  /// In en, this message translates to:
  /// **'It was not possible to determine the exact type of NAT on your network (or you are using the Web version).'**
  String get networkExpUnknown;

  /// No description provided for @donationTitle.
  ///
  /// In en, this message translates to:
  /// **'Support the Project!'**
  String get donationTitle;

  /// No description provided for @donationDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoying CallMe? We charge nothing. If you want to help pay for Relay servers and keep the project alive, make a donation of any amount!'**
  String get donationDesc;

  /// No description provided for @donationPixCopied.
  ///
  /// In en, this message translates to:
  /// **'PIX Key copied to clipboard!'**
  String get donationPixCopied;

  /// No description provided for @donationCopyPix.
  ///
  /// In en, this message translates to:
  /// **'Copy PIX Key'**
  String get donationCopyPix;

  /// No description provided for @donationClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get donationClose;

  /// No description provided for @createServerDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Server'**
  String get createServerDialogTitle;

  /// No description provided for @createServerDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Your server is where you and your friends hang out. Create yours and start talking freely.'**
  String get createServerDialogDesc;

  /// No description provided for @createServerDialogNameLabel.
  ///
  /// In en, this message translates to:
  /// **'SERVER NAME'**
  String get createServerDialogNameLabel;

  /// No description provided for @createServerDialogNameHint.
  ///
  /// In en, this message translates to:
  /// **'My P2P Server'**
  String get createServerDialogNameHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @createServerDialogError.
  ///
  /// In en, this message translates to:
  /// **'Error creating server: {error}'**
  String createServerDialogError(String error);
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
