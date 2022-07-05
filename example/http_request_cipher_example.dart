import 'package:dio/dio.dart';
import 'package:stream_cipher/http_request_cipher.dart';
import 'package:stream_cipher/src/client_adapters/dio_client_adapter.dart';

import 'sample_dart_backend.dart';

const kServerPort = 8092;
const kRawEchoApiUrl = 'http://0.0.0.0:3000/example/echo_server.php';
const kDecodedEchoAPIUrl = 'http://0.0.0.0:$kServerPort/';
Future<void> main() async {
  /// run php serve with `php -S 0.0.0.0:3000`
  /// these items need php to work
  rrrr();
  errr();
  erdr();

  /// this one will run a server backed by dart and will encrypt when posting
  /// but servers response will be encrypted body of request.
  final server = await dartBackEnd();
  await erdr2();
  server.close(force: true);
}

void rrrr() {
  final encrypter = NoEncryptionByteDataEncrypter();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CypherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    useBase64: true,
  );

  final dio = Dio()..httpClientAdapter = dioClient;
  dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    print('Raw request -> Raw response: ${response.data}');
  });
}

void errr() {
  final encrypter = AESByteDataEncrypter.randomSecureKey();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CypherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    useBase64: true,
  );

  final dio = Dio()..httpClientAdapter = dioClient;
  dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    print('Encrypted request -> raw response: ${response.data}');
  });
}

void erdr() {
  final encrypter = AESByteDataEncrypter.randomSecureKey();
  final decrypter = AESByteDataDecrypter(key: encrypter.key, iv: encrypter.iv);
  final dioClient = CypherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    useBase64: true,
  );

  final dio = Dio()..httpClientAdapter = dioClient;

  dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    print('Encrypted request -> decrypted response: ${response.data}');
  });
}

Future<void> erdr2() async {
  final encrypter = AESByteDataEncrypter.empty();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CypherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: 5,
  );

  final dio = Dio()..httpClientAdapter = dioClient;

  final response = await dio.post(
    kDecodedEchoAPIUrl,
    data: '{"note":"this will be encrypted"}',
  );
  print('Encrypted request -> decrypted in backend: ${response.data}');
}
