# Change Log

## 1.1.4

- added new `IByteEn/Decrypter` called `MultiLayer` that will receive a list of `IByteEn/Decrypter`s and will use them in a chain.

- removed `Encrypt` package [https://pub.dev/packages/encrypt] from dependencies.

## 1.1.3

- added extensions for `RSAPublicKey` and `RSAPrivateKey` to export them to `PEM` format

- added `RSAKeyTools` abstract class to provide common methods to load `RSAPublicKey` and `RSAPrivateKey` from `PEM` format

## 1.1.2

- added `FileMode` to `SecureFile` writer to support appending to files

## 1.1.1

- removed `NoEncryption` abstract class

- now using `encryptMethod` getter in `IByteDataEncrypter` and `IByteDataDecrypter` to find its method

- added an assertion to `SecureFile` constructor to check `encryptMethod` of `encrypter` and `decrypter` to check they are from same type

## 1.1.0

- Removed BlowFish encryption system due to a bug causes some data padded with 0x00 at end.
- Added a method to `IByteDataEncrypter` to alternate the headers with encrypt method.
>
>- currently none of the encryption systems in this source use it.
> you need to extend or create an encryption method to use it.
>

- Updated `lint rules`

- added more documenting

- moved encrypt/decrypt stream methods outside of the `IByteDataEncrypter/Decrypter` interfaces. they shouldn't be overridable.

- added a `SecureFile` class that write/read to/from encrypted files.

## 1.0.0

- Initial version.
