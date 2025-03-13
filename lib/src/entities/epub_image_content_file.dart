import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_content_file.dart';

class EpubImageContentFile extends EpubContentFile {
  String? imagePath;

  @override
  int get hashCode {
    var objects = [
      ContentMimeType.hashCode,
      ContentType.hashCode,
      FileName.hashCode,
      imagePath.hashCode
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (!(other is EpubImageContentFile)) {
      return false;
    }
    return
        ContentMimeType == other.ContentMimeType &&
        ContentType == other.ContentType &&
        FileName == other.FileName &&
        imagePath == other.imagePath;
  }
}
