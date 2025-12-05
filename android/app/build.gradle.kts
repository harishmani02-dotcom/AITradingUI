name: Build Android (Full CI)

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      flavors:
        description: 'Comma separated flavors to build (dev,stage,prod)'
        default: 'dev,stage,prod'
      targets:
        description: 'Targets: apk,aab'
        default: 'apk,aab'
      run_tests:
        description: 'Run flutter tests?'
        default: 'true'

permissions:
  contents: write
  packages: write

env:
  # Defaults for flutter
  FLUTTER_VERSION: "3.24.0"
  FLUTTER_CHANNEL: "stable"
  KEYSTORE_PATH: android/app/upload-keystore.jks
  KEYSTORE_PROPERTIES: android/keystore.properties
  BUILD_OUTPUT_DIR: build/outputs

jobs:
  prepare:
    name: Prepare environment & validate secrets
    runs-on: ubuntu-latest
    outputs:
      flavors: ${{ steps.set-flavors.outputs.flavors }}
      targets: ${{ steps.set-targets.outputs.targets }}
      run_tests: ${{ steps.set-tests.outputs.run_tests }}
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Validate required secrets (non-blocking for optional ones)
      run: |
        missing=""
        for s in SUPABASE_URL SUPABASE_ANON_KEY GEMINI_API_KEY KEYSTORE_BASE64 KEYSTORE_PASSWORD KEY_PASSWORD KEY_ALIAS; do
          if [ -z "${{ secrets[$s] }}" ]; then
            missing="$missing $s"
          fi
        done
        if [ -n "$missing" ]; then
          echo "ERROR: Required secrets missing:$missing"
          exit 1
        fi
        echo "✓ required secrets present"

    - name: Set workflow inputs
      id: set-flavors
      run: |
        FLAVORS="${{ github.event.inputs.flavors || '' }}"
        if [ -z "$FLAVORS" ]; then FLAVORS="dev,stage,prod"; fi
        echo "::set-output name=flavors::$FLAVORS"
    - name: Set targets
      id: set-targets
      run: |
        TARGETS="${{ github.event.inputs.targets || '' }}"
        if [ -z "$TARGETS" ]; then TARGETS="apk,aab"; fi
        echo "::set-output name=targets::$TARGETS"
    - name: Set tests flag
      id: set-tests
      run: |
        RUN_TESTS="${{ github.event.inputs.run_tests || 'true' }}"
        echo "::set-output name=run_tests::$RUN_TESTS"

  build:
    name: Build, test, sign, upload
    needs: prepare
    runs-on: ubuntu-latest
    env:
      SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
      SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
      GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
    steps:
    - name: Checkout code (full)
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Setup Java (Zulu 17)
      uses: actions/setup-java@v4
      with:
        distribution: 'zulu'
        java-version: '17'

    - name: Cache Flutter SDK
      uses: actions/cache@v4
      id: flutter-cache
      with:
        path: ~/.pub-cache
        key: flutter-pub-${{ runner.os }}-v1-${{ hashFiles('**/pubspec.yaml') }}
        restore-keys: |
          flutter-pub-${{ runner.os }}-v1-

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: ${{ env.FLUTTER_CHANNEL }}

    - name: Cache Gradle
      uses: actions/cache@v4
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrapper
        key: gradle-cache-${{ runner.os }}-${{ hashFiles('**/*.gradle*','**/gradle-wrapper.properties') }}
        restore-keys: gradle-cache-${{ runner.os }}-

    - name: Validate repo layout (basic)
      run: |
        if [ ! -f "pubspec.yaml" ]; then echo "ERROR: pubspec.yaml not found"; exit 1; fi
        echo "✓ pubspec.yaml present"

    - name: Create runtime .env (Supabase + Gemini)
      run: |
        echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" > .env
        echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
        echo "GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}" >> .env
        echo "✓ .env created"

    - name: Verify .env (format checks - non-sensitive)
      run: |
        if [ ! -f .env ]; then echo ".env missing"; exit 1; fi
        grep -q "SUPABASE_URL=https" .env || (echo "WARNING: SUPABASE_URL format check failed"; )
        grep -q "SUPABASE_ANON_KEY=" .env || (echo "WARNING: SUPABASE_ANON_KEY missing format check"; )
        grep -q "GEMINI_API_KEY=" .env || (echo "WARNING: GEMINI_API_KEY missing format check"; )

    - name: Decode keystore
      run: |
        echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > ${KEYSTORE_PATH}
        mkdir -p android
        echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > ${KEYSTORE_PROPERTIES}
        echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> ${KEYSTORE_PROPERTIES}
        echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> ${KEYSTORE_PROPERTIES}
        echo "storeFile=${KEYSTORE_PATH}" >> ${KEYSTORE_PROPERTIES}
        ls -l ${KEYSTORE_PATH}
        cat ${KEYSTORE_PROPERTIES} | sed -n '1,1p'

    - name: flutter pub get
      run: |
        flutter pub get

    - name: Run flutter tests
      if: needs.prepare.outputs.run_tests == 'true'
      run: |
        flutter test --coverage || (echo "❗ Tests failed"; exit 1)

    - name: Generate app icons
      run: |
        if grep -q "flutter_launcher_icons" pubspec.yaml; then
          dart run flutter_launcher_icons
          echo "✓ Icons generated"
        else
          echo "No flutter_launcher_icons setup found - skipping"
        fi

    - name: Auto bump version (optional)
      id: bump_version
      run: |
        # Simple automatic patch bump in pubspec.yaml (commits back)
        # Requires GITHUB_TOKEN or GITHUB_PAT with push permissions.
        echo "Bumping pubspec.yaml patch version..."
        ver=$(grep '^version:' pubspec.yaml | head -n1 | awk '{print $2}')
        if [ -z "$ver" ]; then
          echo "No version found in pubspec.yaml"; echo "::set-output name=new_version::"; exit 0
        fi
        # Split versionName+build (e.g., 1.0.0+1)
        name=$(echo $ver | cut -d+ -f1)
        code=$(echo $ver | cut -d+ -f2)
        if [ -z "$code" ]; then code=1; fi
        newcode=$((code + 1))
        newver="${name}+${newcode}"
        echo "Old: $ver -> New: $newver"
        sed -i "s/^version: .*/version: ${newver}/" pubspec.yaml
        git config user.name "github-actions[bot]"
        git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
        git add pubspec.yaml
        git commit -m "ci: bump version to ${newver}" || echo "No changes to commit"
        git push origin HEAD:${{ github.ref_name }} || echo "Push failed (token perms?)"
        echo "::set-output name=new_version::${newver}"

    - name: Prepare list of flavors & targets
      id: parse
      run: |
        FLAVORS="${{ needs.prepare.outputs.flavors }}"
        TARGETS="${{ needs.prepare.outputs.targets }}"
        # normalize
        echo "::set-output name=flavors::${FLAVORS}"
        echo "::set-output name=targets::${TARGETS}"
      shell: bash

    - name: Build artifacts (APKs & AABs) per flavor & target
      id: build-artifacts
      run: |
        IFS=',' read -ra FL <<< "${{ steps.parse.outputs.flavors }}"
        IFS=',' read -ra TG <<< "${{ steps.parse.outputs.targets }}"
        mkdir -p build_artifacts
        for flavor in "${FL[@]}"; do
          flavor=$(echo "$flavor" | tr -d '[:space:]')
          for tgt in "${TG[@]}"; do
            tgt=$(echo "$tgt" | tr -d '[:space:]')
            echo "==> Building flavor: $flavor target: $tgt"
            # choose build commands
            if [ "$tgt" = "apk" ]; then
              # produce both universal and split per ABI
              flutter build apk --flavor $flavor --target-platform android-arm,android-arm64 --split-per-abi --release --dart-define=GEMINI_API_KEY=${GEMINI_API_KEY}
              # collect outputs
              cp build/app/outputs/flutter-apk/app-$flavor-release.apk build_artifacts/app-$flavor-release.apk || true
              cp build/app/outputs/flutter-apk/app-$flavor-arm64-v8a-release.apk build_artifacts/app-$flavor-arm64-v8a-release.apk || true
              cp build/app/outputs/flutter-apk/app-$flavor-arm64-v8a-release.apk build_artifacts/app-$flavor-arm64-v8a-release.apk || true
            elif [ "$tgt" = "aab" ] || [ "$tgt" = "bundle" ]; then
              flutter build appbundle --flavor $flavor --release --dart-define=GEMINI_API_KEY=${GEMINI_API_KEY}
              cp build/app/outputs/bundle/release/app-$flavor-release.aab build_artifacts/ 2>/dev/null || cp build/app/outputs/bundle/release/app-release.aab build_artifacts/ 2>/dev/null || true
            else
              echo "Unknown target $tgt - skipping"
            fi
          done
        done
        # Zip artifacts
        cd build_artifacts || exit 0
        zip -r ../artifacts-${{ github.run_id }}.zip . || true
        cd - || true
        echo "Artifacts zipped at artifacts-${{ github.run_id }}.zip"
      env:
        GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}

    - name: Upload artifacts (raw)
      uses: actions/upload-artifact@v4
      with:
        name: ci-artifacts-${{ github.run_id }}
        path: |
          build_artifacts/**
          artifacts-${{ github.run_id }}.zip

    - name: Create GitHub Release (draft) and upload assets
      if: startsWith(github.ref, 'refs/heads/')
      uses: softprops/action-gh-release@v1
      with:
        tag_name: "ci-build-${{ github.run_id }}"
        name: "CI Build ${{ github.run_id }}"
        body: |
          CI build artifacts for run ${{ github.run_id }}.
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: Upload release assets (zip)
      if: startsWith(github.ref, 'refs/heads/')
      uses: actions/upload-release-asset@v1
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: artifacts-${{ github.run_id }}.zip
        asset_name: artifacts-${{ github.run_id }}.zip
        asset_content_type: application/zip
      # Note: some runners might need permissions; if upload fails, artifacts still present in actions artifacts

    - name: Upload to Google Play (internal) - optional
      if: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT != '' }}
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJson: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
        packageName: com.harismani02.aitradingui
        releaseFiles: build_artifacts/*.aab
        track: internal
      env:
        GOOGLE_PLAY_SERVICE_ACCOUNT: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}

    - name: Firebase App Distribution (optional)
      if: ${{ secrets.FIREBASE_TOKEN != '' }}
      uses: wzieba/Firebase-Distribution-Github-Action@v1
      with:
        appId: ${{ secrets.FIREBASE_APP_ID }}
        token: ${{ secrets.FIREBASE_TOKEN }}
        groups: testers
        file: build_artifacts/*.aab

    - name: Sentry Gradle upload (optional)
      if: ${{ secrets.SENTRY_AUTH_TOKEN != '' }}
      run: |
        echo "Uploading ProGuard / mapping to Sentry (if configured)"
        # Requires sentry-cli and proper config in android/app/build.gradle.kts
        if command -v sentry-cli >/dev/null 2>&1; then
          for f in build_artifacts/*; do
            echo "Would upload $f to sentry (placeholder)"
          done
        else
          echo "sentry-cli not installed in runner - skipping actual upload"
        fi

    - name: Firebase / Sentry / Post build hook (optional script)
      run: |
        if [ -f scripts/post_build.sh ]; then
          chmod +x scripts/post_build.sh
          scripts/post_build.sh
        else
          echo "No post_build.sh found - skipping"
        fi

    - name: Clean up sensitive files
      run: |
        shred -u ${KEYSTORE_PATH} || rm -f ${KEYSTORE_PATH}
        shred -u ${KEYSTORE_PROPERTIES} || rm -f ${KEYSTORE_PROPERTIES}
        rm -f .env

  finalize:
    name: Finalize & notify
    needs: [build]
    runs-on: ubuntu-latest
    steps:
    - name: Notify success
      run: |
        echo "Build job finished. Artifacts uploaded to Actions artifacts and Release (if created)."
