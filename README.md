# Lesson Planner

A tool for generating lesson repositories from lesson specifications.

## Overview

Lesson Planner takes a lesson specification (a single Markdown file) and generates a complete lesson repository with:

- Working code demonstrating performance issues
- Step-by-step optimizations in separate commits
- Complete tutorial documentation (LESSON.md)
- Build and profiling instructions

## Installation

```bash
cd lesson-planner
swift build
```

The executable will be at:
- `.build/arm64-apple-macosx/debug/lesson-planner` (Apple Silicon)
- `.build/x86_64-apple-macosx/debug/lesson-planner` (Intel Mac)

For release builds:
```bash
swift build -c release
```

The release executable will be at:
- `.build/arm64-apple-macosx/release/lesson-planner` (Apple Silicon)
- `.build/x86_64-apple-macosx/release/lesson-planner` (Intel Mac)

## Usage

**Important**: Run these commands from the `lesson-planner` repository directory, not from the generated lesson repository.

### Generate a Lesson Repository

```bash
# Navigate to lesson-planner directory
cd /path/to/lesson-planner

# Using the built executable (Apple Silicon)
.build/arm64-apple-macosx/debug/lesson-planner generate \
  --lesson regex-performance \
  --target-repo ~/Development/demo-repos/regex-perf \
  --branch lesson-20250116-143022

# Or use swift run (slower, rebuilds if needed)
swift run lesson-planner generate \
  --lesson regex-performance \
  --target-repo ~/Development/demo-repos/regex-perf \
  --branch lesson-20250116-143022
```

### With Options

```bash
.build/arm64-apple-macosx/debug/lesson-planner generate \
  --lesson regex-performance \
  --target-repo ~/Development/demo-repos/regex-perf \
  --branch lesson-$(date +%Y%m%d-%H%M%S) \
  --model goose-claude-4-5-sonnet \
  --push-to-origin \
  --validate-prompts
```

### Arguments

- `--lesson`: Name of lesson file in `lessons/` (without .md extension)
- `--target-repo`: Path to target repository (will be created if doesn't exist)
- `--branch`: Branch name (default: `lesson-YYYYMMDD-HHMMSS`)
- `--model`: Goose model to use (default: `goose-claude-4-5-sonnet`)
- `--push-to-origin`: Push branch to origin after generation
- `--validate-prompts`: Run prompt validation cycle with subagents

## How It Works

1. **Loads the lesson specification** from `lessons/<name>.md`
2. **Loads documentation** from `docs/` (voice-and-tone.md, repository-structure.md)
3. **Builds a prompt** for Goose using the template in `templates/`
4. **Invokes Goose** with the prompt to generate the repository
5. **Validates** (optional) that prompts produce expected results
6. **Pushes** (optional) the branch to origin

## Lesson Format

Lessons are defined in a single Markdown file with structured sections. See `docs/lesson-format.md` for the complete specification.

### Required Sections

1. **Metadata**: Basic information (name, title, author, etc.)
2. **Inspiration**: Source PRs and context
3. **Demo Repository**: How the demo recreates the problem
4. **Initial State**: What the first commit should contain
5. **Optimizations**: Ordered list of optimization steps
6. **Commits**: Exact commit sequence
7. **Validation**: How to validate each commit
8. **Lesson Structure**: Outline of LESSON.md content
9. **Prompting Examples**: Example prompts for the lesson

## Documentation

- **`docs/lesson-format.md`**: Complete specification of lesson input format
- **`docs/voice-and-tone.md`**: Guidelines for writing prompts and lesson content
- **`docs/repository-structure.md`**: How lesson repositories should be structured and validated

## Example Lesson

See `lessons/regex-performance.md` for a complete example lesson that teaches performance optimization using LLMs.

## Development

### Build

```bash
swift build
```

### Run

```bash
swift run lesson-planner generate --lesson regex-performance --target-repo /tmp/test-repo
```

### Test

```bash
swift test
```

## Requirements

- Swift 5.9+
- macOS 13+
- Goose CLI installed and available in PATH

## License

MIT
