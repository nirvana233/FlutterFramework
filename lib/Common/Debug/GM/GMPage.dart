import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_framework/Common/Manager/AppThemeMgr.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';
import 'package:flutter_framework/MainPage/Language/ViewModel/LanguageViewModel.dart';
import 'package:flutter_framework/Util/Common/ApiConfig.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/NetworkImageUtil.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:flutter_framework/Util/DBManager/DBManager.dart';
import 'package:flutter_framework/Util/NetWorkManager/NetWorkManagerUtil.dart';
import 'package:flutter_framework/Util/Router/RouteOpenPage.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Toast.dart';
import 'package:get/get.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// GM Tools Page（仅测试包入口：悬浮 GM 按钮 / 我的页 GM）
/// 新增调试项：在 [_gmItems] 追加；业务模块的调试页放到 `Common/Debug/` 下再从这里跳转
class GMPage extends StatefulWidget {
  const GMPage({super.key});

  @override
  State<GMPage> createState() => _GMPageState();
}

class _GMPageState extends State<GMPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CommonAppbar(title: 'GM Tools'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildEnvInfo(),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _gmItems.length,
              itemBuilder: (context, index) {
                final item = _gmItems[index];
                return _GMItemButton(
                  title: item.title,
                  icon: item.icon,
                  onTap: () async {
                    VibrationMgr.instance.selection();
                    await item.onTap(context);
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 当前环境信息
  Widget _buildEnvInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<String>(
        future: DeviceUtil.getVersion(),
        builder: (context, snapshot) {
          final lines = [
            '版本: ${snapshot.data ?? '-'}',
            '服务器: ${isTestServerText()}',
            'baseUrl: ${NetWorkManagerUtil.instance.isInitialized ? NetWorkManagerUtil.instance.baseOptions.baseUrl : baseUrl}',
            'App 语言: ${LanguageViewModel.instance.appLanguage.value.languageCode}',
            '设备ID: ${DeviceUtil.deviceIdentifier}',
          ];
          return GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: lines.join('\n')));
              showToast('已复制环境信息');
            },
            child: Text(
              lines.join('\n'),
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF333333)),
            ),
          );
        },
      ),
    );
  }

  String isTestServerText() {
    if (!isTestServerEnabled) return '正式服';
    return _isUsingInnerTestServer ? '内网测试服' : '仿真测试服';
  }

  bool get isTestServerEnabled => baseUrl == testUrl;

  /// 当前是否指向内网测试服（优先看本地 domain 缓存，其次内存 testUrl）
  bool get _isUsingInnerTestServer {
    final cached = PreferenceUtil.instance.getDomain();
    if (cached != null && cached.isNotEmpty) {
      return cached == innerTestUrl;
    }
    return testUrl == innerTestUrl;
  }

  List<_GMItem> get _gmItems => [
    _GMItem(
      title: '查看日志',
      icon: Icons.article_outlined,
      onTap: (context) async {
        if (talker == null) {
          showToast('日志未开启（Const.isLog）');
          return;
        }
        await Get.to(() => TalkerScreen(talker: talker!, isLogsExpanded: false));
      },
    ),
    // 在内网测试服 / 仿真测试服之间切换；清本地登录态，避免 token 串服
    _GMItem(
      title: _isUsingInnerTestServer ? '切换为仿真测试服' : '切换为内网测试服',
      icon: Icons.lan_outlined,
      onTap: (context) async {
        final targetUrl = _isUsingInnerTestServer ? simTestUrl : innerTestUrl;
        final targetName = _isUsingInnerTestServer ? '仿真测试服' : '内网测试服';
        testUrl = targetUrl;
        await PreferenceUtil.instance.setDomain(targetUrl);
        NetWorkManagerUtil.instance.updateBaseUrl(targetUrl);
        await PreferenceUtil.instance.clearLoginInfo();
        showToast('已切换$targetName: $targetUrl');
      },
    ),
    // 网络响应日志 Format JSON：勾选开启并写入本地，默认关闭
    _GMItem(
      title: NetWorkManagerUtil.instance.isHttpResponseFormatJson ? 'Format JSON ✓' : 'Format JSON',
      icon: Icons.data_object_outlined,
      onTap: (context) async {
        final next = !NetWorkManagerUtil.instance.isHttpResponseFormatJson;
        await NetWorkManagerUtil.instance.setHttpResponseFormatJson(next);
        showToast(next ? '已开启响应 Format JSON' : '已关闭响应 Format JSON');
      },
    ),
    _GMItem(
      title: AppThemeMgr.instance.isDarkMode.value ? '暗色模式 ✓' : '暗色模式',
      icon: Icons.dark_mode_outlined,
      onTap: (context) async {
        AppThemeMgr.instance.toggleTheme();
      },
    ),
    _GMItem(
      title: 'App 语言',
      icon: Icons.translate,
      onTap: (context) async {
        await LanguageViewModel.instance.openAppLanguageSetting();
      },
    ),
    _GMItem(
      title: 'Example 列表',
      icon: Icons.list_alt,
      onTap: (context) async {
        await toExampleListPage();
      },
    ),
    _GMItem(
      title: '清除图片缓存',
      icon: Icons.image_not_supported_outlined,
      onTap: (context) async {
        await NetworkImageUtil.clearCache();
        await NetWorkManagerUtil.instance.clearImageCache();
        showToast('图片缓存已清除');
      },
    ),
    _GMItem(
      title: '删除本地所有Preferences数据',
      icon: Icons.delete_forever,
      onTap: (context) async {
        // 清除所有 SharedPreferences（含登录态、AppMgr 缓存的 domain 等）
        bool result = await PreferenceUtil.instance.clearAll();
        showToast(result ? '本地数据记录已删除，重启 App 生效' : '删除本地数据失败');
      },
    ),
    _GMItem(
      title: '删除本地数据库(Hive)',
      icon: Icons.storage_outlined,
      onTap: (context) async {
        await DBManager.instance.deleteAll();
        showToast('Hive 数据已删除，重启 App 生效');
      },
    ),
  ];
}

class _GMItem {
  final String title;
  final IconData icon;
  final Future<void> Function(BuildContext context) onTap;

  _GMItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _GMItemButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GMItemButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color(0xFFFE4C39),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F1F2F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
