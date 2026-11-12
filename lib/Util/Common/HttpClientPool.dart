import 'dart:io';

/// 提供全局复用的 HttpClient，开启持久连接与连接池，减少握手耗时
class HttpClientPool {
  HttpClientPool._();

  static final HttpClient _sharedHttpClient = _createSharedHttpClient();

  static HttpClient get shared => _sharedHttpClient;

  static HttpClient _createSharedHttpClient() {
    final client = HttpClient();
    // 尽量复用连接，避免频繁 TCP/TLS 握手
    client.idleTimeout = const Duration(seconds: 30);
    client.connectionTimeout = const Duration(seconds: 15);
    client.maxConnectionsPerHost = 20;
    client.userAgent = 'NovelTime/1.0';
    client.autoUncompress = true; // 支持 gzip/br 自动解压
    return client;
  }
}
