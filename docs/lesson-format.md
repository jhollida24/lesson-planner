# Lesson Input Format

A lesson is defined in a single Markdown file with structured sections using specific headers.

## File Location

Lessons are stored in the `lessons/` directory with the `.md` extension.

Example: `lessons/regex-performance.md`

---

## Required Sections

### `# Metadata`

Basic information about the lesson.

**Format:**
```markdown
# Metadata

- **Name**: regex-performance
- **Title**: Debugging Performance with LLMs: Regex Optimization
- **Description**: A systematic approach to identifying and fixing regex compilation performance issues
- **Author**: Jeff Holliday
- **Date**: 2025-01-16
- **Project Type**: ios-app
- **Platform**: ios
- **Min Version**: 17.0
- **Build System**: xcode
```

**Fields:**
- `Name`: Unique identifier (used for directory names)
- `Title`: Human-readable title for the lesson
- `Description`: Brief description of what the lesson teaches
- `Author`: Lesson author name
- `Date`: Creation date
- `Project Type`: Type of project (ios-app, macos-cli, swift-package, etc.)
- `Platform`: Target platform (ios, macos, etc.)
- `Min Version`: Minimum platform version
- `Build System`: Build system to use (xcode, spm, etc.)

---

### `# Inspiration`

Context about the source material that inspired the lesson.

**Format:**
```markdown
# Inspiration

## Source Pull Requests

### PR #75419 (cash-ios): Reduce SavingsApplet clientRoute parsing
- **URL**: https://github.com/squareup/cash-ios/pull/75419
- **Summary**: Cached parsed routes to eliminate redundant parsing
- **Key Changes**:
  - Added Action struct to bundle feature + parsed route
  - Parse once in update, reuse for logging and permissions

[... more PRs ...]

## Performance Context

**Bug Report**: "Tapping the Savings applet is slow to open"

**Test Scenario**:
1. Launch Cash App
2. Navigate to Savings
3. Tap into 5 different savings goals
4. Return to main screen

**Profiling Results**:
- Parse time: 485ms → 58ms (-88%)
- Memory churn: 70MB → 9MB (-87%)
- Memory cost: +1MB persistent

## Key Insights

1. **Bottom-up profiling revealed repeated work**: Same expensive operation called from multiple places
2. **Three distinct optimizations**: Cache results, pre-compile patterns, eliminate duplicate calls
3. **Trade-offs matter**: Small persistent memory cost for large speed gain
```

**Purpose**: Provides context about the real-world problem being solved and the source PRs that inspired the lesson.

---

### `# Demo Repository`

Description of how the lesson repository recreates the problem in a simpler, isolated environment.

**Format:**
```markdown
# Demo Repository

## Purpose

The demo repository recreates the regex compilation performance issues found in the Cash App codebase in a simplified, isolated iOS app. This allows students to:

- Build and run the app easily
- Profile with Instruments
- See the performance issues firsthand
- Apply the optimizations step-by-step
- Measure the improvements

## Simplifications from Production

The demo differs from the production Cash App code in these ways:

1. **Simplified UI**: Single screen with buttons instead of complex navigation
2. **Generalized Names**: `FeaturePresenter` instead of `SavingsAppletTilePresenter`
3. **Focused Scope**: Only the routing and redaction components, not the full app
4. **Synthetic Data**: Uses simple test routes instead of real API data
5. **Reduced Scale**: 5 routes instead of 50+, but demonstrates the same pattern

## What Stays the Same

The core performance issues are identical to production:

1. **Same anti-pattern**: Repeated regex compilation on every parse
2. **Same redundancy**: Multiple parsing of the same route
3. **Same duplicate work**: Capability check + redaction parse the same URL
4. **Same measurements**: Profiling with Instruments shows the same bottlenecks
5. **Same fixes**: The optimizations apply directly to production code

## Why This Approach Works

- **Reproducible**: Anyone can clone, build, and profile
- **Teachable**: Simple enough to understand quickly
- **Realistic**: Performance issues match real-world problems
- **Measurable**: Instruments shows clear before/after improvements
- **Applicable**: Techniques transfer directly to production code
```

**Purpose**: Explains how the demo repository relates to the real-world inspiration and why the simplifications are appropriate for teaching.

---

### `# Initial State`

Description of what the project should look like before any optimizations.

