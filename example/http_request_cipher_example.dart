import 'package:dio/dio.dart';
import 'package:http_request_cipher/http_request_cipher.dart';
import 'package:http_request_cipher/src/client_adapters/dio_client_adapter.dart';

const kRawEchoApiUrl = 'http://0.0.0.0:3000/example/echo_server.php';
void main() {
  /// run php serve with `php -S 0.0.0.0:3000`
  rrrr();
  errr();
  erdr();
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
