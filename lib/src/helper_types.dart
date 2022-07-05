library http_request_cipher.helper_types;

class EncryptStreamMeta {
  final String ending;
  final String separator;

  const EncryptStreamMeta({required this.ending, required this.separator}) : assert(ending != separator);
}
