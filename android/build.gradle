buildscript {
    ext.kotlin_version = '1.8.0'
    repositories {
        google()
        mavenCentral()
    }
 
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
 
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
 
rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
    
    // Force compileSdk for all subprojects
    afterEvaluate { project ->
        if (project.hasProperty("android")) {
            android {
                compileSdkVersion 34
            }
        }
    }
}
 
tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
 
