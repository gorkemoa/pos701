allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Build directory configuration removed as it was causing issues
}

// Build directory configuration removed - was causing path issues
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
