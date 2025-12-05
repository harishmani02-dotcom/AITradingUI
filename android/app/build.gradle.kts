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
        # Verify structure without revealing secrets  
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

    - name: Display current Gradle files (for debugging)
      run: |
        echo "=== Current Android structure ==="
        ls -la android/
        echo ""
        echo "=== Current app/build.gradle.kts content ==="
        if [ -f android/app/build.gradle.kts ]; then
          cat android/app/build.gradle.kts
        else
          echo "app/build.gradle.kts not found"
        fi
        echo ""
        echo "=== Current build.gradle.kts content ==="
        if [ -f android/build.gradle.kts ]; then
          cat android/build.gradle.kts
        else
          echo "build.gradle.kts not found"
        fi
        echo ""
        echo "=== Current settings.gradle.kts content ==="
        if [ -f android/settings.gradle.kts ]; then
          cat android/settings.gradle.kts
        else
          echo "settings.gradle.kts not found"
        fi

    - name: Backup custom Android files
      run: |
        echo "=== Backing up custom files ==="
        mkdir -p /tmp/android_backup
        
        # Backup AndroidManifest if it has custom content
        if [ -f android/app/src/main/AndroidManifest.xml ]; then
          cp android/app/src/main/AndroidManifest.xml /tmp/android_backup/
          echo "✓ Backed up AndroidManifest.xml"
        fi
        
        # Backup any custom drawables/resources
        if [ -d android/app/src/main/res ]; then
          cp -r android/app/src/main/res /tmp/android_backup/
          echo "✓ Backed up res folder"
        fi
        
        # Backup kotlin files if any
        if [ -d android/app/src/main/kotlin ]; then
          cp -r android/app/src/main/kotlin /tmp/android_backup/
          echo "✓ Backed up kotlin folder"
        fi

    - name: Delete and recreate Android folder
      run: |
        echo "=== Removing old Android folder ==="
        rm -rf android/
        echo "✓ Android folder removed"
        
        echo "=== Creating new Android project ==="
        flutter create --platforms=android --org com.example --project-name ai_trading_signals .
        echo "✓ New Android project created"

    - name: Restore custom Android files
      run: |
        echo "=== Restoring custom files ==="
        
        # Restore AndroidManifest if we backed it up
        if [ -f /tmp/android_backup/AndroidManifest.xml ]; then
          cp /tmp/android_backup/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
          echo "✓ Restored AndroidManifest.xml"
        fi
        
        # Restore resources if we backed them up
        if [ -d /tmp/android_backup/res ]; then
          cp -r /tmp/android_backup/res/* android/app/src/main/res/ 2>/dev/null || true
          echo "✓ Restored res folder"
        fi
        
        # Restore kotlin files if we backed them up
        if [ -d /tmp/android_backup/kotlin ]; then
          mkdir -p android/app/src/main/kotlin
          cp -r /tmp/android_backup/kotlin/* android/app/src/main/kotlin/
          echo "✓ Restored kotlin folder"
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

    - name: Update app/build.gradle for signing
      run: |
        cat >> android/app/build.gradle << 'EOF'

// Load keystore properties
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    
    android {
        signingConfigs {
            release {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
        buildTypes {
            release {
                signingConfig signingConfigs.release
            }
        }
    }
}
EOF
        echo "✓ Signing configuration added to build.gradle"

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
