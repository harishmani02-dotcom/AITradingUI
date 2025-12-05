name: Build Android APK & AAB

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
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

    - name: Verify Secrets exist
      run: |
        for s in SUPABASE_URL SUPABASE_ANON_KEY GEMINI_API_KEY KEYSTORE_BASE64 KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD; do
          if [ -z "${{ secrets[$s] }}" ]; then
            echo "❌ Missing secret: $s"; exit 1;
          fi
        done
        echo "✅ All secrets found"

    - name: Create .env
      run: |
        echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" > .env
        echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
        echo "GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}" >> .env
        echo "ENV file created"

    - name: Decode keystore
      run: |
        echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-key.jks
        echo "Keystore restored"

    - name: Create key.properties
      run: |
        echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
        echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
        echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
        echo "storeFile=upload-key.jks" >> android/key.properties
        echo "key.properties created"

    - name: Fix build.gradle.kts (remove duplicate plugins if exists)
      run: |
        sed -i '/plugins {/q' android/app/build.gradle.kts # Keep first plugins block only
        echo "Applying final gradle config..."

        cat << 'EOF' >> android/app/build.gradle.kts

android {
    namespace = "com.finspark.ai"

    defaultConfig {
        applicationId = "com.finspark.ai"
    }

    signingConfigs {
        create("release") {
            val props = java.util.Properties()
            props.load(java.io.FileInputStream(rootProject.file("key.properties")))
            keyAlias = props["keyAlias"] as String
            keyPassword = props["keyPassword"] as String
            storeFile = file(props["storeFile"] as String)
            storePassword = props["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
        }
    }
}

EOF
        echo "Gradle config updated successfully"

    - name: Flutter pub get
      run: flutter pub get

    - name: Build APK
      run: flutter build apk --release --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}

    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: finspark-apk
        path: build/app/outputs/flutter-apk/app-release.apk

    - name: Build AAB
      run: flutter build appbundle --release --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}

    - name: Upload AAB
      uses: actions/upload-artifact@v4
      with:
        name: finspark-aab
        path: build/app/outputs/bundle/release/app-release.aab
