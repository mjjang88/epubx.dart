import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:quiver/core.dart';

import '../entities/epub_content_type.dart';
import '../utils/zip_path_utils.dart';
import 'epub_book_ref.dart';

abstract class EpubContentFileRef {
  late EpubBookRef epubBookRef;

  String? FileName;

  EpubContentType? ContentType;
  String? ContentMimeType;
  EpubContentFileRef(EpubBookRef epubBookRef) {
    this.epubBookRef = epubBookRef;
  }

  @override
  int get hashCode =>
      hash3(FileName.hashCode, ContentMimeType.hashCode, ContentType.hashCode);

  @override
  bool operator ==(other) {
    if (!(other is EpubContentFileRef)) {
      return false;
    }

    return (other.FileName == FileName &&
        other.ContentMimeType == ContentMimeType &&
        other.ContentType == ContentType);
  }

  ArchiveFile getContentFileEntry() {
    var contentFilePath = ZipPathUtils.combine(
        epubBookRef.Schema!.ContentDirectoryPath, FileName);
    var contentFileEntry = epubBookRef.EpubArchive()!
        .files
        .firstWhereOrNull((ArchiveFile x) => x.name == contentFilePath);
    if (contentFileEntry == null) {
      throw Exception(
          'EPUB parsing error: file $contentFilePath not found in archive.');
    }
    return contentFileEntry;
  }

  List<int> getContentStream() {
    return openContentStream(getContentFileEntry());
  }

  List<int> openContentStream(ArchiveFile contentFileEntry) {
    var contentStream = <int>[];
    if (contentFileEntry.content == null) {
      throw Exception(
          'Incorrect EPUB file: content file \"$FileName\" specified in manifest is not found.');
    }
    contentStream.addAll(contentFileEntry.content);
    return contentStream;
  }

  Future<Uint8List> readContentAsBytes() async {
    var contentFileEntry = getContentFileEntry();
    var content = openContentStream(contentFileEntry);
    return Uint8List.fromList(content);
  }

  Future<String> readContentAsText() async {
    var contentStream = getContentStream();
    var result = convert.utf8.decode(contentStream);
    return result;
  }

  Future<String> readAndSaveContent(String fileName) async {
    // EPUB 데이터를 Uint8List로 가져오기
    var contentFileEntry = getContentFileEntry();
    Uint8List contentBytes = Uint8List.fromList(openContentStream(contentFileEntry));

    // 로컬 저장소에 저장 후 경로 반환
    return await saveContentToFile(contentBytes, fileName);
  }

  Future<String> saveContentToFile(Uint8List content, String fileName) async {
    try {
      // 파일명에서 경로 제거 (파일명만 추출)
      final pureFileName = path.basename(fileName);

      // 앱 내 로컬 저장소 경로 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = '${directory.path}/images'; // 'images' 폴더 내 저장

      // 디렉토리 생성 (존재하지 않을 경우)
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final filePath = '$folderPath/$pureFileName';

      // 파일 저장
      final file = File(filePath);
      await file.writeAsBytes(content, flush: true);

      return filePath; // 저장된 파일의 경로 반환
    } catch (e) {
      print("Error saving file: $e");
      return ''; // 오류 발생 시 빈 문자열 반환
    }
  }
}
