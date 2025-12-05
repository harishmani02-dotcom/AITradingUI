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


    #-------------------------------------------
    # 🔐 Secret Validation
    #-------------------------------------------
    - name: Verify secrets are set
      run: |
        if [ -z "${{ secrets.SUPABASE_URL }}" ]; then echo "❌ SUPABASE_URL missing"; exit 1; fi
        if [ -z "${{ secrets.SUPABASE_ANON_KEY }}" ]; then echo "❌ SUPABASE_ANON_KEY missing"; exit 1; fi
        if [ -z "${{ secrets.GEMINI_API_KEY }}" ]; then echo "❌ GEMINI_API_KEY missing"; exit 1; fi
        echo "✓ All secrets available"


    #-------------------------------------------
    # 📄 Create .env at runtime
    #-------------------------------------------
    - name: Create .env file
      run: |
        echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" > .env
        echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
        echo "GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}" >> .env
        echo "✓ .env created with Supabase + Gemini"


    #-------------------------------------------
    # 🧪 Validate .env
    #-------------------------------------------
    - name: Verify .env
      run: |
        if [ ! -f .env ]; then echo "❌ .env file not created"; exit 1; fi
        echo "✓ .env exists"
        echo "Size: $(wc -c < .env) bytes"
        grep -q "SUPABASE_URL=https" .env || (echo "❌ URL format wrong"; exit 1)
        grep -q "SUPABASE_ANON_KEY=eyJ" .env || (echo "❌ Supabase key wrong"; exit 1)
        grep -q "GEMINI_API_KEY=AIza" .env || (echo "❌ Gemini key wrong"; exit 1)
        echo "✓ .env validated successfully"


    #-------------------------------------------
    # 🔑 Setup Keystore
    #-------------------------------------------
    - name: Decode keystore
      run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

    - name: Create key.properties
      run: |
        echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
        echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
        echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
        echo "storeFile=upload-keystore.jks" >> android/key.properties


    #-------------------------------------------
    - name: Clean & Get Packages
      run: |
        flutter clean
        flutter pub get

    - name: Generate App Icons
      run: |
        echo "Generating icons..."
        dart run flutter_launcher_icons
        echo "✓ Icons generated"


    #-------------------------------------------
    # 🏗 Build APK with Gemini injected
    #-------------------------------------------
    - name: Build APK
      env:
        GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
      run: |
        echo "Starting APK build..."
        flutter build apk --release --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY --verbose


    #-------------------------------------------
    # 🔎 Check if .env packaged
    #-------------------------------------------
    - name: Verify APK includes .env
      run: |
        unzip -l build/app/outputs/flutter-apk/app-release.apk | grep ".env" || echo "⚠ .env not packaged (ok if using dart-define)"


    #-------------------------------------------
    # ⬆ Upload APK & AAB
    #-------------------------------------------
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
