import Foundation

struct LessonLoader {
    static func load(lessonName: String) throws -> String {
        let lessonPath = "lessons/\(lessonName).md"
        
        guard FileManager.default.fileExists(atPath: lessonPath) else {
            throw LessonPlannerError.lessonNotFound(lessonName)
        }
        
        guard let content = try? String(contentsOfFile: lessonPath, encoding: .utf8) else {
            throw LessonPlannerError.invalidLesson("Could not read lesson file")
        }
        
        // Validate that the lesson has required sections
        let requiredSections = [
            "# Metadata",
            "# Inspiration",
            "# Initial State",
            "# Optimizations",
            "# Commits",
            "# Validation",
            "# Lesson Structure"
        ]
        
        for section in requiredSections {
            guard content.contains(section) else {
                throw LessonPlannerError.invalidLesson("Missing required section: \(section)")
            }
        }
        
        return content
    }
}
