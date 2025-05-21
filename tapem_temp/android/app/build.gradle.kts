// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// 1️⃣ local.properties einlesen, um flutter.sdk zu bekommen
val localProps = Properties().apply {
    rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}
val flutterRoot: String = localProps.getProperty("flutter.sdk")
    ?: error("flutter.sdk nicht in local.properties gesetzt")

// 2️⃣ buildscript-Block für Android- und Google-Services-Plugin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// 3️⃣ Plugin-Anwendung
apply(plugin = "com.android.application")
apply(plugin = "org.jetbrains.kotlin.android")
apply(plugin = "com.google.gms.google-services")
// Flutter-Gradle-Plugin über das Skript aus dem SDK
apply(from = "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle")

android {
    // 4️⃣ Basis-Konfiguration
    namespace = "com.example.tapem_temp"    // ggf. an dein Package anpassen
    compileSdk = (project.property("flutter.compileSdkVersion") as String).toInt()

    defaultConfig {
        applicationId = "com.example.tapem_temp"
        minSdk = 23                            // Firebase-Plugins erfordern ≥23
        targetSdk = (project.property("flutter.targetSdkVersion") as String).toInt()
        versionCode = (project.property("flutter.versionCode") as String).toInt()
        versionName = project.property("flutter.versionName") as String

        // App-Name für Dev-Build
        resValue("string", "app_name", "Tap’em (Dev)")
    }

    // 5️⃣ NDK-Version, die kompatibel mit Firebase-Core/Auth/Firestore ist
    ndkVersion = "27.0.12077973"

    // 6️⃣ Java & Kotlin Kompatibilität
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11"
            freeCompilerArgs += listOf("-Xjvm-default=compatibility")
        }
    }

    // 7️⃣ Build-Types
    signingConfigs {
        // Debug-Signatur (Standard)
        getByName("debug")
        // Release-Signatur (optional über key.properties)
        create("release") {
            rootProject.file("key.properties").takeIf { it.exists() }?.let { file ->
                val props = Properties().apply { FileInputStream(file).use { load(it) } }
                keyAlias = props["keyAlias"] as String
                keyPassword = props["keyPassword"] as String
                storeFile = props["storeFile"]?.let { file(it as String) }
                storePassword = props["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // 8️⃣ Packaging-Options gegen Kotlin-Metadaten-Konflikte
    packagingOptions {
        resources.excludes.add("/META-INF/*.kotlin_module")
    }
}

dependencies {
    // Kotlin Standard-Library, alle Flutter-Plugins werden automatisch eingebunden
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:${property("kotlin_version")}")
}
