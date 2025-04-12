plugins {
    id("com.android.application")
    id("kotlin-android")
    // Das Flutter Gradle Plugin muss nach den Android- und Kotlin-Plugins angewendet werden.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gymapp"
    compileSdk = flutter.compileSdkVersion
    // Liest die NDK-Version aus gradle.properties oder verwendet den Standardwert, wenn nichts definiert ist.
    ndkVersion = (project.findProperty("android.ndkVersion") ?: "27.0.12077973") as String

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.gymapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug-Keys werden hier für den Release-Build verwendet – passe das für einen echten Release an.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
