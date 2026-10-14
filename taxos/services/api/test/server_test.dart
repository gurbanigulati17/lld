import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:taxos_api/auth.dart';
import 'package:taxos_api/server.dart';
import 'package:test/test.dart';

Future<Map<String, Object?>> call(
  Handler h,
  String method,
  String path, [
  Object? body,
  String? token,
]) async {
  final req = Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body == null ? null : jsonEncode(body),
    headers: {
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    },
  );
  final res = await h(req);
  final json = jsonDecode(await res.readAsString()) as Map<String, Object?>;
  json['_status'] = res.statusCode;
  return json;
}

class _CapturingSender implements OtpSender {
  final sent = <String, String>{};
  @override
  Future<void> send(String phone, String code) async => sent[phone] = code;
}

void main() {
  final sender = _CapturingSender();
  final h = buildHandler(
    auth: AuthService(secret: List.filled(32, 7), sender: sender),
  );

  test('health', () async {
    final r = await call(h, 'GET', '/health');
    expect(r['_status'], 200);
    expect(r['engineVersion'], engineVersion);
  });

  test('compare returns both regimes and the recommendation', () async {
    final r = await call(h, 'POST', '/v1/itr/compare', {
      'assessmentYear': 'ay2026_27',
      'profile': {'ageCategory': 'below60'},
      'salary': {'basic': 600000, 'otherTaxableComponents': 675000},
    });
    expect(r['_status'], 200);
    expect(r['recommended'], 'newRegime');
    expect((r['newRegime'] as Map)['totalTaxLiability'], 0);
    expect((r['form'] as Map)['form'], 'itr1');
  });

  test('compute with explicit regime', () async {
    final r = await call(h, 'POST', '/v1/itr/compute', {
      'regime': 'oldRegime',
      'input': {
        'assessmentYear': 'ay2026_27',
        'profile': {'ageCategory': 'below60'},
        'salary': {'basic': 540000},
      },
    });
    expect(r['_status'], 200);
    expect((r['computation'] as Map)['regime'], 'oldRegime');
    expect((r['computation'] as Map)['totalTaxLiability'], 0);
    expect(r['explanation'], isA<List>());
  });

  test('gstr3b', () async {
    final r = await call(h, 'POST', '/v1/gst/gstr3b', {
      'period': '2025-09',
      'outwardSupplies': [
        {'taxableValue': 100000, 'ratePercent': 18, 'interState': false},
      ],
      'itcAvailable': {'cgst': 20000},
    });
    expect(r['_status'], 200);
    expect((r['cashPayable'] as Map)['sgst'], 9000);
  });

  test('bad JSON is a 400 not a crash', () async {
    final req = Request('POST', Uri.parse('http://localhost/v1/itr/compare'), body: '{not json');
    final res = await h(req);
    expect(res.statusCode, 400);
    final wrong = await call(h, 'POST', '/v1/itr/compare', {'assessmentYear': 'ay1999'});
    expect(wrong['_status'], 400);
  });

  group('auth', () {
    test('OTP sign-in, me, logout, and the token stops working', () async {
      final req = await call(h, 'POST', '/v1/auth/otp/request', {'phone': '+91 98765 43210'});
      expect(req['_status'], 200);
      expect(req.containsKey('devCode'), isFalse);
      final code = sender.sent['9876543210']!;

      final wrong = await call(h, 'POST', '/v1/auth/otp/verify', {'phone': '9876543210', 'code': code == '000000' ? '111111' : '000000'});
      expect(wrong['_status'], 401);
      expect(wrong['error'], 'wrong_code');

      final ok = await call(h, 'POST', '/v1/auth/otp/verify', {'phone': '9876543210', 'code': code});
      expect(ok['_status'], 200);
      final token = ok['token'] as String;

      final me = await call(h, 'GET', '/v1/auth/me', null, token);
      expect(me['phone'], '9876543210');

      final out = await call(h, 'POST', '/v1/auth/logout', null, token);
      expect(out['signedOut'], isTrue);
      final after = await call(h, 'GET', '/v1/auth/me', null, token);
      expect(after['_status'], 401);
    });

    test('rejects bad numbers, fast resends and tampered tokens', () async {
      final bad = await call(h, 'POST', '/v1/auth/otp/request', {'phone': '12345'});
      expect(bad['_status'], 400);
      await call(h, 'POST', '/v1/auth/otp/request', {'phone': '9123456789'});
      final again = await call(h, 'POST', '/v1/auth/otp/request', {'phone': '9123456789'});
      expect(again['_status'], 429);
      final tampered = await call(h, 'GET', '/v1/auth/me', null, 'eyJzdWIiOiI5OTk5OTk5OTk5In0.bad');
      expect(tampered['_status'], 401);
      final none = await call(h, 'GET', '/v1/auth/me');
      expect(none['_status'], 401);
    });

    test('codes expire and lock after five wrong attempts', () async {
      var now = DateTime(2026, 10, 14, 10);
      final s = _CapturingSender();
      final auth = AuthService(secret: List.filled(32, 3), sender: s, clock: () => now);
      await auth.requestOtp('9000000001');
      now = now.add(const Duration(minutes: 6));
      expect(() => auth.verifyOtp('9000000001', s.sent['9000000001']!),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'code_expired')));

      await auth.requestOtp('9000000002');
      for (var i = 0; i < 5; i++) {
        expect(() => auth.verifyOtp('9000000002', 'xxxxxx'), throwsA(isA<AuthException>()));
      }
      expect(() => auth.verifyOtp('9000000002', s.sent['9000000002']!),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'too_many_attempts')));
    });

    test('dev mode returns the code so the app can sign in without SMS', () async {
      final dev = buildHandler(auth: AuthService(secret: List.filled(32, 9), sender: _CapturingSender(), devMode: true));
      final r = await call(dev, 'POST', '/v1/auth/otp/request', {'phone': '9876500000'});
      expect(r['devCode'], matches(RegExp(r'^[0-9]{6}$')));
    });
  });
}
