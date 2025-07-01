allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Build dizinini Flutter'ın beklediği konuma ayarla
    buildDir = File(rootProject.projectDir, "../build/android/${project.name}")
}

// Build directory configuration removed - was causing path issues
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
