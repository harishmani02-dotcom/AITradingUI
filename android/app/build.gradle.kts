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
 
android {
    namespace = "com.example.ai_trading_signals"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
 
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
 
    kotlinOptions {
        jvmTarget = "11"
    }
 
    defaultConfig {
        applicationId = "com.example.ai_trading_signals"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
       
        multiDexEnabled = true
    }
 
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks")
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
 

