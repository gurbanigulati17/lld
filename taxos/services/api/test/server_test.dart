import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:taxos_api/server.dart';
import 'package:test/test.dart';

Future<Map<String, Object?>> call(
  Handler h,
  String method,
  String path, [
  Object? body,
]) async {
  final req = Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body == null ? null : jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
  final res = await h(req);
  final json = jsonDecode(await res.readAsString()) as Map<String, Object?>;
  json['_status'] = res.statusCode;
  return json;
}

void main() {
  final h = buildHandler();

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
}
