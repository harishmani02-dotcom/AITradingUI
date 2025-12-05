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

    - name: Decode keystore
      run: |
        echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

    - name: Create keystore.properties
      run: |
        echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/keystore.properties
        echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/keystore.properties
        echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/keystore.properties
        echo "storeFile=upload-keystore.jks" >> android/keystore.properties

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
