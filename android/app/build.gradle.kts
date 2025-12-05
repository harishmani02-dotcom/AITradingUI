name: Build Android APK & AAB

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Java
      uses: actions/setup-java@v4
      with:
        distribution: 'zulu'
        java-version: '17'

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'

    ############################################
    # 1. Verify Secrets
    ############################################
    - name: Verify secrets
      run: |
        for v in SUPABASE_URL SUPABASE_ANON_KEY GEMINI_API_KEY KEYSTORE_BASE64 KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD; do
          if [ -z "${{ secrets[$v] }}" ]; then
            echo "❌ Missing secret: $v" && exit 1
          fi
        done
        echo "✔ All secrets available"

    ############################################
    # 2. Regenerate Android Folder Fresh
    ############################################
    - name: Recreate Android folder safely
      run: |
        mv android android_backup_$(date +%s) || true
        flutter create --platforms=android --project-name finsparkai --org com.finspark.ai .

    ############################################
    # 3. Apply Modern Gradle Fix (Important)
    ############################################
    - name: Fix Gradle settings
      run: |
        cat > android/settings.gradle << 'EOF'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
plugins {
    id "com.android.application" version "8.1.2" apply false
    id "org.jetbrains.kotlin.android" version "1.9.0" apply false
    id "dev.flutter.flutter-gradle-plugin" version "1.0.0" apply false
}
include ":app"
EOF

        cat > android/build.gradle << 'EOF'
allprojects {
    repositories { google(); mavenCentral() }
}
task clean(type: Delete) { delete rootProject.buildDir }
EOF

    ############################################
    # 4. Modify app/build.gradle to new format
    ############################################
    - name: Patch android/app/build.gradle
      run: |
        cat > android/app/build.gradle << 'EOF'
plugins {
    id "com.android.application"
    id "org.jetbrains.kotlin.android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.finspark.ai"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.finspark.ai"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }

    signingConfigs {
        release {
            storeFile file("upload-keystore.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

flutter { source '../..' }
EOF

    ############################################
    # 5. Decode Keystore for Release Signing
    ############################################
    - name: Decode Keystore File
      run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

    ############################################
    # 6. Build APK + AAB
    ############################################
    - name: Flutter Build
      run: |
        flutter pub get
        flutter build apk --release
        flutter build appbundle --release

    ############################################
    # 7. Upload Build Artifacts
    ############################################
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: FinsparkAI-APK
        path: build/app/outputs/flutter-apk/app-release.apk

    - name: Upload AAB
      uses: actions/upload-artifact@v4
      with:
        name: FinsparkAI-AAB
        path: build/app/outputs/bundle/release/app-release.aab
