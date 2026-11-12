import 'dart:io';

import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:path_provider/path_provider.dart';

class DocumentFileManager {
  // TODO: Implement DocumentFileManager
  // 单例实例
  static final DocumentFileManager instance = DocumentFileManager._internal();
  // 私有构造函数
  DocumentFileManager._internal();

  // 工厂构造函数，返回单例实例
  factory DocumentFileManager() {
    return instance;
  }

  Future<String> get _localRootPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<bool> fileExists(String fileName) async {
    final file = await localFilePath(fileName);
    return file.exists();
  }

  Future<Future<FileSystemEntity>> deleteFile(String fileName) async {
    final file = await localFilePath(fileName);
    return file.delete();
  }

  Future<File> localFilePath(String fileName) async {
    final path = await _localRootPath;
    return File('$path/$fileName');
  }

  Future<File?> writeFile(String fileName, String data) async {
    try {
      final file = await localFilePath(fileName);
      await file.writeAsString(data);
      return file;
    } catch (e) {
      logE("DocumentFileManager: writeFile error: $e");
      return null;
    }
  }

  Future<String> readFile(String fileName) async {
    try {
      final file = await localFilePath(fileName);

      // Read the file
      final contents = await file.readAsString();

      return contents;
    } catch (e) {
      // If encountering an error, return 0
      return "";
    }
  }
}
