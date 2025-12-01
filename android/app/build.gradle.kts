plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
 
import java.util.Properties
import java.io.FileInputStream
 
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val flutterMinSdkVersion = 21
val flutterTargetSdkVersion = 34
val flutterCompileSdkVersion = 34
val flutterVersionCode = 1
val flutterVersionName = "1.0"

extra["flutter.minSdkVersion"] = flutterMinSdkVersion
extra["flutter.targetSdkVersion"] = flutterTargetSdkVersion
extra["flutter.compileSdkVersion"] = flutterCompileSdkVersion
extra["flutter.versionCode"] = flutterVersionCode
extra["flutter.versionName"] = flutterVersionName
 
android {
    namespace = "com.example.ai_trading_signals"
    compileSdk = flutterCompileSdkVersion
    ndkVersion = "25.1.8937393"
 
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
 
    kotlinOptions {
        jvmTarget = "11"
    }
 
    defaultConfig {
        applicationId = "com.example.ai_trading_signals"
        minSdk = flutterMinSdkVersion
        targetSdk = flutterTargetSdkVersion
        versionCode = flutterVersionCode
        versionName = flutterVersionName
       
        multiDexEnabled = true
    }
 
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let {
                if (it.startsWith("C:") || it.startsWith("/")) {
                    file(it)
                } else {
                    file("$projectDir/$it")
                }
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }
 
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
 
flutter {
    source = "../.."
}
 
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
