import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:stream_cipher/http_request_cipher.dart';

import 'http_request_cipher_example.dart';

Future<HttpServer> dartBackEnd() async {
  final webServer = Router()
    ..post(
      '/',
      (Request request) async {
        final decrypter = AESByteDataDecrypter.empty();
        final deStream = decrypter.alterDecryptStream(
          request.read().asyncMap(Uint8List.fromList),
          streamMeta: const EncryptStreamMeta(
            ending: '#ENDING#',
            separator: '#SEPARATOR#',
          ),
        );
        final buffer = <int>[];
        await deStream.forEach(buffer.addAll);
        return Response(200, body: String.fromCharCodes(buffer));
      },
    );
  var server = await serve(webServer, '0.0.0.0', kServerPort);
  print('awaiting for request on port $kServerPort');
  return server;
}
