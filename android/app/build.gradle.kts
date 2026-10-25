import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.exists()) {
    FileInputStream(releasePropertiesFile).use { releaseProperties.load(it) }
}

android {
    namespace = "com.example.expense_orc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.expense_orc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (releasePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias = requireNotNull(releaseProperties.getProperty("keyAlias")) {
                    "android/key.properties must define keyAlias"
                }
                keyPassword = requireNotNull(releaseProperties.getProperty("keyPassword")) {
                    "android/key.properties must define keyPassword"
                }
                storeFile = file(
                    requireNotNull(releaseProperties.getProperty("storeFile")) {
                        "android/key.properties must define storeFile"
                    },
                )
                storePassword = requireNotNull(releaseProperties.getProperty("storePassword")) {
                    "android/key.properties must define storePassword"
                }
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            if (releasePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
