allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// file_picker 11's own android/build.gradle skips applying the Kotlin plugin
// on AGP 9+ (assumes Flutter's built-in Kotlin will compile its .kt sources
// instead), but android.builtInKotlin=false here — Flutter's built-in Kotlin
// is off because turning it on breaks other plugins (shared_preferences_android
// 2.4.13 still applies org.jetbrains.kotlin.android unconditionally and AGP9
// rejects that under built-in Kotlin). Apply the plugin ourselves for just
// this one module so its Kotlin sources actually compile.
subprojects {
    if (project.name == "file_picker") {
        pluginManager.apply("org.jetbrains.kotlin.android")
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
