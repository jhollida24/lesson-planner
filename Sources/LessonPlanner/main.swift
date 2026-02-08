import ArgumentParser
import Foundation

struct LessonPlanner: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lesson-planner",
        abstract: "Generate lesson repositories from lesson specifications",
        subcommands: [Generate.self]
    )
}

struct Generate: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate a lesson repository"
    )
    
    @Option(name: .long, help: "Name of lesson file in lessons/ (without .md extension)")
    var lesson: String
    
    @Option(name: .long, help: "Path to target repository (will be created if doesn't exist)")
    var targetRepo: String
    
    @Option(name: .long, help: "Branch name (default: lesson-YYYYMMDD-HHMMSS)")
    var branch: String?
    
    @Option(name: .long, help: "Goose model to use")
    var model: String = "goose-claude-4-5-sonnet"
    
    @Flag(name: .long, help: "Push branch to origin after generation")
    var pushToOrigin: Bool = false
    
    @Flag(name: .long, help: "Run prompt validation cycle with subagents")
    var validatePrompts: Bool = false
    
    func run() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let branchName = branch ?? "lesson-\(dateFormatter.string(from: Date()))"
        
        print("🚀 Generating lesson: \(lesson)")
        print("📁 Target repository: \(targetRepo)")
        print("🌿 Branch: \(branchName)")
        print("🤖 Model: \(model)")
        print()
        
        // Load lesson
        print("📖 Loading lesson specification...")
        let lessonContent = try LessonLoader.load(lessonName: lesson)
        
        // Load docs
        print("📚 Loading documentation...")
        let voiceTone = try loadDoc(name: "voice-and-tone")
        let repoStructure = try loadDoc(name: "repository-structure")
        
        // Build prompt
        print("✍️  Building prompt for Goose...")
        let prompt = try PromptBuilder.build(
            lesson: lessonContent,
            voiceTone: voiceTone,
            repoStructure: repoStructure,
            targetRepo: targetRepo,
            branch: branchName
        )
        
        // Save prompt for inspection
        let promptPath = "/tmp/lesson-planner-prompt.md"
        try prompt.write(toFile: promptPath, atomically: true, encoding: .utf8)
        print("💾 Prompt saved to: \(promptPath)")
        print()
        
        // Invoke Goose
        print("🦆 Invoking Goose...")
        try GooseInvoker.invoke(
            prompt: prompt,
            model: model,
            workingDir: targetRepo
        )
        
        // Push to origin if requested
        if pushToOrigin {
            print()
            print("📤 Pushing branch to origin...")
            try GitManager.push(
                repoPath: targetRepo,
                branch: branchName
            )
        }
        
        print()
        print("✅ Lesson generation complete!")
        print("📁 Repository: \(targetRepo)")
        print("🌿 Branch: \(branchName)")
    }
    
    private func loadDoc(name: String) throws -> String {
        let docPath = "docs/\(name).md"
        guard let content = try? String(contentsOfFile: docPath, encoding: .utf8) else {
            throw LessonPlannerError.documentNotFound(docPath)
        }
        return content
    }
}

enum LessonPlannerError: LocalizedError {
    case documentNotFound(String)
    case lessonNotFound(String)
    case invalidLesson(String)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound(let path):
            return "Document not found: \(path)"
        case .lessonNotFound(let name):
            return "Lesson not found: lessons/\(name).md"
        case .invalidLesson(let message):
            return "Invalid lesson format: \(message)"
        }
    }
}

// Entry point
LessonPlanner.main()
