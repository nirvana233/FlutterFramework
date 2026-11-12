import 'dart:io';

import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:path_provider/path_provider.dart';

class MemoryCacheManager {
  static Future<double> getCacheSize() async {
    try {
      // Directory docDirectory = await getApplicationDocumentsDirectory();
      Directory tempDirectory = await getTemporaryDirectory();
      double size = 0;
      // if (docDirectory.existsSync()) {
      //   size += calculateDirectorySize(docDirectory);
      // }
      if (tempDirectory.existsSync()) {
        size += calculateDirectorySize(tempDirectory);
      }
      return size;
    } catch (e) {
      logW("MemoryCacheManager: getCacheSize error: $e");
      return 0;
    }
  }

  static double calculateDirectorySize(Directory dir) {
    double size = 0;
    final List<FileSystemEntity> entities = dir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File) {
        size += entity.lengthSync();
      }
    }
    return size;
  }

  /// 删除缓存
  static Future<void> clearCache() async {
    // Directory docDirectory = await getApplicationDocumentsDirectory();
    Directory tempDirectory = await getTemporaryDirectory();

    // if (docDirectory.existsSync()) {
    //   await deleteDirectory(docDirectory);
    // }

    if (tempDirectory.existsSync()) {
      await deleteDirectory(tempDirectory);
    }
  }

  static Future<Null> deleteDirectory(FileSystemEntity file) async {
    if (file is Directory) {
      final List<FileSystemEntity> children = file.listSync();
      for (final FileSystemEntity child in children) {
        await deleteDirectory(child);
        await child.delete();
      }
    }
  }
}
