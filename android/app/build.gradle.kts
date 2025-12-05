Plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
 
import java.util.Properties
import java.io.FileInputStream
 
// --- Start of Keystore Configuration Cleanup ---
// Use a single location to load the properties file.
// Assuming your properties file is named 'key.properties' in the root folder.
val keystorePropertiesFile = rootProject.file("key.properties") 
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// --- End of Keystore Configuration Cleanup ---
 
android {
    namespace = "com.FinsparkAIplay.ai_trading_signals"
    
    // 💡 FIX 1: Downgrade from 35 to 34 (latest stable SDK)
    compileSdk = 34 
    ndkVersion = "25.1.8937393"
 
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
 
    kotlinOptions {
        jvmTarget = "11"
    }
 
    defaultConfig {
        applicationId = "com.FinsparkAIplay.ai_trading_signals.v3"
        minSdk = 21
        
        // 💡 FIX 1: Downgrade from 35 to 34 (latest stable SDK)
        targetSdk = 34 
        versionCode = 3
        versionName = "2.0.0"
       
        multiDexEnabled = true
    }
 
signingConfigs {
    create("release") {
        
        // 💡 FIX 2: Use the keystoreProperties loaded at the top of the file
        if (keystoreProperties.isNotEmpty()) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storePassword = keystoreProperties["storePassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
        } else {
             // You may want to add a proper error message here if the file is missing
        }
    }
}

buildTypes {
    getByName("release") {
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
