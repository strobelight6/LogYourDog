/// Build-time configuration via --dart-define flags.
///
/// Emulator mode (local dev):
///   flutter run --dart-define=USE_EMULATOR=true
///
/// Production (all FIREBASE_* values required):
///   flutter run \
///     --dart-define=FIREBASE_API_KEY=... \
///     --dart-define=FIREBASE_APP_ID=... \
///     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///     --dart-define=FIREBASE_PROJECT_ID=... \
///     --dart-define=FIREBASE_STORAGE_BUCKET=...
///
/// In practice, store these in .vscode/launch.json (gitignored) or CI secrets.
library;

class Env {
  static const bool useEmulator =
      bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

  static const String firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String firebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String firebaseIosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: '');
}
