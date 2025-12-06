plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}
 
android {
    namespace "com.example.aitradingui"
    compileSdk 34
    ndkVersion flutter.ndkVersion
 
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
 
    kotlinOptions {
        jvmTarget = '1.8'
    }
 
    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }
 
    defaultConfig {
        applicationId "com.example.aitradingui"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }
 
    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }
    }
}
 
flutter {
    source '../..'
}
 
dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.0"
}
 
