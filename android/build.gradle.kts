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
    val projectPath = project.projectDir.absolutePath
    val rootPath = rootProject.projectDir.absolutePath
    
    if (projectPath.length >= 2 && rootPath.length >= 2 && 
        projectPath[1] == ':' && rootPath[1] == ':' && 
        !projectPath.substring(0, 2).equals(rootPath.substring(0, 2), ignoreCase = true)) {
        
        val driveLetter = projectPath.substring(0, 2)
        val fallbackBuildDir = java.io.File(driveLetter + "\\temp\\flutter_builds\\" + project.name)
        project.layout.buildDirectory.set(fallbackBuildDir)
    } else {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

// 1. Force plugins to SDK 36 FIRST and enforce JVM target 11
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            @Suppress("DEPRECATION")
            project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                compileSdkVersion(36)
            }
        }
    }
}
// 2. Then evaluate them
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
