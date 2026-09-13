import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Raw provider identity handed back to the UI layer. [idToken] is either a
/// Google id_token or an Apple identity_token — the backend distinguishes
/// them by which endpoint receives it, never by inspecting this class.
/// [firstName]/[lastName] are Apple-only and only ever non-null on the
/// user's very first authorization with this app.
class SocialAuthResult {
  const SocialAuthResult({required this.idToken, this.firstName, this.lastName});

  final String idToken;
  final String? firstName;
  final String? lastName;
}

/// Thrown when the user backs out of the provider's sign-in flow. Callers
/// should treat this as a silent no-op, not an error to surface.
class SocialAuthCancelledException implements Exception {}

class SocialAuthFailedException implements Exception {
  SocialAuthFailedException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps google_sign_in / sign_in_with_apple so the rest of the app never
/// touches plugin-specific types.
class SocialAuthService {
  static Future<SocialAuthResult> signInWithGoogle({String? webClientId}) async {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email'],
      clientId: webClientId,
    );
    final GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } catch (error) {
      throw SocialAuthFailedException('Google sign-in failed: $error');
    }
    if (account == null) throw SocialAuthCancelledException();
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw SocialAuthFailedException('Google did not return an identity token.');
    }
    return SocialAuthResult(idToken: idToken);
  }

  static Future<SocialAuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw SocialAuthFailedException('Apple did not return an identity token.');
      }
      return SocialAuthResult(
        idToken: identityToken,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw SocialAuthCancelledException();
      }
      throw SocialAuthFailedException('Apple sign-in failed: ${error.message}');
    }
  }
}
