import Foundation

struct GooseInvoker {
    static func invoke(prompt: String, model: String, workingDir: String) throws {
        // Create working directory if it doesn't exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: workingDir) {
            try fileManager.createDirectory(
                atPath: workingDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Save prompt to a temporary file
        let promptFile = "\(workingDir)/.lesson-planner-prompt.md"
        try prompt.write(toFile: promptFile, atomically: true, encoding: .utf8)
        
        // Invoke goose run with the prompt text
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "goose",
            "run",
            "--text", prompt,
            "--provider", "anthropic",
            "--model", model
        ]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
        
        // Set up pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Start the process
        try process.run()
        
        // Read output in real-time
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                print(output, terminator: "")
                fflush(stdout)
            }
        }
        
        errorHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                fputs(output, stderr)
                fflush(stderr)
            }
        }
        
        // Wait for completion
        process.waitUntilExit()
        
        // Clean up handlers
        outputHandle.readabilityHandler = nil
        errorHandle.readabilityHandler = nil
        
        if process.terminationStatus != 0 {
            throw LessonPlannerError.invalidLesson("Goose invocation failed with status \(process.terminationStatus)")
        }
    }
}
