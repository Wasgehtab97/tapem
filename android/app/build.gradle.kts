// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin muss nach Android- und Kotlin-Plugins angewendet werden
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services Plugin für Firebase
    id("com.google.gms.google-services")
}

android {
    // Paket- und Namespace umbenannt von gymapp auf tapem
    namespace = "com.example.tapem"
    compileSdk = flutter.compileSdkVersion

    // NDK-Version aus gradle.properties lesen oder Default nutzen
    ndkVersion = (project.findProperty("android.ndkVersion") ?: "27.0.12077973") as String

    defaultConfig {
        // Application ID anpassen
        applicationId = "com.example.tapem"
        minSdk = 23                                   // Firebase empfiehlt mindestens 23
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
        // Optional: JVM Default Compatibility für Interfaces
        freeCompilerArgs += listOf("-Xjvm-default=compatibility")
    }

    buildTypes {
        debug {
            // Zum Testen weiter Debug-Signing nutzen
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // TODO: Release-SigningConfig hier eintragen, sobald vorhanden
            signingConfig = signingConfigs.getByName("debug")
            // ProGuard/R8 aktivieren für Minifizierung und Optimierung
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    // Standard-Pfad zur Flutter-Modul-Integration
    source = "../.."
}
