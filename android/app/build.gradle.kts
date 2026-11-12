import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 正式签名配置：android/key.properties（不提交，模板见 key.properties.example）
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.flutter_framework"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 新项目请修改为自己的包名（同步修改 namespace 与 MainActivity 所在包）
        applicationId = "com.example.flutter_framework"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 未配置 key.properties 时回退 debug 签名，保证 `flutter run --release` 可用
            signingConfig =
                if (hasReleaseKeystore) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
            ndk {
                // 上架包仅 ARM（Play 16KB 页对齐要求）
                abiFilters += listOf("arm64-v8a", "armeabi-v7a")
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
        debug {
            // 测试包与正式包可同时安装
            applicationIdSuffix = ".test"
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

// 仅改 App 的 profile variant 包名，避免污染 Flutter 插件 Library 的 buildTypes
// （不可在 buildTypes.profile 写 applicationIdSuffix，否则插件 Library 会报错）
androidComponents {
    onVariants(selector().withBuildType("profile")) { variant ->
        variant.applicationId.set("com.example.flutter_framework.test")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AndroidX Core：Edge-to-Edge（Android 15 兼容）
    implementation("androidx.core:core-ktx:1.15.0")
}
