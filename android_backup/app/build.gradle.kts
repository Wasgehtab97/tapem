import org.gradle.api.tasks.Copy
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.tapem"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.tapem"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs += listOf("-Xjvm-default=compatibility")
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Copy-Task: Spiegel das fertige APK zurück in Flutter-Standard-Output
tasks.register<Copy>("copyDebugFlutterApkToFlutterOutput") {
    dependsOn("assembleDebug")
    from("$buildDir/outputs/flutter-apk/app-debug.apk")
    into("$rootProject.buildDir/app/outputs/flutter-apk")
    rename { "app-debug.apk" }
}
// Sorge dafür, dass der Copy-Task nach assembleDebug läuft
tasks.named("assembleDebug") {
    finalizedBy("copyDebugFlutterApkToFlutterOutput")
}
