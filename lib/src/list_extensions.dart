library http_request_cipher.extensions;

extension ListBreaker<T> on List<T> {
  /// split the list by given sublist
  Iterable<Iterable<T>> splitByPart(List<T> splitter) {
    final parts = <Iterable<T>>[];
    int start = 0;
    for (int i = 0; i < length; i++) {
      if (this[i] == splitter[0]) {
        if (splitter.length == 1) {
          parts.add(sublist(start, i));
          start = i + 1;
        } else {
          if (i + splitter.length <= length && sublist(i, i + splitter.length).join('') == splitter.join('')) {
            parts.add(sublist(start, i));
            start = i + splitter.length;
            i += splitter.length - 1;
          }
        }
      }
    }
    parts.add(sublist(start, length));
    return parts;
  }

  Iterable<Iterable<T>> breakToPieceOfSize(int pieceSize) {
    final result = <Iterable<T>>[];
    var current = <T>[];
    for (var item in this) {
      current.add(item);
      if (current.length == pieceSize) {
        result.add(current);
        current = <T>[];
      }
    }
    if (current.isNotEmpty) {
      result.add(current);
    }
    return result;
  }

  Iterable<Iterable<T>> breakToPiecesOfSizes(List<int> pieceSizes) {
    final result = <Iterable<T>>[];
    int pieceIndex = 0;
    var current = <T>[];
    for (var item in this) {
      current.add(item);
      if (current.length == pieceSizes[pieceIndex]) {
        pieceIndex++;
        result.add(current);
        current = <T>[];
      }
    }
    if (current.isNotEmpty) {
      result.add(current);
    }
    return result;
  }
}
