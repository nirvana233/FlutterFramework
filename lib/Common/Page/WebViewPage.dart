// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_framework/Base/BaseFulWidget.dart';
import 'package:flutter_framework/Common/Widget/Animation/LottieAnimationView.dart';
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
// #docregion platform_imports
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS/macOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// #enddocregion platform_imports

class WebViewPage extends BaseFulWidget {
  WebViewPage({super.key, required super.arguments});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  WebResourceError? _webResourceError;

  String? _url;
  String? _title;

  @override
  void initState() {
    super.initState();

    var arguments = widget.arguments;
    _url = arguments['url'];
    _title = arguments['title'];

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // logD('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _webResourceError = null;
              });
            }
            // logD('Page started loading: $url');
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // logD('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _webResourceError = error;
              });
            }
            logW('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_url ?? ''));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppbar(
        title: _title ?? '',
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
          ),
          WebViewWidget(controller: _controller),
          if (_isLoading) const LottieAnimationView(),
          if (_webResourceError != null)
            Center(
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //_webResourceError?.description ??
                    Text('error_message_9'.tr, style: const TextStyle(color: Colors.black54)),
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _isLoading = true;
                              });
                            }
                            _controller.reload();
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color.fromARGB(255, 204, 204, 204),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
