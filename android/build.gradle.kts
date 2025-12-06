buildscript {
    val kotlinVersion = "1.8.0"
    
    repositories {
        google()
        mavenCentral()
    }
 
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}
 
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
 
rootProject.layout.buildDirectory.set(File("../build"))
 
subprojects {
    project.layout.buildDirectory.set(File(rootProject.layout.buildDirectory.get().asFile, project.name))
}
 
subprojects {
    project.evaluationDependsOn(":app")
}
 
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
 
