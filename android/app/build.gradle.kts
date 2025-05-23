plugins {
    // Android Application Plugin
    id("com.android.application")
    // Kotlin Android Plugin für Kotlin-Support
    id("org.jetbrains.kotlin.android")
    // Flutter Gradle Plugin zum Bauen der Flutter-App
    id("dev.flutter.flutter-gradle-plugin")
    // Google-Services Plugin für Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.tapem"
    compileSdk = flutter.compileSdkVersion

    // NDK-Version für native Bibliotheken (z.B. Firebase)
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.tapem"
        minSdk = 26          // ← hier hochsetzen!
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
