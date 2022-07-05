# Change Log

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

## 1.0.0

- Initial version.
