import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf_io.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:stream_cipher/stream_cipher.dart';

import 'stream_cipher_example.dart';

FutureOr<Response> Function(Request) cipherMiddleWare(
  FutureOr<Response> Function(Request) innerHandler,
) {
  return (Request request) async {
    final decrypter = AESByteDataDecrypter.empty();

    final deStream = decrypter.alterDecryptStream(
      request.body.asBinary.map(Uint8List.fromList),
      streamMeta: const EncryptStreamMeta(
        ending: '#ENDING#',
        separator: '#SEPARATOR#',
      ),
    );
    final buffer = <int>[];
    await deStream.forEach(buffer.addAll);

    return innerHandler(
      request.change(body: buffer),
    );
  };
}

Future<HttpServer> dartBackEnd() async {
  final webServer = Router().plus
    ..post(
      '/decoded_echo',
      (Request request) async {
        final decrypter = AESByteDataDecrypter.empty();
        final deStream = decrypter.alterDecryptStream(
          request.read().map(Uint8List.fromList),
          streamMeta: const EncryptStreamMeta(
            ending: '#ENDING#',
            separator: '#SEPARATOR#',
          ),
        );
        final buffer = <int>[];
        await deStream.forEach(buffer.addAll);
        return Response(200, body: String.fromCharCodes(buffer));
      },
    )
    ..post(
      '/raw_echo',
      (Request request) async {
        // final decrypter = AESByteDataDecrypter.empty();
        return Response(
          200,
          body: request.body.asBinary,
        );
      },
      use: cipherMiddleWare,
    );
  final server = await serve(webServer, '0.0.0.0', kServerPort);
  print('awaiting for request on port $kServerPort');
  return server;
}
