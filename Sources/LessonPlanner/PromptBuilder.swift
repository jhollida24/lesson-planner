import Foundation

struct PromptBuilder {
    static func build(
        lesson: String,
        voiceTone: String,
        repoStructure: String,
        targetRepo: String,
        branch: String
    ) throws -> String {
        let templatePath = "templates/lesson-generation-prompt.md"
        
        guard let template = try? String(contentsOfFile: templatePath, encoding: .utf8) else {
            throw LessonPlannerError.documentNotFound(templatePath)
        }
        
        // Replace placeholders
        var prompt = template
        prompt = prompt.replacingOccurrences(of: "{{lesson_content}}", with: lesson)
        prompt = prompt.replacingOccurrences(of: "{{voice_and_tone}}", with: voiceTone)
        prompt = prompt.replacingOccurrences(of: "{{repository_structure}}", with: repoStructure)
        prompt = prompt.replacingOccurrences(of: "{{target_repo}}", with: targetRepo)
        prompt = prompt.replacingOccurrences(of: "{{branch_name}}", with: branch)
        
        return prompt
    }
}
