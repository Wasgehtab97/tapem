// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Das Flutter Gradle Plugin muss nach den Android- und Kotlin-Plugins angewendet werden.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gymapp"
    compileSdk = flutter.compileSdkVersion

    // Liest die NDK-Version aus gradle.properties oder verwendet einen Standardwert, falls nicht definiert.
    ndkVersion = (project.findProperty("android.ndkVersion") ?: "27.0.12077973") as String

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.gymapp"
        // Setze minSdk explizit auf 23, wie von Firebase empfohlen.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // In diesem Beispiel wird debug signingConfig verwendet – passe das für einen echten Release an.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Plugin für Google Services: Stellt sicher, dass die google-services.json angewendet wird.
// Dieser Plugin-Aufruf sollte nach allen anderen Konfigurationen erfolgen.
apply(plugin = "com.google.gms.google-services")
