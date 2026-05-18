import com.flutter.gradle.tasks.FlutterTask
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.quotidian.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    lint {
        // Release-Lint kann bei einzelnen Plugins in AGP/Lint-Metaspace-Fehler laufen.
        checkReleaseBuilds = false
        abortOnError = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.quotidian.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    // Load keystore properties if present (key.properties at project root).
    val keystorePropertiesFile = rootProject.file("../key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }
    val storeFilePath = keystoreProperties.getProperty("storeFile") ?: "release.keystore"
    val storeFileExists = rootProject.file(storeFilePath).exists()
    val hasReleaseSigning = keystorePropertiesFile.exists() &&
        storeFileExists &&
        !keystoreProperties.getProperty("storeFile").isNullOrBlank() &&
        !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyPassword").isNullOrBlank()

    signingConfigs {
        create("release") {
            storeFile = rootProject.file(storeFilePath)
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

// Work around a Flutter Gradle plugin edge case where empty flavor names are
// propagated as "-dFlavor=" and can crash compileFlutterBuildDebug.
tasks.withType<FlutterTask>().configureEach {
    doFirst {
        if (flavor.isNullOrBlank()) {
            flavor = null
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
