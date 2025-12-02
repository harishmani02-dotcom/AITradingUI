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
    namespace = "com.FinsparkAIplay.ai_trading_signals"
    compileSdk = 35
    ndkVersion = "25.1.8937393"
 
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
 
    kotlinOptions {
        jvmTarget = "11"
    }
 
    defaultConfig {
        applicationId = "com.FinsparkAIplay.ai_trading_signals"
        minSdk = 21
        targetSdk = 35
        versionCode = 3
        versionName = "2.0.0"
       
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
