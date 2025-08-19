// --- Kotlin DSL Imports ---
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // Passe das auf deinen finalen Paketnamen an, muss mit google-services.json übereinstimmen
    namespace = "com.example.tapem"

    // Von Flutter vorgegeben (aus flutter.gradle)
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = "27.0.12077973" // nur falls wirklich benötigt

    defaultConfig {
        applicationId = "com.example.tapem"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // multiDexEnabled = true // nur, wenn du wirklich ans 65k-Methodenlimit kommst

        // Falls dein Manifest auf diesen String verweist (FCM Default Channel):
        // So stellst du sicher, dass die Ressource existiert.
        resValue("string", "default_notification_channel_id", "default_channel")
    }

    // Java/Kotlin 17 (AGP 8.x + Flutter 3.35)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf("-Xjvm-default=all")
    }

    // --- Signing: Release liest aus key.properties ---
    signingConfigs {
        // Debug-Config existiert automatisch
        create("release") {
            // Du verwendest eine .jks-Datei -> storeType auf "jks" setzen (oder ganz weglassen)
            storeType = "jks"
            val propsFile = file("../key.properties")
            if (propsFile.exists()) {
                val props = Properties().apply { FileInputStream(propsFile).use { load(it) } }
                storeFile     = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias      = props.getProperty("keyAlias")
                keyPassword   = props.getProperty("keyPassword")
            } else {
                println("⚠️ key.properties fehlt – Release kann nicht korrekt signiert werden.")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // nutzt die Standard-Debug-Signatur
            signingConfig = signingConfigs.getByName("debug")
            // Debug bleibt ungeschrumpft für bessere Developer-Erfahrung
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            // R8 aktiv, aber mit passenden Keep-Regeln (siehe proguard-rules.pro weiter unten)
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Optional: falls du native/crashlytics-symbole brauchst
            // ndk { debugSymbolLevel = "SYMBOL_TABLE" }
        }
    }

    // (Optional) Lint locker halten für Sideload-Tests – für Play-Release lieber wieder aktivieren
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    // Packaging: Duplikate/Warnungen vermeiden
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE*",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/INDEX.LIST"
            )
        }
    }
}

// Fix für „Duplicate class … play.core.common …“ (tritt bei manchen Setups auf)
configurations.configureEach {
    exclude(group = "com.google.android.play", module = "core-common")
}

flutter {
    source = "../.."
}

dependencies {
    // (Optional) Falls du Foldables/APIs brauchst – ansonsten kannst du diese zwei entfernen
    implementation("androidx.window:window:1.3.0")
    implementation("androidx.window:window-java:1.3.0")

    // Für Deferred Components / SplitInstall (von Flutter referenziert)
    implementation("com.google.android.play:core:1.10.3")

    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
