plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
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
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ai_trading_signals"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ADD THIS: Enable MultiDex support
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // OPTION 1: DISABLE MINIFICATION (Quick fix for testing)
            minifyEnabled = false
            shrinkResources = false
            
            // OPTION 2: ENABLE WITH PROGUARD (Better for production)
            // Uncomment these and comment out the lines above once proguard-rules.pro is created:
            // minifyEnabled = true
            // shrinkResources = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ADD THIS: MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
}
