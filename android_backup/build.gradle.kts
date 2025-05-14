import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.tasks.Delete

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Nur falls Du Google-Services nutzt:
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Einheitliches Kotlin-JVM-Target (für alle Module: app + plugins)
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11"
            freeCompilerArgs += "-Xjvm-default=compatibility"
        }
    }
}

// Ein einfacher clean-Task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
