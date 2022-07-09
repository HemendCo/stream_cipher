import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf_io.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:stream_cipher/stream_cipher.dart';

import 'stream_cipher_example.dart';

FutureOr<Response> Function(Request) decryptRequestMiddleware(
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

FutureOr<Response> Function(Request) encryptResponseMiddleware(
  FutureOr<Response> Function(Request) innerHandler,
) {
  return (Request request) async {
    final encrypter = AESByteDataEncrypter.empty();
    final result = await innerHandler(
      request,
    );

    final deStream = encrypter.alterEncryptStream(
      result.read().map(Uint8List.fromList),
      streamMeta: const EncryptStreamMeta(
        ending: '#ENDING#',
        separator: '#SEPARATOR#',
      ),
    );
    final buffer = <int>[];
    await deStream.forEach(buffer.addAll);
    return result.change(body: buffer);
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
    )
    ..post(
      '/middle_cipher',
      (Request request) async {
        final test = await request.body.asString;
        final data = jsonDecode(test);
        logger.i('note in back end (MiddleWare): ${data['note']}', null, StackTrace.fromString('BackEnd'));
        return Response(
          200,
          body: test,
        );
      },
      use: decryptRequestMiddleware + encryptResponseMiddleware,
    );
  final server = await serve(webServer, '0.0.0.0', kServerPort);
  logger.i('awaiting for request on port $kServerPort', null, StackTrace.fromString('BackEnd'));

  return server;
}
