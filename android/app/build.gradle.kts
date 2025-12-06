- name: Update app/build.gradle.kts
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
                    // Disable minification and shrinking for faster builds
                    isMinifyEnabled = false
                    isShrinkResources = false
                }
                getByName("debug") {
                    isMinifyEnabled = false
                    isShrinkResources = false
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
