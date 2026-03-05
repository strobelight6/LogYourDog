import 'package:firebase_core/firebase_core.dart';
import 'config/env.dart';

/// Provides [FirebaseOptions] built from --dart-define values.
///
/// In emulator mode (USE_EMULATOR=true), placeholder values are used —
/// the emulator does not validate API keys or app IDs.
///
/// For production, supply real values via --dart-define flags.
/// The conventional way is to let `flutterfire configure` generate
/// lib/firebase_options.dart (gitignored) and import DefaultFirebaseOptions
/// from there, then swap this class out.
class FirebaseConfig {
  static const String _emulatorProjectId = 'log-your-dog-local';

  static FirebaseOptions get currentPlatform {
    if (Env.useEmulator || Env.firebaseProjectId.isEmpty) {
      return const FirebaseOptions(
        apiKey: 'emulator-placeholder-api-key',
        appId: '1:000000000000:ios:0000000000000000',
        messagingSenderId: '000000000000',
        projectId: _emulatorProjectId,
        storageBucket: '$_emulatorProjectId.appspot.com',
      );
    }

    return FirebaseOptions(
      apiKey: Env.firebaseApiKey,
      appId: Env.firebaseAppId,
      messagingSenderId: Env.firebaseMessagingSenderId,
      projectId: Env.firebaseProjectId,
      storageBucket: Env.firebaseStorageBucket,
      iosBundleId: Env.firebaseIosBundleId.isNotEmpty ? Env.firebaseIosBundleId : null,
    );
  }
}
