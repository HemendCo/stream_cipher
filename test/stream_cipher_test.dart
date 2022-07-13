// ignore_for_file: lines_longer_than_80_chars, prefer_foreach

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stream_cipher/stream_cipher.dart';
import 'package:test/test.dart';
part 'no_encryption_mock.dart';

void main() {
  group('Encryption Tests', () {
    const kRSAPublicKey = '''-----BEGIN PUBLIC KEY-----
MDwwDQYJKoZIhvcNAQEBBQADKwAwKAIhAMIjTtt6GCD7zFD5wWpjbOpfbYg63mdg
Vmg0Q34LeT/FAgMBAAE=
-----END PUBLIC KEY-----''';
    const kRSAPrivateKey = '''-----BEGIN PRIVATE KEY-----
MIHCAgEAMA0GCSqGSIb3DQEBAQUABIGtMIGqAgEAAiEAwiNO23oYIPvMUPnBamNs
6l9tiDreZ2BWaDRDfgt5P8UCAwEAAQIgUv5nKtqyT/91JDTxY7rnhzcbFopJTB6y
Ec2CTNUN+U0CEQD03/V921/wANHTb7fG1dMfAhEAyvU/k4VSyP3tvBlQv/wUmwIQ
D1SiIvIEDJuQh2M8Jzel0wIQdyRRFgCGAIdQL8OMq6cHUQIRAJDViA2ucV7u0wBT
Nf2I+3s=
-----END PRIVATE KEY-----''';

    const kRSAPublicPkcs1Key = '''-----BEGIN RSA PUBLIC KEY-----
MCgCIQCaBSJ+BdvQiyHIP6xphzXr7PAAcaDgcfQ7HiE46kd6kwIDAQAB
-----END RSA PUBLIC KEY-----''';
    const kRSAPrivatePkcs1Key = '''-----BEGIN RSA PRIVATE KEY-----
MIGpAgEAAiEAmgUifgXb0IshyD+saYc16+zwAHGg4HH0Ox4hOOpHepMCAwEAAQIg
OU9j0ETZ0DWVMnAO9Y1sUHOTd/szRNdAPT7h8jCAKSECEQDNc9okvvM34O+X5Jgz
csWbAhEAv+ngppV1xvHivojfbGsqaQIQUohirnZC0ES9GwCKn8hQVwIQF6buXfl7
m3pCNLNPvd/zSQIQHb9zWGpmoCAtqvof8vputQ==
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
    group('No Encryption', () {
      test(
        'Single-Shot',
        () {
          final encrypter = _NoEncryptionByteDataEncrypter();
          final decrypter = _NoEncryptionByteDataDecrypter();
          final encrypted = encrypter.encrypt(testString);
          final decrypted = decrypter.decrypt(encrypted);
          expect(decrypted, testString);
        },
      );
      test(
        'Stream Alter Encryption Test',
        () async {
          final encrypter = _NoEncryptionByteDataEncrypter();
          final decrypter = _NoEncryptionByteDataDecrypter();
          final buffer = <int>[];
          await for (final part in decrypter.alterDecryptStream(
            encrypter.alterEncryptStream(
              Stream.fromIterable(
                testString.sliceToPiecesOfSize(1024).map(
                      (e) => Uint8List.fromList(
                        e.toList(),
                      ),
                    ),
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
        'Single-Shot(Encrypt only) ',
        () {
          final simpleTestText = Uint8List.fromList(
            'Sample text to test encryption basics'.codeUnits,
          );
          final encrypter = _NoEncryptionByteDataEncrypter();
          final encrypted = encrypter.encrypt(simpleTestText);
          expect(encrypted, simpleTestText);
        },
      );
      test(
        'Single-Shot(Decrypt only)',
        () {
          final simpleTestText = Uint8List.fromList(
            'Sample text to test encryption basics'.codeUnits,
          );
          // final encrypter = _NoEncryptionByteDataEncrypter();
          final decrypter = _NoEncryptionByteDataDecrypter();
          // final encrypted = encrypter.encrypt(testString);
          final decrypted = decrypter.decrypt(simpleTestText);
          expect(decrypted, simpleTestText);
        },
      );
      test(
        'Stream (Encrypt only) ',
        () async {
          final simpleTestText = Uint8List.fromList(
            'Sample text to test encryption basics'.codeUnits,
          );
          final slicedData = simpleTestText.sliceToPiecesOfSize(5);
          final encrypter = _NoEncryptionByteDataEncrypter();
          final encrypted = encrypter.alterEncryptStream(
            Stream.fromIterable(
              slicedData.map((e) => Uint8List.fromList(e.toList())),
            ),
            streamMeta: streamMeta,
          );
          final testResultBuffer = <int>[];
          for (final i in slicedData) {
            testResultBuffer
              ..addAll(i)
              ..addAll(
                slicedData.last != i ? streamMeta.separator.codeUnits : streamMeta.ending.codeUnits,
              );
          }
          final buffer = <int>[];
          await for (final part in encrypted) {
            buffer.addAll(part);
          }
          expect(buffer, testResultBuffer);
        },
      );
      test(
        'Stream (Decrypt only) ',
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
          final simpleTestText = Uint8List.fromList(
            'Sample text to test encryption basics'.codeUnits,
          );
          final decrypter = _NoEncryptionByteDataDecrypter();
          final encrypted = decrypter.alterDecryptStream(
            Stream.fromIterable(
              encryptedMessage.sliceToPiecesOfSize(15).map((e) => Uint8List.fromList(e.toList())),
            ),
            streamMeta: streamMeta,
          );

          final buffer = <int>[];
          await for (final part in encrypted) {
            buffer.addAll(part);
          }
          expect(buffer, simpleTestText);
        },
      );
    });
    group('AES', () {
      test(
        'Single-Shot',
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
        'Stream Alter',
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
                testString.sliceToPiecesOfSize(16).map((e) => Uint8List.fromList(e.toList())),
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
    group('AES With base64 ', () {
      test(
        'Stream Alter',
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
              useBase64: true,
            ),
            streamMeta: streamMeta,
            useBase64: true,
          )) {
            buffer.addAll(part);
          }
          expect(buffer, testString);
        },
      );
    });

    group('RSA', () {
      test(
        'Single-Shot',
        () {
          final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicKey);
          final decrypter = RSAByteDataDecrypter.fromString(kRSAPrivateKey);

          final buffer = <int>[];
          for (final i in testString.sliceToPiecesOfSize(encrypter.inputBlocSize)) {
            final encrypted = encrypter.encrypt(Uint8List.fromList(i.toList()));
            final decrypted = decrypter.decrypt(encrypted);
            buffer.addAll(decrypted);
          }
          expect(buffer, testString);
        },
      );
      test('Encrypt only', () {
        final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicKey);
        final buffer = <int>[];
        for (final i in testString.sliceToPiecesOfSize(encrypter.inputBlocSize)) {
          final encrypted = encrypter.encrypt(Uint8List.fromList(i.toList()));
          buffer.addAll(encrypted);
        }
        expect(buffer, isNot(testString));
      });

      test(
        'Stream Alter',
        () async {
          final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicKey);
          final decrypter = RSAByteDataDecrypter.fromString(kRSAPrivateKey);
          final buffer = <int>[];
          await for (final part in decrypter.alterDecryptStream(
            encrypter.alterEncryptStream(
              Stream.fromIterable(
                testString.sliceToPiecesOfSize(encrypter.inputBlocSize).map((e) => Uint8List.fromList(e.toList())),
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
    group('RSA with pkcs1 key', () {
      test(
        'Single-Shot',
        () {
          final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicPkcs1Key);
          final decrypter = RSAByteDataDecrypter.fromString(kRSAPrivatePkcs1Key);

          final buffer = <int>[];
          for (final i in testString.sliceToPiecesOfSize(encrypter.inputBlocSize)) {
            final encrypted = encrypter.encrypt(Uint8List.fromList(i.toList()));
            final decrypted = decrypter.decrypt(encrypted);
            buffer.addAll(decrypted);
          }
          expect(buffer, testString);
        },
      );
      test('Encrypt only', () {
        final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicPkcs1Key);
        final buffer = <int>[];
        for (final i in testString.sliceToPiecesOfSize(encrypter.inputBlocSize)) {
          final encrypted = encrypter.encrypt(Uint8List.fromList(i.toList()));
          buffer.addAll(encrypted);
        }
        expect(buffer, isNot(testString));
      });

      test(
        'Stream Alter',
        () async {
          final encrypter = RSAByteDataEncrypter.fromString(kRSAPublicPkcs1Key);
          final decrypter = RSAByteDataDecrypter.fromString(kRSAPrivatePkcs1Key);
          final buffer = <int>[];
          await for (final part in decrypter.alterDecryptStream(
            encrypter.alterEncryptStream(
              Stream.fromIterable(
                testString.sliceToPiecesOfSize(encrypter.inputBlocSize).map((e) => Uint8List.fromList(e.toList())),
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
    group('GZip', () {
      test(
        'Single-Shot',
        () {
          final encrypter = Base64ByteDataEncoder();
          final decrypter = Base64ByteDataDecoder();
          final encrypted = encrypter.encrypt(testString);
          final decrypted = decrypter.decrypt(encrypted);
          expect(decrypted, testString);
        },
      );
      test(
        'Stream Alter',
        () async {
          final encrypter = Base64ByteDataEncoder();
          final decrypter = Base64ByteDataDecoder();
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
    });
    group('No encryption total', () {
      test(
        'Single-Shot',
        () {
          final encrypter = NoEncryptionByteDataEncrypter();
          final decrypter = NoEncryptionByteDataDecrypter();
          final encrypted = encrypter.encrypt(testString);
          final decrypted = decrypter.decrypt(encrypted);
          expect(decrypted, testString);
        },
      );
      test(
        'Stream Alter',
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
    });
    group('MultiLayer', () {
      test(
        'Single-Shot',
        () {
          final _aesEncrypter = AESByteDataEncrypter.randomSecureKey();
          final _aesDecrypter = AESByteDataDecrypter(
            key: _aesEncrypter.key,
            iv: _aesEncrypter.iv,
          );

          final encrypter = MultiLayerEncrypter([
            Base64ByteDataEncoder(),
            _aesEncrypter,
          ]);
          final decrypter = MultiLayerDecrypter([
            Base64ByteDataDecoder(),
            _aesDecrypter,
          ]);
          final encrypted = encrypter.encrypt(testString);
          final decrypted = decrypter.decrypt(encrypted);

          expect(decrypted, testString);
        },
      );
      test(
        'Stream Alter',
        () async {
          final _aesEncrypter = AESByteDataEncrypter.randomSecureKey();
          final _aesDecrypter = AESByteDataDecrypter(
            key: _aesEncrypter.key,
            iv: _aesEncrypter.iv,
          );
          final _rsaEncrypter = RSAByteDataEncrypter.fromString(kRSAPublicPkcs1Key);
          final _rsaDecrypter = RSAByteDataDecrypter.fromString(kRSAPrivatePkcs1Key);

          final encrypter = MultiLayerEncrypter([
            // GZipByteDataEncoder(),
            _rsaEncrypter,
            Base64ByteDataEncoder(),
          ]);
          final decrypter = MultiLayerDecrypter([
            // GZipByteDataDecoder(),
            _rsaDecrypter,
            Base64ByteDataDecoder(),
          ]);
          final buffer = <int>[];
          await for (final part in decrypter.alterDecryptStream(
            encrypter.alterEncryptStream(
              Stream.fromIterable(
                testString.sliceToPiecesOfSize(16).map((e) => Uint8List.fromList(e.toList())),
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
  });
}
