import java.io.FileInputStream
import java.util.Properties

// Release signing: put your upload keystore details in android/key.properties
// (gitignored — never commit it). See README "Building a release". Without
// that file the release build falls back to the debug key so that
// `flutter run --release` keeps working locally, but such a build must NOT be
// published.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Reads google-services.json in this directory and wires up Firebase —
    // required for the OneSignal Android SDK to register with FCM and get a
    // real push token (see push-notification-not-working investigation).
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.fyp_cims"
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
        applicationId = "com.example.fyp_cims"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // tflite_flutter (the on-device skill model) needs Android 8.0 (API 26) or newer.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // Keep the native libraries compressed inside the APK so the file is smaller to
            // download and to send (the installed app is a little bigger on the phone instead).
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties: debug key, for local testing only.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
