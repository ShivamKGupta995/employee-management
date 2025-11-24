plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.employee_system"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 1. THIS ENABLED THE FEATURE (You already have this)
        isCoreLibraryDesugaringEnabled = true 

        // NOTE: Standard Flutter usually uses VERSION_1_8, but 11 is often fine too.
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.employee_system"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// =========================================================
// 2. ADD THIS BLOCK AT THE END OF THE FILE
// =========================================================
dependencies {
    // This is the required library for the feature you enabled above
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}