pluginManagement {
    val flutterSdkPath: String = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            properties.load(java.io.FileInputStream(localPropertiesFile))
        }
        val path = properties.getProperty("flutter.sdk")
        requireNotNull(path) { "flutter.sdk not set in local.properties" }
        path
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

include(":app")
