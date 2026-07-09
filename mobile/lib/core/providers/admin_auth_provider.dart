import 'package:flutter/foundation.dart';

/// Direct port of `core/state/admin-auth.service.ts`.
///
/// THIS IS NOT REAL SECURITY. It's a single shared passphrase compared
/// in-app, visible to anyone who decompiles the shipped app bundle - it
/// only stops casual/accidental access, nothing more. Real staff auth
/// (accounts, roles, server-side session checks) needs to come from the
/// Laravel backend - see docs/api-spec.md's "Admin endpoints" section,
/// which already assumes real auth in front of every admin route.
///
/// Change this before shipping this feature to any real build.
///
/// Unlike the web version (which persists sign-in for the browser tab via
/// sessionStorage), this stays in-memory only and resets on every cold
/// app launch - arguably the more appropriate default for a mobile app.
const String _adminPassphrase = 'skillbox2026';

class AdminAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  bool login(String passphrase) {
    final ok = passphrase == _adminPassphrase;
    if (ok) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return ok;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
