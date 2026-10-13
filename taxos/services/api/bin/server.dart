import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:taxos_api/server.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(buildHandler(), InternetAddress.anyIPv4, port);
  stdout.writeln('TaxOS API listening on http://${server.address.host}:${server.port} (engine $engineVersion)');
}
