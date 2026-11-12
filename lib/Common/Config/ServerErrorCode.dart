/// 服务端业务错误码，按模块分组追加
class ServerErrorCode {
  /// 通用业务成功码。
  static const int bizSuccess = 200;

  /// 登录失效 / token 过期（触发 NetWorkManagerUtil.reLogin）。
  static const int tokenExpired = 401;
}