**Format:**
```markdown
# Initial State

The project should be a fully buildable iOS app with intentional performance issues.

## Project Structure

- Xcode project: `RegexPerformance.xcodeproj`
- Swift Package Manager: `Package.swift`
- Main app files:
  - `RegexPerformanceApp/RegexPerformanceApp.swift` - App entry point
  - `RegexPerformanceApp/ContentView.swift` - Main screen with route buttons
  - `RegexPerformanceApp/FeatureDetailView.swift` - Detail screen
- Library sources in `Sources/RegexPerformance/`:
  - `Routing/Route.swift` - Route model
  - `Routing/RouteMatcher.swift` - **Performance issue: compiles regex on every call**
  - `Routing/RouteParser.swift` - Route parser
  - `Presentation/FeaturePresenter.swift` - **Performance issue: parses same route multiple times**
  - `Redaction/URLRedactor.swift` - **Performance issue: parses URL twice**
  - `Redaction/AggregateRedactor.swift` - Aggregates redactors
- Tests in `Tests/RegexPerformanceTests/`:
  - `URLRedactorTests.swift` - Tests for redaction

## Performance Issues

The initial state must demonstrate three performance problems:

1. **Redundant Parsing**: `FeaturePresenter` parses the same route in `update()`, `logTap()`, and `checkPermissions()`
2. **Repeated Regex Compilation**: `RouteMatcher` compiles `NSRegularExpression` on every `matches()` and `extract()` call
3. **Duplicate Parsing**: `URLRedactor` has separate `isCapableOfRedacting()` and `redact()` methods that both parse the URL

## Build Requirements

- Must build successfully with: `xcodebuild -project RegexPerformance.xcodeproj -scheme RegexPerformance -sdk iphonesimulator build`
- All tests must pass: `swift test`
- Must be runnable on iOS Simulator

## UI Behavior

- ContentView shows 5 buttons: Home, Profile, Settings, Feature Detail, Help
- Tapping "Feature Detail" navigates to FeatureDetailView
- FeatureDetailView has "Simulate Updates" button that triggers the performance issues
```

**Purpose**: Defines exactly what the first commit should contain - a working project with performance problems.

---

### `# Optimizations`

Ordered list of optimizations to apply.

**Format:**
```markdown
# Optimizations

## Optimization 1: Cache Parsed Routes

**ID**: opt-1

**Description**: Eliminate redundant parsing by caching parsed routes in FeaturePresenter

**Files Changed**:
- `Sources/RegexPerformance/Presentation/FeaturePresenter.swift`

**Theory**:
FeaturePresenter parses the same Route multiple times. Look at line 25—it parses when the feature updates. Then look at line 42—it parses again when logging. And line 58—parses again for permissions.

Parse once and reuse the result. Create an Action type that contains both the analytics event and the parsed Route.

**Expected Changes**:
- Add `Action` struct with `feature` and `route` fields
- Parse route once in `update()` method
- Store in `currentAction` property
- Reuse in `logTap()` and `checkPermissions()`

---

## Optimization 2: Pre-compile Regex Patterns

**ID**: opt-2

**Description**: Store NSRegularExpression instances instead of strings

**Files Changed**:
- `Sources/RegexPerformance/Routing/RouteMatcher.swift`
- `Sources/RegexPerformance/Routing/RouteParser.swift`

**Theory**:
RouteMatcher stores regex patterns as strings. Look at line 18—it compiles the regex on every call to matches(). Profiling shows this accounts for about half of the total parse time.

Pre-compile the patterns once at initialization. Store NSRegularExpression instances instead of strings.

**Expected Changes**:
- Change `RouteMatcher.pattern` from `String` to `NSRegularExpression`
- Update `RouteMatcher.init` to accept `NSRegularExpression`
- Remove regex compilation from `matches()` and `extract()`
- Update `RouteParser.init` to compile patterns once

---

## Optimization 3: Eliminate Duplicate Parsing

**ID**: opt-3

**Description**: Collapse capability check into redact method

**Files Changed**:
- `Sources/RegexPerformance/Redaction/URLRedactor.swift`
- `Sources/RegexPerformance/Redaction/AggregateRedactor.swift`
- `Tests/RegexPerformanceTests/URLRedactorTests.swift`

**Theory**:
URLRedactor parses each URL twice. Look at line 12—isCapableOfRedacting parses the URL. Then look at line 20—redact parses it again.

Remove isCapableOfRedacting and have redact() return an enum indicating success, not-applicable, or error. AggregateRedactor would try each redactor until one succeeds.

**Expected Changes**:
- Add `RedactionResult` enum: `.redacted(String)`, `.notApplicable`
- Remove `isCapableOfRedacting` method
- Change `redact()` return type to `RedactionResult`
- Update `AggregateRedactor` to try each redactor
- Update tests to use new API
```

