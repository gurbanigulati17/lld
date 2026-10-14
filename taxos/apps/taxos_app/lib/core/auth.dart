import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'draft_store.dart';
import 'settings.dart';

/// A signed-in user.
class AuthSession {
  const AuthSession({
    required this.phone,
    required this.token,
    required this.expiresAt,
    this.name = '',
    this.demo = false,
  });

  /// 10-digit Indian mobile.
  final String phone;
  final String token;
  final DateTime expiresAt;
  final String name;

  /// True when signed in with an on-device demo code (no server).
  final bool demo;

  bool get expired => DateTime.now().isAfter(expiresAt);

  String get maskedPhone => '+91 ${phone.substring(0, 2)}••• ••${phone.substring(7)}';

  AuthSession copyWith({String? name}) => AuthSession(
        phone: phone,
        token: token,
        expiresAt: expiresAt,
        name: name ?? this.name,
        demo: demo,
      );

  Map<String, Object?> toJson() => {
        'phone': phone,
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
        'name': name,
        'demo': demo,
      };

  factory AuthSession.fromJson(Map<String, Object?> j) => AuthSession(
        phone: j['phone'] as String,
        token: j['token'] as String,
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        name: (j['name'] as String?) ?? '',
        demo: (j['demo'] as bool?) ?? false,
      );
}

class OtpChallenge {
  const OtpChallenge({required this.phone, required this.expiresIn, this.demoCode});
  final String phone;
  final Duration expiresIn;

  /// Shown on screen in demo mode, since no SMS is sent.
  final String? demoCode;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Accepts 10-digit Indian mobiles with or without +91 or 0.
String normalisePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 12 && digits.startsWith('91')) digits = digits.substring(2);
  if (digits.length == 11 && digits.startsWith('0')) digits = digits.substring(1);
  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(digits)) {
    throw const AuthFailure('Enter a 10-digit Indian mobile number.');
  }
  return digits;
}

abstract interface class AuthRepository {
  Future<OtpChallenge> requestOtp(String phone);
  Future<AuthSession> verifyOtp(String phone, String code);
  Future<void> signOut(AuthSession session);
}

/// Talks to the Kardo API (`/v1/auth/*`).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;

  Future<Map<String, Object?>> _post(String path, Map<String, Object?> body, {String? token}) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'content-type': 'application/json',
              if (token != null) 'authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthFailure('Could not reach Kardo. Check your connection and try again.');
    }
    final json = res.body.isEmpty ? <String, Object?>{} : jsonDecode(res.body) as Map<String, Object?>;
    if (res.statusCode != 200) {
      throw AuthFailure((json['message'] as String?) ?? 'Something went wrong. Try again.');
    }
    return json;
  }

  @override
  Future<OtpChallenge> requestOtp(String phone) async {
    final p = normalisePhone(phone);
    final r = await _post('/v1/auth/otp/request', {'phone': p});
    return OtpChallenge(
      phone: p,
      expiresIn: Duration(seconds: (r['expiresIn'] as num?)?.toInt() ?? 300),
      demoCode: r['devCode'] as String?,
    );
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    final p = normalisePhone(phone);
    final r = await _post('/v1/auth/otp/verify', {'phone': p, 'code': code});
    return AuthSession(
      phone: p,
      token: r['token'] as String,
      expiresAt: DateTime.parse(r['expiresAt'] as String),
    );
  }

  @override
  Future<void> signOut(AuthSession session) async {
    try {
      await _post('/v1/auth/logout', const {}, token: session.token);
    } catch (_) {
      // Signing out locally must always succeed, even offline.
    }
  }
}

/// On-device sign-in for builds without a server. Codes are generated and
/// shown on screen; nothing leaves the phone.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({Random? random, this.fixedCode = const String.fromEnvironment('KARDO_DEMO_FIXED_CODE')})
      : _random = random ?? Random.secure();
  final Random _random;

  /// Set only for scripted screenshot builds; empty in real builds.
  final String fixedCode;
  final _codes = <String, (String, DateTime)>{};

  @override
  Future<OtpChallenge> requestOtp(String phone) async {
    final p = normalisePhone(phone);
    final code = fixedCode.isNotEmpty ? fixedCode : List.generate(6, (_) => _random.nextInt(10)).join();
    _codes[p] = (code, DateTime.now().add(const Duration(minutes: 5)));
    return OtpChallenge(phone: p, expiresIn: const Duration(minutes: 5), demoCode: code);
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    final p = normalisePhone(phone);
    final entry = _codes[p];
    if (entry == null || DateTime.now().isAfter(entry.$2)) {
      throw const AuthFailure('That code has expired. Ask for a new one.');
    }
    if (entry.$1 != code.trim()) throw const AuthFailure('That code is not right.');
    _codes.remove(p);
    return AuthSession(
      phone: p,
      token: 'demo-${List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join()}',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      demo: true,
    );
  }

  @override
  Future<void> signOut(AuthSession session) async {}
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(configProvider);
  return config.hasServer ? ApiAuthRepository(config.apiBaseUrl) : DemoAuthRepository();
});

/// Where the session is kept: Android Keystore / iOS Keychain.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

/// The current session, or null when signed out.
class AuthController extends AsyncNotifier<AuthSession?> {
  static const _key = 'kardo.session.v1';

  @override
  Future<AuthSession?> build() async {
    try {
      final raw = await ref.read(secureStorageProvider).read(key: _key);
      if (raw == null) return null;
      final session = AuthSession.fromJson(jsonDecode(raw) as Map<String, Object?>);
      return session.expired ? null : session;
    } catch (_) {
      return null;
    }
  }

  Future<void> signedIn(AuthSession session) async {
    await _persist(session);
    state = AsyncData(session);
  }

  Future<void> setName(String name) async {
    final s = state.valueOrNull;
    if (s == null) return;
    final next = s.copyWith(name: name.trim());
    await _persist(next);
    state = AsyncData(next);
  }

  /// Revokes the session on the server (when there is one), deletes it from
  /// secure storage and clears tax drafts saved on this phone.
  Future<void> signOut() async {
    final s = state.valueOrNull;
    if (s != null) await ref.read(authRepositoryProvider).signOut(s);
    try {
      await ref.read(secureStorageProvider).delete(key: _key);
    } catch (_) {}
    await const DraftStore().clearAll();
    state = const AsyncData(null);
  }

  Future<void> _persist(AuthSession s) async {
    try {
      await ref.read(secureStorageProvider).write(key: _key, value: jsonEncode(s.toJson()));
    } catch (_) {}
  }
}

final authProvider = AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);
