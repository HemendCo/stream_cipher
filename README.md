this package can be used to encrypt/decrypt data in stream form (e.g. HTTP, IO,etc)

this package initially comes with a http client adapter for `Dio` library.

### Secure File

> example:
>
> ```Dart
> final secureFile = SecureFile(
>    File('example'),
>    encrypter: encrypter,
>    decrypter: decrypter,
>    useBase64: true,
>    maxBlockSize: 4096,
>  );
> ```
>
> **supports**:
>
>- `Stream<Uint8List>` read/write
>- `Uint8List` read/write
>- `String` read/write
>
> **Notes**:
>
>>- de/encryption is done while read/writing meaning data will not be de/encrypted until that part of data is read/written.
>>- both of de/encrypter use same method. **Note**: for internal encrypters like `AES,RSA,Gzip,NoEncryption` it has an assertion but if you extend De/Encrypter you need to test it inside your app. in some cases this may seems ok but in action during reading the file content may cause an error or even **data corruption**.
>>
>>- this does not extend `File` class.
>>
>>- `write` methods support appending to file. but in this case you need to pass a `EncryptStreamMeta` to constructor with `Separator` and `Ending` with same value using `EncryptStreamMeta.sameSeparatorAsEnding('....... separator .......')`.
>>
>>- due to high load of some algorithms during de/encryption this class does not support synchronous read/write.
>>
>>- methods in this class are not running inside an isolate and therefore may cause performance issues.

## DioHttpAdapter
>
>```Dart
>/// create instance of `CipherDioHttpAdapter`
>final dioClient = CipherDioHttpAdapter(
>      decrypter: decrypter,
>      encrypter: encrypter,
>    );
>/// creating an instance of `Dio` with `CipherDioHttpAdapter`
>final dio = Dio()..httpClientAdapter = dioClient;
>```
>
>>- in this method only the body of the request is encrypted.
>>
>>- in this method only the body of the response is decrypted.
>>
>>- the header of request is not encrypted. to deform the header of request, you can extend one of `IByteDataEncrypter`s and override the `alterHeader` method to do so.

for backend side you can check example of this project

## Example of De/Encrypter

> to create instance of de/encrypter
>
>```Dart
>final encrypter = AESByteDataEncrypter.randomSecureKey();
>final decrypter = AESByteDataDecrypter(
>   key: encrypter.key,
>   iv: encrypter.iv,
> );
>```