**Purpose**: Defines each optimization step with theory, expected changes, and files affected.

---

### `# Commits`

Ordered list of commits to create.

**Format:**
```markdown
# Commits

## Commit 1: Initial State
**ID**: initial
**Message**: Add initial project with performance issues
**Description**: Create fully buildable iOS app with intentional performance problems. See "Initial State" section for complete requirements.

## Commit 2: Xcode Project
**ID**: xcode-project
**Message**: Add Xcode project for iOS app
**Description**: Add Xcode project so the app can be built and profiled from the start. This commit should come immediately after the initial state.

## Commit 3: Optimization 1
**ID**: opt-1
**Message**: Reuse parsed routes in FeaturePresenter
**Optimization**: opt-1

## Commit 4: Optimization 2
**ID**: opt-2
**Message**: Pre-compile regex patterns in RouteMatcher
**Optimization**: opt-2

## Commit 5: Optimization 3
**ID**: opt-3
**Message**: Eliminate duplicate parsing in URLRedactor
**Optimization**: opt-3

## Commit 6: Lesson Documentation
**ID**: lesson
**Message**: Add performance optimization guide
**Description**: Add LESSON.md with complete tutorial following the structure in "Lesson Structure" section

## Commit 7: Update Documentation
**ID**: docs
**Message**: Update documentation with commit links
**Description**: Update README and LESSON with correct commit hashes from the actual commits
```

**Purpose**: Defines the exact commit sequence and messages.

---

### `# Validation`

How to validate each commit.

**Format:**
```markdown
# Validation

## Build Command
```bash
xcodebuild -project RegexPerformance.xcodeproj \
  -scheme RegexPerformance \
  -sdk iphonesimulator \
  build
```

## Test Command
```bash
swift test
```

## Required Files
- `RegexPerformance.xcodeproj/project.pbxproj`
- `README.md`
- `Package.swift`
- `Sources/RegexPerformance/` (directory)
- `Tests/RegexPerformanceTests/` (directory)

## Validation Requirements
- Every commit must build successfully
- All tests must pass at every commit
- App must be runnable on iOS Simulator
- App must be profileable with Instruments
```

**Purpose**: Defines how to validate that each commit is correct.

---

### `# Lesson Structure`

Outline of the lesson content to generate in LESSON.md.

**Format:**
```markdown
# Lesson Structure

## Section 1: Introduction (300-400 words)
- Present the bug report: "Tapping the Feature Detail button is slow"
- Set expectations for systematic approach
- No "what you'll learn" section

## Section 2: Phase 1 - Measure the Problem (500-600 words)
- Establish baseline with Instruments
- Test scenario: Launch app, tap Feature Detail button 5 times
- Save trace files for comparison
- **Placeholder**: Reader collects profiling data

[... more sections ...]
```

**Purpose**: Defines the structure and content of LESSON.md.

---

### `# Prompting Examples`

Example prompts to include in the lesson.

**Format:**
```markdown
# Prompting Examples

## Optimization 1 Prompt

```
FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 25—it parses when the 
feature updates. Then look at line 42—it parses again when logging. And 
line 58—parses again for permissions.

I want to parse once and reuse the result. Create an Action type that 
contains both the analytics event and the parsed Route.

Show me your plan for refactoring this.
```

[... more prompts ...]
```

**Purpose**: Provides exact prompts to include in LESSON.md.

---

## Element Types Summary

1. **Metadata**: Basic lesson information
2. **Inspiration**: Source material and context from real PRs
3. **Demo Repository**: How the lesson repo recreates the problem in a simpler environment
4. **Initial State**: What the first commit should contain
5. **Optimizations**: Ordered list of optimization steps
6. **Commits**: Exact commit sequence
7. **Validation**: How to validate each commit
8. **Lesson Structure**: Outline of LESSON.md content
9. **Prompting Examples**: Example prompts for the lesson

All elements are in a single Markdown file with clearly marked sections.
