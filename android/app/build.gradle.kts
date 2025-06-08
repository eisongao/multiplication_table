plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.multiplication_table"
    compileSdk = flutter.compileSdkVersion

    // 指定 NDK 版本，确保所有插件兼容
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.multiplication_table"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        /**
         * 指定一个名为 release 的签名配置
         * key.jks 请放在 android/app/key/multiplication.jks
         */
        create("release") {
            keyAlias      = "multiplication"
            keyPassword   = "123456a"
            storeFile     = file("key/multiplication.jks")
            storePassword = "123456a"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
