import org.gradle.api.tasks.Copy
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// 1) Das klassische buildscript-Block für das Google-Services-Plugin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// 2) Plugins-Block – hier nur die Plugins mit Version im settings.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 3) Am Ende anwenden des Google-Services-Plugins
apply(plugin = "com.google.gms.google-services")

android {
    namespace = "com.example.tapem"
    compileSdk = flutter.compileSdkVersion

    // NDK-Version für Firebase & Co.
    ndkVersion = "27.0.12077973"

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

// (Optional) Wenn du weiterhin ein manuelles Kopieren brauchst, steht hier dein Copy-Task
// tasks.register<Copy>("copyDebugFlutterApkToFlutterOutput") { … }
