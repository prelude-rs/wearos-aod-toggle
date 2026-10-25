plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.ktlint)
    alias(libs.plugins.detekt)
}

// Assinatura de release: propriedades aodtoggle.keystore.* (~/.gradle/gradle.properties, nunca no repositório).
fun signingProp(name: String): String? = providers.gradleProperty("aodtoggle.keystore.$name").orNull

val releaseSigningProps = listOf("file", "password", "alias", "keyPassword").associateWith(::signingProp)
val hasReleaseSigning = releaseSigningProps.values.all { !it.isNullOrBlank() }

android {
    namespace = "rs.prelude.aodtoggle"
    compileSdk = 36

    defaultConfig {
        applicationId = "rs.prelude.aodtoggle"
        minSdk = 34
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseSigningProps.getValue("file")!!)
                storePassword = releaseSigningProps.getValue("password")
                keyAlias = releaseSigningProps.getValue("alias")
                keyPassword = releaseSigningProps.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
        }
        release {
            isMinifyEnabled = false
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    lint {
        warningsAsErrors = false
    }
}

kotlin {
    jvmToolchain(17)
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom(rootProject.file("config/detekt/detekt.yml"))
}

dependencies {
    implementation(libs.watchface.complications.data.source.ktx)
    implementation(libs.androidx.core.ktx)

    testImplementation(libs.junit)

    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.test.ext.junit)
}
