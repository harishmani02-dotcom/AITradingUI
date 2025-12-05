name: Build Android APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:  
    - name: Checkout code  
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

    - name: Display current Android structure
      run: |
        echo "=== Current Android files ==="
        ls -la android/ || echo "No android folder"
        echo ""
        if [ -f android/app/build.gradle.kts ]; then
          echo "Found build.gradle.kts (Kotlin DSL)"
        fi
        if [ -f android/app/build.gradle ]; then
          echo "Found build.gradle (Groovy)"
        fi

    - name: Backup custom Android files
      run: |
        echo "=== Backing up custom files ==="
        mkdir -p /tmp/android_backup
        
        if [ -f android/app/src/main/AndroidManifest.xml ]; then
          cp android/app/src/main/AndroidManifest.xml /tmp/android_backup/
          echo "✓ Backed up AndroidManifest.xml"
        fi
        
        if [ -d android/app/src/main/res ]; then
          cp -r android/app/src/main/res /tmp/android_backup/
          echo "✓ Backed up res folder"
        fi
        
        if [ -d android/app/src/main/kotlin ]; then
          cp -r android/app/src/main/kotlin /tmp/android_backup/
          echo "✓ Backed up kotlin folder"
        fi

    - name: Recreate Android folder with supported structure
      run: |
        echo "=== Removing old Android folder ==="
        rm -rf android/
        echo "✓ Removed"
        
        echo "=== Creating new Android project ==="
        flutter create --platforms=android .
        echo "✓ Created"

    - name: Restore custom Android files
      run: |
        echo "=== Restoring custom files ==="
        
        if [ -f /tmp/android_backup/AndroidManifest.xml ]; then
          cp /tmp/android_backup/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
          echo "✓ Restored AndroidManifest.xml"
        fi
        
        if [ -d /tmp/android_backup/res ]; then
          cp -r /tmp/android_backup/res/* android/app/src/main/res/ 2>/dev/null || true
          echo "✓ Restored res folder"
        fi
        
        if [ -d /tmp/android_backup/kotlin ]; then
          mkdir -p android/app/src/main/kotlin
          cp -r /tmp/android_backup/kotlin/* android/app/src/main/kotlin/
          echo "✓ Restored kotlin folder"
        fi

    - name: Verify secrets are set  
      run: |  
        if [ -z "${{ secrets.SUPABASE_URL }}" ]; then  
          echo "ERROR: SUPABASE_URL secret is not set!"  
          exit 1  
        fi  
        if [ -z "${{ secrets.SUPABASE_ANON_KEY }}" ]; then  
          echo "ERROR: SUPABASE_ANON_KEY secret is not set!"  
          exit 1  
        fi  
        if [ -z "${{ secrets.GEMINI_API_KEY }}" ]; then  
          echo "ERROR: GEMINI_API_KEY secret is not set!"  
          exit 1  
        fi  
        echo "✓ All secrets are set"  

    - name: Create .env file  
      run: |  
        echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" > .env  
        echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env  
        echo "GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}" >> .env  
        echo "✓ .env file created"  
         
    - name: Verify .env file  
      run: |  
        if [ ! -f .env ]; then  
          echo "ERROR: .env file was not created!"  
          exit 1  
        fi  
        echo "✓ .env file exists"  
        echo "File size: $(wc -c < .env) bytes"  
        if [ $(wc -c < .env) -lt 100 ]; then  
          echo "WARNING: .env file seems too small (less than 100 bytes)!"  
          echo "This might indicate empty secret values."  
        fi  
        if grep -q "SUPABASE_URL=https://" .env; then  
          echo "✓ SUPABASE_URL has correct format"  
        else  
          echo "ERROR: SUPABASE_URL is missing or malformed!"  
          exit 1  
        fi  
        if grep -q "SUPABASE_ANON_KEY=eyJ" .env; then  
          echo "✓ SUPABASE_ANON_KEY has correct format"  
        else  
          echo "ERROR: SUPABASE_ANON_KEY is missing or malformed!"  
          exit 1  
        fi  
        if grep -q "GEMINI_API_KEY=AIza" .env; then  
          echo "✓ GEMINI_API_KEY has correct format"  
        else  
          echo "ERROR: GEMINI_API_KEY is missing or malformed!"  
          exit 1  
        fi  

    - name: Decode keystore  
      run: |  
        echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks  
        echo "✓ Keystore decoded"

    - name: Create key.properties  
      run: |  
        echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties  
        echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties  
        echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties  
        echo "storeFile=upload-keystore.jks" >> android/key.properties  
        echo "✓ key.properties created"

    - name: Configure signing in build.gradle
      run: |
        # Insert signing configuration into the existing build.gradle
        cat > /tmp/signing_config.txt << 'EOF'

def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
EOF

        # Append to build.gradle
        cat /tmp/signing_config.txt >> android/app/build.gradle
        echo "✓ Signing configuration added"

    - name: Clean and get dependencies  
      run: |  
        flutter clean  
        flutter pub get  
 
    - name: Generate app icons  
      run: |  
        echo "Generating launcher icons..."  
        dart run flutter_launcher_icons  
        echo "✓ Icons generated"  

    - name: Build APK  
      run: flutter build apk --release --verbose  

    - name: Verify APK includes .env  
      run: |  
        echo "=== Checking if .env is bundled in APK ==="  
        unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "flutter_assets" | grep ".env" || echo "WARNING: .env might not be in APK!"  

    - name: Upload APK  
      uses: actions/upload-artifact@v4  
      with:  
        name: app-release-apk  
        path: build/app/outputs/flutter-apk/app-release.apk  

    - name: Build AAB  
      run: flutter build appbundle --release  

    - name: Upload AAB  
      uses: actions/upload-artifact@v4  
      with:  
        name: app-release-aab  
        path: build/app/outputs/bundle/release/app-release.aab
