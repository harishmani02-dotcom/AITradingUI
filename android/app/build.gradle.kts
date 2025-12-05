plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties once at the top (safe)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.FinsparkAIplay.ai_trading_signals"
    compileSdk = 35
    ndkVersion = "27.0.12077973" // latest stable

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
        targetSdk = 35
        versionCode = 3
        versionName = "2.0.0"
    }

    signingConfigs {
        create("release") {
            val keyAlias = keystoreProperties["keyAlias"] as String?
            val keyPassword = keystoreProperties["keyPassword"] as String?
            val storePassword = keystoreProperties["storePassword"] as String?
            val storeFilePath = keystoreProperties["storeFile"] as String?

            if (keyAlias != null && keyPassword != null && storePassword != null && storeFilePath != null) {
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
                this.storePassword = storePassword
                storeFile = file(storeFilePath)
            } else {
                println("Warning: key.properties incomplete – release signing will use debug keys")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    // Fix for duplicate META-INF licenses (required since AGP 8+)
    packaging {
        resources {
            excludes += setOf(
                "/META-INF/AL2.0",
                "/META-INF/LGPL2.1",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Only add MultiDex if you really have >64k methods (99% of Flutter apps don’t need it anymore)
dependencies {
    // implementation("androidx.multidex:multidex:2.0.1")
}
