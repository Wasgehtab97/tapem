import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle Plugin für App-Builds
        classpath("com.android.tools.build:gradle:8.7.0")
        // Google-Services Plugin für Firebase-Integration
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Zentralisiertes Build-Output außerhalb des Projekt-Roots
val rootBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(rootBuildDir)

subprojects {
    // Jedes Subprojekt erhält ein eigenes Build-Verzeichnis
    val subProjectBuildDir = rootBuildDir.dir(project.name)
    project.layout.buildDirectory.value(subProjectBuildDir)

    // Stelle sicher, dass :app immer zuerst ausgewertet wird
    evaluationDependsOn(":app")
}

// Clean-Task für das gesamte Projekt
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
