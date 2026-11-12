import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';
import 'HttpClientPool.dart';

/// 提供复用 HttpClient 的图片缓存管理器，降低重复建连的成本
class ImageCacheManagers {
  ImageCacheManagers._();

  static final Map<int, CacheManager> _managersByStaleSeconds = {};

  /// 根据失效时间获取（或创建）对应的 CacheManager 实例
  /// 通过共享的 HttpClient 实现连接复用
  static CacheManager get({Duration? stalePeriod}) {
    final int seconds = (stalePeriod ?? const Duration(days: 7)).inSeconds;
    final existing = _managersByStaleSeconds[seconds];
    if (existing != null) return existing;

    final ioClient = IOClient(HttpClientPool.shared);

    final config = Config(
      'imageCache_${seconds}s',
      stalePeriod: Duration(seconds: seconds),
      maxNrOfCacheObjects: 300,
      fileService: HttpFileService(httpClient: ioClient),
    );

    final manager = CacheManager(config);
    _managersByStaleSeconds[seconds] = manager;
    return manager;
  }
}
