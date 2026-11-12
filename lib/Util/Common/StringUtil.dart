//todo:appstore url（新项目上架后替换为真实 ID）
import 'package:get/get.dart';

const String appStoreId = "0000000000";
const String appStoreRatingUrl = 'https://itunes.apple.com/app/id$appStoreId?action=write-review';
const String appStoreAppUrl = "https://apps.apple.com/app/id$appStoreId";

const String googlePlayStoreId = "com.example.flutter_framework";
String get googlePlayStoreUrl => "https://play.google.com/store/apps/details?id=$googlePlayStoreId";

String get storeUrl => GetPlatform.isIOS ? appStoreAppUrl : googlePlayStoreUrl;

//todo:链接
//官网
const String officialUrl = "https://www.example.com/";
//隐私协议
const String privacyPolicyUrl = "https://www.example.com/privacy-policy.html";
//服务条款
const String termsOfServiceUrl = "https://www.example.com/terms-of-service.html";
//Apple用户协议
const String appleServicePolicyUrl =
    "https://www.apple.com/legal/internet-services/itunes/dev/stdeula";

//todo:底部间距
const double bottomSpacingWithoutSafeArea = 15.0;
