import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf_io.dart' as io;
import 'package:taxos_api/auth.dart';
import 'package:taxos_api/server.dart';

Future<void> main() async {
  final env = Platform.environment;
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;

  // TAXOS_AUTH_SECRET: base64, 32+ bytes. Without it, sessions do not survive
  // a restart, which is fine for development only.
  final secretB64 = env['TAXOS_AUTH_SECRET'];
  final secret = secretB64 != null
      ? base64.decode(secretB64)
      : List<int>.generate(32, (_) => Random.secure().nextInt(256));
  if (secretB64 == null) {
    stderr.writeln('TAXOS_AUTH_SECRET not set; using a random secret for this run.');
  }
  final devOtp = env['TAXOS_DEV_OTP'] == '1';
  if (devOtp) stderr.writeln('TAXOS_DEV_OTP=1: OTP codes are returned in responses. Never enable in production.');

  final auth = AuthService(
    secret: secret,
    devMode: devOtp,
    sender: LogOtpSender(stderr.writeln),
  );
  final server = await io.serve(buildHandler(auth: auth), InternetAddress.anyIPv4, port);
  stdout.writeln('TaxOS API listening on http://${server.address.host}:${server.port} (engine $engineVersion)');
}
