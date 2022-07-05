// ignore_for_file: lines_longer_than_80_chars, prefer_foreach

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http_request_cipher/http_request_cipher.dart';
import 'package:http_request_cipher/src/client_adapters/extensions/request_encrypter.dart';
import 'package:http_request_cipher/src/client_adapters/extensions/response_decrypter.dart';
import 'package:test/test.dart';

void main() {
  group('Encryption Tests', () {
    const kRSAPublicKey = '''-----BEGIN PUBLIC KEY-----
MIGeMA0GCSqGSIb3DQEBAQUAA4GMADCBiAKBgHJnzr0orb3n7PF2/uhQUMpUpxuS
ZNb4Xh7GPrWMWUZNxBdWYPf0P7A56bvqRNoe8oYDYF2nd6HAkglCp2oN1j6nDFaV
b3mU94CiuGV2U5/0+lKtdkbv+lCTt9+PExoVWJEXlybjllLZuKboZNdJUpBjt0ZU
cCL0KXjtjrMXngJBAgMBAAE=
-----END PUBLIC KEY-----''';
    const kRSAPrivateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgHJnzr0orb3n7PF2/uhQUMpUpxuSZNb4Xh7GPrWMWUZNxBdWYPf0
P7A56bvqRNoe8oYDYF2nd6HAkglCp2oN1j6nDFaVb3mU94CiuGV2U5/0+lKtdkbv
+lCTt9+PExoVWJEXlybjllLZuKboZNdJUpBjt0ZUcCL0KXjtjrMXngJBAgMBAAEC
gYAdfGnJUQGuj2b/OPcr8v9Plo/XSFzbFvpTHi8tZXXg68wdY7LsVTRQ/CwktZV3
TkCdj6M3oCDyPIqm/lnduKE9/kDCbogNIkyp+eE5XOQhd+8zCzT/N3/Xzpbv1SXU
+QxIabnM16lDHN+1bl+Da017yu/FhpR8wDYMLwOe1lQhkQJBALTCJuGcWP/WrBFZ
mK6xAWSsKoVQ/F7DBAYlh6xyUyR+pUtHGfEJd/J2FqAXXXE3haxO2U9lViWJ1uJ8
01Ah4tUCQQCiBwErSsn50AePPtUNoiECqZAiz2VTQeNwiWE0ddp+b0qozIiJo4gq
KUs+4F79kp8Ktj6yl+W6aJSVcnNO+t+9AkARkQC4Ujpv+ovUT9G/wGHzR6wGMr2j
8+3TLxiFUML1u/0SWMGTpCjs/j7qpfqlwxCRk0QZLC74DPI+JoVetzxVAkEAgJE0
UUjoGc0DopvF7SqALR+lWqndCgKXWb35HuqBdKAUyvp5QVY8/s+DgKIDXgyRHKvd
9lLnnFHNzQRjEQGqtQJBALNSOnRuXR3yw48wE2YJTu1ofhPXdt9SG3dALnPlOgMF
Dov+DO4lUqWMJ4FWn27u9iUrCw7HWHfjFMIlxtoyc8E=
-----END RSA PRIVATE KEY-----''';

    var testString = Uint8List(0);
    const streamMeta = EncryptStreamMeta(
      ending: '#ENDING#',
      separator: '#SEPARATOR#',
    );
    setUp(() {
      final file = File('test/_test_file.exe');
      testString = Uint8List.fromList(
        base64Encode(
          file.readAsBytesSync(),
        ).codeUnits,
      );
    });
    test(
      'No Encryption Test Single-Shot ',
      () {
        final encrypter = NoEncryptionByteDataEncrypter();
        final decrypter = NoEncryptionByteDataDecrypter();
        final encrypted = encrypter.encrypt(testString);
        final decrypted = decrypter.decrypt(encrypted);
        expect(decrypted, testString);
      },
    );
    test(
      'No Encryption Test Single-Shot (Encrypt only) ',
      () {
        final simpleTestText = Uint8List.fromList('Sample text to test encryption basics'.codeUnits);
        final encrypter = NoEncryptionByteDataEncrypter();
        final encrypted = encrypter.encrypt(simpleTestText);
        expect(encrypted, simpleTestText);
      },
    );
    test(
      'No Encryption Test Single-Shot (Decrypt only)',
      () {
        final simpleTestText = Uint8List.fromList('Sample text to test encryption basics'.codeUnits);
        // final encrypter = NoEncryptionByteDataEncrypter();
        final decrypter = NoEncryptionByteDataDecrypter();
        // final encrypted = encrypter.encrypt(testString);
        final decrypted = decrypter.decrypt(simpleTestText);
        expect(decrypted, simpleTestText);
      },
    );
    test(
      'No Encryption Test Stream (Encrypt only) ',
      () async {
        final simpleTestText = Uint8List.fromList('Sample text to test encryption basics'.codeUnits);
        final slicedData = simpleTestText.sliceToPiecesOfSize(5);
        final encrypter = NoEncryptionByteDataEncrypter();
        final encrypted = encrypter.alterEncryptStream(
          Stream.fromIterable(slicedData.map((e) => Uint8List.fromList(e.toList()))),
          streamMeta: streamMeta,
        );
        final testResultBuffer = <int>[];
        for (final i in slicedData) {
          testResultBuffer
            ..addAll(i)
            ..addAll(slicedData.last != i ? streamMeta.separator.codeUnits : streamMeta.ending.codeUnits);
        }
        final buffer = <int>[];
        await for (final part in encrypted) {
          buffer.addAll(part);
        }
        expect(buffer, testResultBuffer);
      },
    );
    test(
      'No Encryption Test Stream (Decrypt only) ',
      () async {
        final encryptedMessage = [
          83,
          97,
          109,
          112,
          108,
          35,
          83,
          69,
          80,
          65,
          82,
          65,
          84,
          79,
          82,
          35,
          101,
          32,
          116,
          101,
          120,
          35,
          83,
          69,
          80,
          65,
          82,
          65,
          84,
          79,
          82,
          35,
          116,
          32,
          116,
          111,
          32,
          35,
          83,
          69,
          80,
          65,
          82,
          65,
          84,
          79,
          82,
          35,
          116,
          101,
          115,
          116,
          32,
          35,
          83,
          69,
          80,
          65,
          82,
          65,
          84,
          79,
          82,
          35,
          101,
          110,
          99,
          114,
          121,
          35,
          83,
          69,
          80,
          65,
          82,
          65,
          84,
          79,
          82,
          35,
          112,
          116,
          105,
          111,
          110,
          35,
          83,
          69,
          80,
          65,
          82,
          65,
          84,
          79,
          82,
          35,
          32,
          98,
          97,
          115,
          105,
          35,
          83,
          69,
          80,
          65,
          82,
          65,
          84,
          79,
          82,
          35,
          99,
          115,
          35,
          69,
          78,
          68,
          73,
          78,
          71,
          35
        ];
        final simpleTestText = Uint8List.fromList('Sample text to test encryption basics'.codeUnits);
        final decrypter = NoEncryptionByteDataDecrypter();
        final encrypted = decrypter.alterDecryptStream(
          Stream.fromIterable(encryptedMessage.sliceToPiecesOfSize(15).map((e) => Uint8List.fromList(e.toList()))),
          streamMeta: streamMeta,
        );

        final buffer = <int>[];
        await for (final part in encrypted) {
          buffer.addAll(part);
        }
        expect(buffer, simpleTestText);
      },
    );
    test(
      'No Stream Alter Encryption Test',
      () async {
        final encrypter = NoEncryptionByteDataEncrypter();
        final decrypter = NoEncryptionByteDataDecrypter();
        final buffer = <int>[];
        await for (final part in decrypter.alterDecryptStream(
          encrypter.alterEncryptStream(
            Stream.fromIterable(
              testString.sliceToPiecesOfSize(1024).map((e) => Uint8List.fromList(e.toList())),
            ),
            streamMeta: streamMeta,
          ),
          streamMeta: streamMeta,
        )) {
          buffer.addAll(part);
        }
        expect(buffer, testString);
      },
    );
    test(
      'AES Encryption Test Single-Shot ',
      () {
        final encrypter = AESByteDataEncrypter.randomSecureKey();
        final decrypter = AESByteDataDecrypter(
          key: encrypter.key,
          iv: encrypter.iv,
        );
        final encrypted = encrypter.encrypt(testString);
        final decrypted = decrypter.decrypt(encrypted);
        expect(decrypted, testString);
      },
    );
    test(
      'AES Stream Alter Encryption Test',
      () async {
        final encrypter = AESByteDataEncrypter.randomSecureKey();
        final decrypter = AESByteDataDecrypter(
          key: encrypter.key,
          iv: encrypter.iv,
        );
        final buffer = <int>[];
        await for (final part in decrypter.alterDecryptStream(
          encrypter.alterEncryptStream(
            Stream.fromIterable(
              testString.sliceToPiecesOfSize(1024).map((e) => Uint8List.fromList(e.toList())),
            ),
            streamMeta: streamMeta,
          ),
          streamMeta: streamMeta,
        )) {
          buffer.addAll(part);
        }
        expect(buffer, testString);
      },
    );

    test(
      'RSA Encryption Test Single-Shot',
      () {
        final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicKey);
        final decrypter = RSAByteDataDecrypter.fromString(kRSAPrivateKey);
        final buffer = <int>[];
        for (final i in testString.sliceToPiecesOfSize(50)) {
          final encrypted = encrypter.encrypt(Uint8List.fromList(i.toList()));
          final decrypted = decrypter.decrypt(encrypted);
          buffer.addAll(decrypted);
        }
        expect(buffer, testString);
      },
    );
    test(
      'RSA Stream Alter Encryption Test',
      () async {
        final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicKey);
        final decrypter = RSAByteDataDecrypter.fromString(kRSAPrivateKey);
        final buffer = <int>[];
        await for (final part in decrypter.alterDecryptStream(
          encrypter.alterEncryptStream(
            Stream.fromIterable(
              testString.sliceToPiecesOfSize(50).map((e) => Uint8List.fromList(e.toList())),
            ),
            streamMeta: streamMeta,
          ),
          streamMeta: streamMeta,
        )) {
          buffer.addAll(part);
        }
        expect(buffer, testString);
      },
    );
  });
}
