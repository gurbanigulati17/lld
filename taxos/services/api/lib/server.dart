import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:tax_engine/tax_engine.dart';

import 'auth.dart';

/// Engine version reported to clients so the app can confirm it ran the
/// same rules. Bump with the engine package.
const engineVersion = '0.1.0';

/// Builds the API handler. Kept free of `dart:io` so tests can call it
/// in-process without opening a socket.
Handler buildHandler({required AuthService auth}) {
  final router = Router()
    ..get('/health', _health)
    ..post('/v1/auth/otp/request', (Request req) async {
      final body = await _body(req);
      final r = await auth.requestOtp((body['phone'] as String?) ?? '');
      return _json({
        'sent': true,
        'expiresIn': r.expiresIn.inSeconds,
        if (r.devCode != null) 'devCode': r.devCode,
      });
    })
    ..post('/v1/auth/otp/verify', (Request req) async {
      final body = await _body(req);
      final s = auth.verifyOtp((body['phone'] as String?) ?? '', (body['code'] as String?) ?? '');
      return _json({
        'token': s.token,
        'expiresAt': s.expiresAt.toIso8601String(),
        'user': {'phone': s.phone},
      });
    })
    ..get('/v1/auth/me', (Request req) {
      final claims = auth.validate(_bearer(req));
      return _json({'phone': claims.phone, 'expiresAt': claims.expiresAt.toIso8601String()});
    })
    ..post('/v1/auth/logout', (Request req) {
      auth.revoke(_bearer(req));
      return _json({'signedOut': true});
    })
    ..post('/v1/itr/compute', _itrCompute)
    ..post('/v1/itr/compare', _itrCompare)
    ..post('/v1/itr/form', _itrForm)
    ..post('/v1/gst/gstr3b', _gstr3b)
    ..post('/v1/gst/reconcile', _reconcile)
    ..post('/v1/gst/registration', _registration);

  return const Pipeline()
      .addMiddleware(_cors())
      .addMiddleware(logRequests())
      .addMiddleware(_jsonErrors())
      .addHandler(router.call);
}

Response _health(Request _) => _json({
      'status': 'ok',
      'engineVersion': engineVersion,
      'assessmentYears': [for (final ay in AssessmentYear.values) ay.name],
    });

Future<Response> _itrCompute(Request req) async {
  final body = await _body(req);
  final input = ItrInput.fromJson(body['input'] as Map<String, Object?>? ?? body);
  final regimeName = body['regime'] as String?;
  final regime = regimeName == null
      ? null
      : TaxRegime.values.byName(regimeName);
  const computer = ItrComputer();
  final result = regime == null
      ? computer.compare(input).best
      : computer.compute(input, regime);
  return _json({
    'engineVersion': engineVersion,
    'computation': result.toJson(),
    'explanation': const ExplanationBuilder().explain(result),
  });
}

Future<Response> _itrCompare(Request req) async {
  final input = ItrInput.fromJson(await _body(req));
  final cmp = const ItrComputer().compare(input);
  return _json({
    'engineVersion': engineVersion,
    ...cmp.toJson(),
    'form': selectForm(input, totalIncome: cmp.best.totalIncome).toJson(),
    'explanation': const ExplanationBuilder().explainComparison(cmp),
  });
}

Future<Response> _itrForm(Request req) async {
  final input = ItrInput.fromJson(await _body(req));
  final best = const ItrComputer().compare(input).best;
  return _json(selectForm(input, totalIncome: best.totalIncome).toJson());
}

Future<Response> _gstr3b(Request req) async {
  final input = Gstr3bInput.fromJson(await _body(req));
  return _json({
    'engineVersion': engineVersion,
    ...const Gstr3bComputer().compute(input).toJson(),
  });
}

Future<Response> _reconcile(Request req) async {
  final body = await _body(req);
  List<GstInvoice> parse(String key) => ((body[key] as List?) ?? const [])
      .map((e) => GstInvoice.fromJson(e as Map<String, Object?>))
      .toList();
  final tolerance = (body['toleranceRupees'] as num?)?.toInt() ?? 1;
  final r = Gstr2bReconciler(toleranceRupees: tolerance)
      .reconcile(books: parse('books'), statement: parse('statement'));
  return _json(r.toJson());
}

Future<Response> _registration(Request req) async {
  final b = await _body(req);
  final advice = const GstRegistrationAdvisor().advise(GstRegistrationInput(
    aggregateTurnover: (b['aggregateTurnover'] as num?)?.toInt() ?? 0,
    nature: SupplyNature.values.byName((b['nature'] as String?) ?? 'services'),
    inSpecialCategoryState: (b['inSpecialCategoryState'] as bool?) ?? false,
    makesInterStateSupplies: (b['makesInterStateSupplies'] as bool?) ?? false,
    sellsThroughEcommerce: (b['sellsThroughEcommerce'] as bool?) ?? false,
    isCasualOrNonResident: (b['isCasualOrNonResident'] as bool?) ?? false,
    liableUnderReverseCharge: (b['liableUnderReverseCharge'] as bool?) ?? false,
  ));
  return _json(advice.toJson());
}

// ---------------------------------------------------------------------------

Future<Map<String, Object?>> _body(Request req) async {
  final text = await req.readAsString();
  if (text.isEmpty) throw const FormatException('Empty request body');
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object');
  }
  return decoded;
}

String _bearer(Request req) {
  final h = req.headers['authorization'] ?? '';
  if (!h.startsWith('Bearer ')) {
    throw const AuthException(401, 'missing_token', 'Sign in first.');
  }
  return h.substring(7).trim();
}

Response _json(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Middleware _jsonErrors() => (inner) => (req) async {
      try {
        return await inner(req);
      } on AuthException catch (e) {
        return _json({'error': e.code, 'message': e.message}, status: e.status);
      } on FormatException catch (e) {
        return _json({'error': 'bad_request', 'message': e.message}, status: 400);
      } on ArgumentError catch (e) {
        return _json({'error': 'bad_request', 'message': e.message.toString()}, status: 400);
      } on TypeError catch (e) {
        return _json({'error': 'bad_request', 'message': e.toString()}, status: 400);
      }
    };

Middleware _cors() => (inner) => (req) async {
      const headers = {
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET, POST, OPTIONS',
        'access-control-allow-headers': 'content-type, authorization',
      };
      if (req.method == 'OPTIONS') return Response.ok('', headers: headers);
      final res = await inner(req);
      return res.change(headers: headers);
    };
