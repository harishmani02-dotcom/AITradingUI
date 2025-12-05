pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        
        // CRITICAL FIX: Add the Flutter SDK local Maven repository
        // This tells Gradle where to find the 'dev.flutter.flutter-gradle-plugin'
        maven(url = uri("${settings.rootDir}/../.android/Flutter/local/artifacts/repo"))
    }
}

plugins {
    id("com.android.application") version "8.1.2" apply false
    
    // TYPO FIXED: Removed the duplicate 'version "8.1.2") version "8.1.2"'
    id("com.android.library") version "8.1.2" apply false 
    
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

include(":app")
