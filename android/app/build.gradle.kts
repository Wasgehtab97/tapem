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
    namespace = "com.example.tapem"                // Muss mit applicationId übereinstimmen
    compileSdk = flutter.compileSdkVersion

    // NDK-Version für native Bibliotheken (z.B. Firebase)
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.tapem"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        // Java 11 Kompatibilität für Kotlin-Code
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs += listOf("-Xjvm-default=compatibility")
    }

    buildTypes {
        debug {
            // Debug-Signing (Standard-Konfiguration)
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // Release-Build mit Minifizierung und ProGuard-Regeln
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
    // Pfad zur Flutter-Modulquelle
    source = "../.."
}
