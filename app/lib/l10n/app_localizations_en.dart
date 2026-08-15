// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to CallMe!';

  @override
  String get welcomeSubtitle =>
      'Direct, decentralized and secure communication.';

  @override
  String get supportCardTitle =>
      'CallMe is a initiative focused on guaranteeing gamers group calls through P2P networks.';

  @override
  String get supportCardSubtitle =>
      'Developing and maintaining decentralized technologies requires a lot of coffee and sleepless nights. Consider supporting the project! Any amount help!';

  @override
  String get supportButton => 'Support Development';

  @override
  String get helperText =>
      'Create your own space or join your friends in the bottom bar.';

  @override
  String get createServer => 'Create Server';

  @override
  String get join => 'Join';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabAppearance => 'Appearance';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabSecurity => 'Security';

  @override
  String get tabNetwork => 'Network';

  @override
  String get profileDisplayNameLabel => 'DISPLAY NAME';

  @override
  String get profileDisplayNameHint => 'Enter your display name';

  @override
  String get profileLanguageLabel => 'APP LANGUAGE';

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get profileSaveSuccess => 'Profile updated successfully!';

  @override
  String get appearanceAppThemeLabel => 'APP THEME';

  @override
  String get appearanceAccentColorTitle => 'Accent Color';

  @override
  String get appearanceAccentColorDesc =>
      'Changes the main color of CallMe buttons, icons and highlights.';

  @override
  String get appearanceCustomColorTitle => 'Custom Color';

  @override
  String get appearanceTypographyLabel => 'TYPOGRAPHY';

  @override
  String get appearanceAppFontTitle => 'App Font';

  @override
  String get appearanceAppFontDesc =>
      'Changes the text style across the entire interface.';

  @override
  String get appearanceVoiceIndicatorLabel => 'VOICE INDICATOR';

  @override
  String get appearanceIndicatorColorTitle => 'Indicator Color';

  @override
  String get appearanceIndicatorColorDesc =>
      'Color of the card when a user is speaking in the call.';

  @override
  String get appearanceNeonEffectTitle => 'Neon Effect';

  @override
  String get appearanceNeonEffectDesc =>
      'Enables a glow around the card when the user speaks.';

  @override
  String get appearanceBackgroundImagesLabel => 'BACKGROUND IMAGES';

  @override
  String get appearanceAppBackgroundTitle => 'App Background';

  @override
  String get appearanceAppBackgroundDesc =>
      'Customize the image that appears behind all screens.';

  @override
  String get appearanceNotifBackgroundTitle => 'Notification Background';

  @override
  String get appearanceNotifBackgroundDesc =>
      'Exclusive image that appears in the expandable notification during a voice call.';

  @override
  String get btnSelectImage => 'Select Image';

  @override
  String get imageConfigured => 'Image configured';

  @override
  String get colorBlue => 'Blue (Default)';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorOrange => 'Orange';

  @override
  String get audioProcessingLabel => 'AUDIO PROCESSING (WEBRTC)';

  @override
  String get audioFiltersTitle => 'Audio Filters (Gamers)';

  @override
  String get audioFiltersDesc =>
      'Disable the filters below if your audio is too low while playing games or listening to music. This will make WebRTC send raw audio at max volume.';

  @override
  String get audioAgcTitle => 'Auto Gain Control (AGC)';

  @override
  String get audioAgcDesc =>
      'Automatically lowers your microphone when it detects loud game sound.';

  @override
  String get audioNoiseTitle => 'Noise Suppression';

  @override
  String get audioNoiseDesc =>
      'Removes background noises (like fan or game sound).';

  @override
  String get audioEchoTitle => 'Echo Cancellation';

  @override
  String get audioEchoDesc =>
      'Prevents others from hearing their own voice coming from your speaker.';

  @override
  String get securityExportTitle => 'Export Account';

  @override
  String get securityExportDesc =>
      'Save your data in a binary file so you don\'t lose your identity in case of formatting.';

  @override
  String get securityExportPassHint => 'Create a password for the backup';

  @override
  String get securityExportPassConfirmHint => 'Confirm password';

  @override
  String get securityExportBtn => 'Generate Security File';

  @override
  String get securityExportErrShort =>
      'The password must have at least 4 characters.';

  @override
  String get securityExportErrMatch => 'Passwords do not match.';

  @override
  String get securityExportSuccess => 'Backup generated and ready to share!';

  @override
  String get securityExportShareText => 'My CallMe Backup';

  @override
  String get securityExportErrorPrefix => 'Error exporting: ';

  @override
  String get securityImportTitle => 'Restore Account';

  @override
  String get securityImportDesc =>
      'Import your .clmbkp file to recover your identity and access your servers.';

  @override
  String get securityImportSelectFile => 'Select File';

  @override
  String get securityImportFileSelected => 'File selected';

  @override
  String get securityImportPassHint => 'Enter the backup password';

  @override
  String get securityImportBtn => 'Start Restore';

  @override
  String get securityImportSuccess => 'Account restored successfully!';

  @override
  String get securityImportErrPass => 'Incorrect password.';

  @override
  String get securityImportErrCorrupt =>
      'Error: the file may be invalid or corrupted.';

  @override
  String get networkDiagnosticLabel => 'NETWORK DIAGNOSTIC';

  @override
  String get networkDiagnosticDesc =>
      'Discover your network conditions and see how the app is handling WebRTC and NAT (CGNAT).';

  @override
  String get networkDiagnosticRunning => 'Analyzing...';

  @override
  String get networkDiagnosticBtn => 'Run Diagnostic';

  @override
  String get networkDiagnosticResultsLabel => 'RESULTS';

  @override
  String get networkLocalIpv4 => 'Local IPv4';

  @override
  String get networkPublicIpv4 => 'Public IPv4';

  @override
  String get networkPublicIpv6 => 'Public IPv6';

  @override
  String get networkStatusLabel => 'Network Status';

  @override
  String get networkStatusCgnat => 'CGNAT (Strict)';

  @override
  String get networkStatusNat => 'NAT (Router)';

  @override
  String get networkStatusOpen => 'Open (No NAT)';

  @override
  String get networkStatusUnknown => 'Unknown';

  @override
  String get networkExplanationTitle => 'What does this mean?';

  @override
  String get networkExpIpv6 =>
      'Your device has IPv6! This means CallMe can establish a direct P2P connection with excellent quality, bypassing any NAT.';

  @override
  String get networkExpOpen =>
      'We didn\'t detect any NAT restrictions. Direct connections should work perfectly.';

  @override
  String get networkExpNat =>
      'You are behind a common NAT (probably a Wi-Fi router). WebRTC will try to punch through this NAT (Holepunching). Most of the time, direct connection works.';

  @override
  String get networkExpCgnat =>
      'We detected Strict CGNAT (Mobile Carrier NAT). Traditional P2P WebRTC cannot bypass this. But don\'t worry! CallMe is using the Stealth Relay network (MQTT) to ensure your voice reaches its destination.';

  @override
  String get networkExpUnknown =>
      'It was not possible to determine the exact type of NAT on your network (or you are using the Web version).';

  @override
  String get donationTitle => 'Support the Project!';

  @override
  String get donationDesc =>
      'Enjoying CallMe? We charge nothing. If you want to help pay for Relay servers and keep the project alive, make a donation of any amount!';

  @override
  String get donationPixCopied => 'PIX Key copied to clipboard!';

  @override
  String get donationCopyPix => 'Copy PIX Key';

  @override
  String get donationClose => 'Close';

  @override
  String get createServerDialogTitle => 'Create Your Server';

  @override
  String get createServerDialogDesc =>
      'Your server is where you and your friends hang out. Create yours and start talking freely.';

  @override
  String get createServerDialogNameLabel => 'SERVER NAME';

  @override
  String get createServerDialogNameHint => 'My P2P Server';

  @override
  String get cancel => 'Cancel';

  @override
  String createServerDialogError(String error) {
    return 'Error creating server: $error';
  }
}
