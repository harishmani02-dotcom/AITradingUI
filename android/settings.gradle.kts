pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        
        // CRITICAL FIX: Use the FLUTTER_ROOT path for the local Maven repository
        // This is a more robust way to find the plugin in CI/CD environments.
        maven(url = uri("${settings.rootDir}/../${System.getenv("FLUTTER_ROOT")}/packages/flutter_tools/gradle"))
    }
}

plugins {
    id("com.android.application") version "8.1.2" apply false
    
    // NOTE: This line is already fixed from the previous typo
    id("com.android.library") version "8.1.2" apply false 
    
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

include(":app")
