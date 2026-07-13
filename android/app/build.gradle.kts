import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials live in android/key.properties (gitignored).
// See https://docs.flutter.dev/deployment/android#sign-the-app
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = keystoreProperties.containsKey("storeFile")

android {
    namespace = "com.hisp.hisp_mobile_trucker"
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
        applicationId = "com.hisp.hisp_mobile_trucker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else if ((project.findProperty("allowDebugSigning") as String?)
                    .toBoolean() ||
                System.getenv("ALLOW_DEBUG_SIGNING") == "true"
            ) {
                // Explicit opt-in only (-PallowDebugSigning=true or
                // ALLOW_DEBUG_SIGNING=true): lets `flutter run --release`
                // work on a dev machine. DO NOT distribute this build —
                // a debug-signed APK can never be updated in place.
                logger.warn(
                    "WARNING: release build signed with DEBUG keys " +
                    "(allowDebugSigning) - do not distribute."
                )
                signingConfig = signingConfigs.getByName("debug")
            } else {
                // A silently debug-signed "release" APK is a trap: once
                // installed it can never be updated with the real key.
                throw GradleException(
                    "Release build requires android/key.properties with the " +
                    "release keystore (see docs.flutter.dev/deployment/android" +
                    "#sign-the-app). To knowingly build a NON-distributable " +
                    "test APK with debug keys, pass -PallowDebugSigning=true " +
                    "or set ALLOW_DEBUG_SIGNING=true."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
