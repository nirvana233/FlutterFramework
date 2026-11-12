/// 客户端自定义错误码（与服务端错误码区分，统一使用 1000000 起的号段）
class ClientErrorCode {
  /// 网络请求失败（超时、断网、DNS 等，未拿到服务端响应）
  static const int networkRequestFailed = 1000000;
}
