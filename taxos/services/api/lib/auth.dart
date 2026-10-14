import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Delivers a one-time code to a phone number. Production plugs in an SMS
/// gateway (MSG91, Gupshup, Twilio); development logs it.
abstract interface class OtpSender {
  Future<void> send(String phone, String code);
}

class LogOtpSender implements OtpSender {
  const LogOtpSender(this.log);
  final void Function(String) log;

  @override
  Future<void> send(String phone, String code) async =>
      log('OTP for +91 ${phone.substring(0, 2)}XXXXXX${phone.substring(8)}: $code');
}

class AuthException implements Exception {
  const AuthException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  @override
  String toString() => '$code: $message';
}

class OtpRequestResult {
  const OtpRequestResult({required this.expiresIn, this.devCode});
  final Duration expiresIn;

  /// Only set when dev mode is on, so the app can sign in without SMS.
  final String? devCode;
}

class Session {
  const Session({required this.token, required this.phone, required this.expiresAt});
  final String token;
  final String phone;
  final DateTime expiresAt;
}

class Claims {
  const Claims({required this.phone, required this.jti, required this.expiresAt});
  final String phone;
  final String jti;
  final DateTime expiresAt;
}

class _Pending {
  _Pending(this.hash, this.expiresAt, this.sentAt);
  final String hash;
  final DateTime expiresAt;
  final DateTime sentAt;
  int attempts = 0;
}

/// Phone + OTP sign-in with HMAC-signed bearer tokens.
///
/// State is in memory: right for one instance and for tests. Behind a load
/// balancer the pending codes and the revocation list move to Redis.
class AuthService {
  AuthService({
    required List<int> secret,
    required this.sender,
    this.devMode = false,
    DateTime Function()? clock,
    Random? random,
  })  : _hmac = Hmac(sha256, secret),
        _now = clock ?? DateTime.now,
        _random = random ?? Random.secure() {
    if (secret.length < 32) {
      throw ArgumentError('Auth secret must be at least 32 bytes');
    }
  }

  static const otpLifetime = Duration(minutes: 5);
  static const resendCooldown = Duration(seconds: 30);
  static const maxAttempts = 5;
  static const sessionLifetime = Duration(days: 30);

  final OtpSender sender;
  final bool devMode;
  final Hmac _hmac;
  final DateTime Function() _now;
  final Random _random;
  final _pending = <String, _Pending>{};
  final _revoked = <String, DateTime>{};

  /// Accepts 10-digit Indian mobiles with or without +91 / 0 prefix.
  static String normalisePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('91')) digits = digits.substring(2);
    if (digits.length == 11 && digits.startsWith('0')) digits = digits.substring(1);
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(digits)) {
      throw const AuthException(400, 'invalid_phone', 'Enter a 10-digit Indian mobile number.');
    }
    return digits;
  }

  Future<OtpRequestResult> requestOtp(String rawPhone) async {
    final phone = normalisePhone(rawPhone);
    final now = _now();
    final existing = _pending[phone];
    if (existing != null && now.difference(existing.sentAt) < resendCooldown) {
      final wait = resendCooldown - now.difference(existing.sentAt);
      throw AuthException(429, 'too_soon', 'Wait ${wait.inSeconds + 1} seconds before asking for a new code.');
    }
    final code = List.generate(6, (_) => _random.nextInt(10)).join();
    _pending[phone] = _Pending(_hashCode(phone, code), now.add(otpLifetime), now);
    await sender.send(phone, code);
    return OtpRequestResult(expiresIn: otpLifetime, devCode: devMode ? code : null);
  }

  Session verifyOtp(String rawPhone, String code) {
    final phone = normalisePhone(rawPhone);
    final pending = _pending[phone];
    final now = _now();
    if (pending == null || now.isAfter(pending.expiresAt)) {
      _pending.remove(phone);
      throw const AuthException(401, 'code_expired', 'That code has expired. Ask for a new one.');
    }
    if (pending.attempts >= maxAttempts) {
      _pending.remove(phone);
      throw const AuthException(429, 'too_many_attempts', 'Too many wrong codes. Ask for a new one.');
    }
    pending.attempts++;
    if (!_constantTimeEquals(pending.hash, _hashCode(phone, code.trim()))) {
      throw const AuthException(401, 'wrong_code', 'That code is not right.');
    }
    _pending.remove(phone);
    return _issue(phone, now);
  }

  Claims validate(String token) {
    final parts = token.split('.');
    if (parts.length != 2) throw const AuthException(401, 'invalid_token', 'Sign in again.');
    final expected = _sign(parts[0]);
    if (!_constantTimeEquals(expected, parts[1])) {
      throw const AuthException(401, 'invalid_token', 'Sign in again.');
    }
    final Map<String, Object?> payload;
    try {
      payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))))
          as Map<String, Object?>;
    } catch (_) {
      throw const AuthException(401, 'invalid_token', 'Sign in again.');
    }
    final exp = DateTime.fromMillisecondsSinceEpoch((payload['exp'] as num).toInt() * 1000, isUtc: true);
    final jti = payload['jti'] as String;
    if (_now().isAfter(exp) || _revoked.containsKey(jti)) {
      throw const AuthException(401, 'session_ended', 'Your session has ended. Sign in again.');
    }
    return Claims(phone: payload['sub'] as String, jti: jti, expiresAt: exp);
  }

  /// Signs the session out everywhere this token is used.
  void revoke(String token) {
    final claims = validate(token);
    _revoked[claims.jti] = claims.expiresAt;
    _revoked.removeWhere((_, exp) => _now().isAfter(exp));
  }

  Session _issue(String phone, DateTime now) {
    final exp = now.add(sessionLifetime).toUtc();
    final jti = List.generate(16, (_) => _random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({
          'sub': phone,
          'jti': jti,
          'iat': now.toUtc().millisecondsSinceEpoch ~/ 1000,
          'exp': exp.millisecondsSinceEpoch ~/ 1000,
        })))
        .replaceAll('=', '');
    return Session(token: '$payload.${_sign(payload)}', phone: phone, expiresAt: exp);
  }

  String _sign(String payload) =>
      base64Url.encode(_hmac.convert(utf8.encode(payload)).bytes).replaceAll('=', '');

  String _hashCode(String phone, String code) =>
      _hmac.convert(utf8.encode('otp:$phone:$code')).toString();

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
