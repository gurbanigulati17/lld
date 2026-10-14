import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_engine/tax_engine.dart';

/// Thin client for the Kardo API service. The server runs the same engine
/// package; this is used to confirm the on-device result before filing.
class TaxosApiClient {
  TaxosApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<ServerVerification> verifyItr(ItrInput input) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/v1/itr/compare'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(input.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw ApiException('Server returned ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, Object?>;
    final rec = json['recommended'] as String;
    final best = json[rec] as Map<String, Object?>;
    return ServerVerification(
      recommended: TaxRegime.values.byName(rec),
      totalTaxLiability: (best['totalTaxLiability'] as num).toInt(),
      netPayable: (best['netPayable'] as num).toInt(),
      engineVersion: (json['engineVersion'] as String?) ?? 'unknown',
    );
  }

  Future<bool> health() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class ServerVerification {
  const ServerVerification({
    required this.recommended,
    required this.totalTaxLiability,
    required this.netPayable,
    required this.engineVersion,
  });

  final TaxRegime recommended;
  final int totalTaxLiability;
  final int netPayable;
  final String engineVersion;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
