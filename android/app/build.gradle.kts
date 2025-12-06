- name: Debug Android Structure
      run: |
        echo "=== Checking Android directory structure ==="
        ls -la android/
        ls -la android/app/
        echo "=== Checking for existing build files ==="
        find android/app -name "build.gradle*" -type f
        
    - name: Force Remove All Build Files
      run: |
        find android/app -name "build.gradle" -type f -delete
        find android/app -name "build.gradle.kts" -type f -delete
        echo "All build.gradle files removed"

    - name: Create New app/build.gradle.kts
      run: |
        cat > android/app/build.gradle.kts << 'EOF'
        import java.util.Properties
        import java.io.FileInputStream
        
        plugins {
            id("com.android.application")
            id("kotlin-android")
            id("dev.flutter.flutter-gradle-plugin")
        }
        
        kotlin {
            jvmToolchain(17)
        }
        
        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localProperties.load(FileInputStream(localPropertiesFile))
        }
        
        val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
        val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"
        
        android {
            namespace = "com.finspark.ai"
            compileSdk = 34
            
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            
            kotlinOptions {
                jvmTarget = "17"
            }
            
            sourceSets {
                getByName("main") {
                    java.srcDir("src/main/kotlin")
                }
            }
            
            defaultConfig {
                applicationId = "com.finspark.ai"
                minSdk = 21
                targetSdk = 34
                versionCode = flutterVersionCode
                versionName = flutterVersionName
                multiDexEnabled = true
            }
            
            signingConfigs {
                create("release") {
                    storeFile = file("upload-keystore.jks")
                    storePassword = System.getenv("KEYSTORE_PASSWORD")
                    keyAlias = System.getenv("KEY_ALIAS")
                    keyPassword = System.getenv("KEY_PASSWORD")
                }
            }
            
            buildTypes {
                getByName("release") {
                    signingConfig = signingConfigs.getByName("release")
                }
            }
            
            packaging {
                resources {
                    excludes += listOf(
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
        
        dependencies {
            implementation("androidx.multidex:multidex:2.0.1")
        }
        EOF

    - name: Verify No Shrink Settings
      run: |
        echo "=== Final build.gradle.kts content ==="
        cat android/app/build.gradle.kts
        echo ""
        echo "=== Checking for problematic settings ==="
        if grep -i "shrink" android/app/build.gradle.kts; then
          echo "ERROR: Found shrink settings!"
          exit 1
        fi
        if grep -i "minify" android/app/build.gradle.kts; then
          echo "ERROR: Found minify settings!"
          exit 1
        fi
        echo "✓ No shrink or minify settings found"
        
    - name: Check for other build files
      run: |
        echo "=== Searching for any other build configuration files ==="
        find android -name "*.gradle*" -type f | while read file; do
          echo "--- $file ---"
          if grep -i "shrinkResources\|isShrinkResources" "$file" 2>/dev/null; then
            echo "⚠️  Found shrinkResources in: $file"
            grep -n "shrinkResources\|isShrinkResources" "$file"
          fi
        done
