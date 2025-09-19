plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // ✅ aktifkan plugin Google Services
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.siaga_banjir"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.siaga_banjir"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
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

dependencies {
    // Firebase BoM (versi terbaru per 2025)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Firebase SDK yang dibutuhkan
    implementation("com.google.firebase:firebase-analytics")

    // Tambahkan produk Firebase lain sesuai kebutuhan
    // contoh:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
}
