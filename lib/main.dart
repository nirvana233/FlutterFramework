import 'package:bot_toast/bot_toast.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_framework/Base/BaseFulWidget.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Config/FontConfig.dart';
import 'package:flutter_framework/Common/Manager/AppMgr.dart';
import 'package:flutter_framework/Common/Manager/AppThemeMgr.dart';
import 'package:flutter_framework/Common/Manager/RegisterControllerMgr.dart';
import 'package:flutter_framework/Common/Manager/TimeMgr.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/MainPage/Language/ViewModel/LanguageViewModel.dart';
import 'package:flutter_framework/MainPage/Launch/LaunchPage.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/NetworkImageShimmer.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_framework/Util/DBManager/DBManager.dart';
import 'package:flutter_framework/Util/Router/PageRouteObserver.dart';
import 'package:flutter_framework/Util/Router/Route.dart';
import 'package:flutter_framework/Util/Translations/MyTranslations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

void main() async {
  // 禁用调试标志
  debugPrintRebuildDirtyWidgets = false;
  debugPrintLayouts = false;

  /// 在调用sdk初始化方法之前准备好 Flutter 框架的运行环境。
  WidgetsFlutterBinding.ensureInitialized();

  await init();

  runApp(
    DevicePreview(
      enabled: isShowDevicePreview,
      builder: (context) {
        return MyApp();
      },
    ),
  );
}

/// runApp 前的初始化。顺序约定：日志 → 本地存储 → 语言 → 其余管理器
/// 第三方 SDK（统计、推送、登录等）接入后也在这里初始化。
Future<void> init() async {
  // 强制隐藏状态栏和导航栏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  initTalker();
  await PreferenceUtil.instance.init();
  AppThemeMgr.instance.init();
  TimeMgr.instance.init();
  await LanguageViewModel.instance.init();
  // Dio 初始化在 LaunchPage，在获取 domain 后执行
  RegisterControllerMgr.instance.register();
  AppMgr.instance.init();
  VibrationMgr.instance.init();
  await DBManager.instance.init();
  await DeviceUtil.instance.initialize();
  // 确保应用启动时默认允许截图，防止状态残留
  screenshotOn();
  // 禁止横屏翻转，全局锁定竖屏（runApp 前完成）；iPad 开启多任务时不生效
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

class MyApp extends BaseFulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // 随 State 保留路由栈记录，避免热重载或重建后退栈丢失当前页面。
  final PageRouteObserver<PageRoute> _routeObserver = PageRouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    logP('initState');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除观察者
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    AppMgr.instance.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    AppMgr.instance.appContext = context;
    return _build(context);
  }

  Widget _build(BuildContext context) {
    return ScreenUtilInit(
      designSize: GetPlatform.isIOS ? const Size(375, 812) : const Size(360, 800),
      minTextAdapt: true,
      //分屏模式，折叠屏
      splitScreenMode: true,
      builder: (_, child) {
        return GestureDetector(
          onTap: () {
            // 点击键盘外部区域时关闭键盘
            FocusManager.instance.primaryFocus?.unfocus();
          },
          // 语言 / 主题切换时整体重建
          child: Obx(() {
            Locale locale = LanguageViewModel.instance.appLanguage.value;
            bool isDarkMode = AppThemeMgr.instance.isDarkMode.value;
            return GetMaterialApp(
              useInheritedMediaQuery: true,
              debugShowCheckedModeBanner: false,
              navigatorObservers: [_routeObserver, BotToastNavigatorObserver()],
              routingCallback: null,
              initialRoute: GetPlatform.isAndroid ? null : launchPage,
              home: GetPlatform.isAndroid ? LaunchPage() : null,
              builder: (context, child) {
                // 先让 DevicePreview 注入模拟设备的 MediaQuery/Locale，再叠加项目自定义 builder
                final previewWrappedChild = isShowDevicePreview
                    ? DevicePreview.appBuilder(context, child)
                    : child;
                final toastAndLoadingWrapped = EasyLoading.init(builder: BotToastInit())(
                  context,
                  previewWrappedChild,
                );

                // 禁用系统字体缩放,保持应用字体大小不受系统设置影响(包括Toast等所有组件)
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: NetworkImageShimmerScope(child: toastAndLoadingWrapped),
                );
              },
              // 使用GetX的Translation
              translations: MyTranslations(),
              // 设置当前语言环境
              locale: isShowDevicePreview ? (DevicePreview.locale(context) ?? locale) : locale,
              //默认语言环境
              fallbackLocale: MyTranslations.fallbackLocale(),
              //支持的语言列表，用于App内切换语言
              supportedLocales: MyTranslations.localeSupportList(),
              // 支持的语言环境列表
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              onGenerateRoute: generateRoute,
              theme: _buildTheme(isDarkMode),
            );
          }),
        );
      },
    );
  }

  /// 全局主题：颜色统一取自 FigmaVariables，明暗模式由 AppThemeMgr 控制
  ThemeData _buildTheme(bool isDarkMode) {
    final colors = isDarkMode ? FigmaVariables.dark : FigmaVariables.light;
    return ThemeData(
      useMaterial3: true,
      fontFamily: FontConfig.primaryFontFamily,
      fontFamilyFallback: FontConfig.getFontFamilyFallback(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.colorPrimaryDefault,
        primary: colors.colorPrimaryDefault,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colors.colorPrimaryDefault.withValues(alpha: 0.3),
        selectionHandleColor: colors.colorPrimaryDefault,
        cursorColor: colors.colorPrimaryDefault,
      ),
      appBarTheme: AppBarTheme(backgroundColor: colors.colorBgElementB100),
      // 设置页面背景颜色
      scaffoldBackgroundColor: colors.colorBgElementB96,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
