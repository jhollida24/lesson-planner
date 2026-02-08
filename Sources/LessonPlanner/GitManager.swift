import Foundation

struct GitManager {
    static func push(repoPath: String, branch: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["push", "origin", "\(branch):\(branch)"]
        process.currentDirectoryURL = URL(fileURLWithPath: repoPath)
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
            print(output)
        }
        
        if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
            print(error)
        }
        
        if process.terminationStatus != 0 {
            throw LessonPlannerError.invalidLesson("Git push failed with status \(process.terminationStatus)")
        }
    }
}
