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

---

# Inspiration

## Source Pull Requests

### PR #75419 (cash-ios): Reduce SavingsApplet clientRoute parsing

- **URL**: https://github.com/squareup/cash-ios/pull/75419
- **Summary**: Cached parsed routes to eliminate redundant parsing
- **Key Changes**:
  - Added Action struct to bundle feature + parsed route
  - Parse once in update, reuse for logging and permissions
  - Used Combine's `removeDuplicates()` to avoid redundant parsing

### PR #1138 (cash-client-routes): Reuse NSRegularExpression instances

- **URL**: https://github.com/squareup/cash-client-routes/pull/1138
- **Summary**: Pre-compile regex patterns instead of compiling on every parse
- **Key Changes**:
  - Changed Matcher to store NSRegularExpression instead of String
  - Updated callers to compile patterns once at initialization
  - Updated API to accept compiled regex instances
- **Profiling Data**:
  - Before: 70MB memory churn, 485ms parse time
  - After: 9MB memory churn, 58ms parse time
  - Trade-off: +1MB persistent memory

### PR #75454 (cash-ios): Bump cash-client-routes

- **URL**: https://github.com/squareup/cash-ios/pull/75454
- **Summary**: Integration PR to pull in optimized library
- **Key Changes**:
  - Bumped dependency version
  - Fixed build errors from API changes

### PR #75481 (cash-ios): Remove `isCapableOfRedacting(urlString:)`

- **URL**: https://github.com/squareup/cash-ios/pull/75481
- **Summary**: Eliminated duplicate parsing in URL redaction
- **Key Changes**:
  - Removed separate capability check method
  - Changed redact() to return Result enum
  - Collapsed two parse operations into one

## Performance Context

**Bug Report**: "Tapping the Savings applet is slow to open"

**Test Scenario**:
1. Launch Cash App
2. Navigate to Savings
3. Tap into 5 different savings goals
4. Return to main screen

**Profiling Results** (from PR #1138 comment):
- Parse time: 485ms → 58ms (-88%)
- Memory churn: 70MB → 9MB (-87%)
- Memory cost: +1MB persistent

## Key Insights

1. **Bottom-up profiling revealed repeated work**: Same expensive operation (NSRegularExpression initialization) called from multiple places
2. **Three distinct optimizations**: Cache results, pre-compile patterns, eliminate duplicate calls
3. **Trade-offs matter**: Small persistent memory cost (+1MB) for large speed gain
4. **Instruments is essential**: Top-down shows what's slow, bottom-up shows why it's called so much

---

# Demo Repository

## Purpose

The demo repository recreates the regex compilation performance issues found in the Cash App codebase in a simplified, isolated iOS app. This allows students to:

- Build and run the app easily on iOS Simulator
- Profile with Instruments (Time Profiler and Allocations)
- See the performance issues firsthand in their own measurements
- Apply the optimizations step-by-step
- Measure the improvements with their own profiling data

## Simplifications from Production

The demo differs from the production Cash App code in these ways:

1. **Simplified UI**: Single screen with buttons instead of complex navigation hierarchy
2. **Generalized Names**: 
   - `FeaturePresenter` instead of `SavingsAppletTilePresenter`
   - `Route` instead of `ClientRoute`
   - `RouteMatcher` instead of `Matcher`
3. **Focused Scope**: Only the routing and redaction components, not the full app architecture
4. **Synthetic Data**: Uses simple test routes (`/home`, `/profile`, `/feature/:id`) instead of real API routes
5. **Reduced Scale**: 5 routes instead of 50+, but demonstrates the same pattern
6. **Standalone**: No external dependencies or backend services

## What Stays the Same

The core performance issues are identical to production:

1. **Same anti-pattern**: Repeated regex compilation on every parse call
2. **Same redundancy**: Multiple parsing of the same route in different methods
3. **Same duplicate work**: Capability check + redaction both parse the same URL
4. **Same measurements**: Profiling with Instruments shows the same bottlenecks (regex init, memory churn)
5. **Same fixes**: The optimizations apply directly to production code
6. **Same trade-offs**: Pre-compiling regex trades memory for speed
7. **Same profiling techniques**: Top-down and bottom-up analysis work the same way

## Why This Approach Works

- **Reproducible**: Anyone can clone, build, and profile on their machine
- **Teachable**: Simple enough to understand quickly without domain knowledge
- **Realistic**: Performance issues match real-world problems at scale
- **Measurable**: Instruments shows clear before/after improvements
- **Applicable**: Techniques transfer directly to production codebases
- **Isolated**: No need to understand the full Cash App architecture

## How It Recreates the Problem

The demo app intentionally includes the same performance anti-patterns:

1. **FeaturePresenter** (like SavingsAppletTilePresenter):
   - Parses route in `update()` when feature changes
   - Parses again in `logTap()` for analytics
   - Parses again in `checkPermissions()` for access control
   - Same URL parsed 3 times for one user interaction

2. **RouteMatcher** (like Matcher):
   - Stores regex patterns as strings
   - Compiles NSRegularExpression on every `matches()` call
   - Compiles again on every `extract()` call
   - 5 routes × 2 methods = 10 regex compilations per parse

3. **URLRedactor** (like ClientRouteURLRedactor):
   - `isCapableOfRedacting()` parses URL to check if it matches
   - `redact()` parses the same URL again to perform redaction
   - Sequential duplicate work on the same input

These are the exact same patterns found in production, just with simpler names and fewer routes.

---

# Initial State

The project should be a fully buildable iOS app with intentional performance issues.

## Project Structure

- Xcode project: `RegexPerformance.xcodeproj`
- Swift Package Manager: `Package.swift`
- Main app files in `RegexPerformanceApp/`:
  - `RegexPerformanceApp.swift` - App entry point (@main)
  - `ContentView.swift` - Main screen with 5 route buttons
  - `FeatureDetailView.swift` - Detail screen with "Simulate Updates" button
  - `Assets.xcassets/` - App icon and assets
  - `Info.plist` - App configuration
- Library sources in `Sources/RegexPerformance/`:
  - `Routing/Route.swift` - Route model (path + parameters)
  - `Routing/RouteMatcher.swift` - **Performance issue: compiles regex on every call**
  - `Routing/RouteParser.swift` - Route parser using matchers
  - `Presentation/FeaturePresenter.swift` - **Performance issue: parses same route multiple times**
  - `Redaction/URLRedactor.swift` - **Performance issue: parses URL twice**
  - `Redaction/AggregateRedactor.swift` - Aggregates multiple redactors
- Tests in `Tests/RegexPerformanceTests/`:
  - `URLRedactorTests.swift` - Tests for redaction functionality

## Performance Issues

The initial state must demonstrate three performance problems:

### 1. Redundant Parsing in FeaturePresenter

`FeaturePresenter` parses the same route multiple times:
- Line ~25: Parses in `update()` when feature changes
- Line ~42: Parses again in `logTap()` for analytics
- Line ~58: Parses again in `checkPermissions()` for access control

**Why it's a problem**: Same expensive operation (route parsing with regex) repeated 3 times for one user interaction.

### 2. Repeated Regex Compilation in RouteMatcher

`RouteMatcher` compiles `NSRegularExpression` on every call:
- Line ~18: Compiles in `matches()` method
- Line ~30: Compiles again in `extract()` method
- Happens for every route check (5 routes × 2 methods = 10 compilations per parse)

**Why it's a problem**: NSRegularExpression compilation is expensive (parsing pattern, optimizing). Accounts for about half of total parse time.

### 3. Duplicate Parsing in URLRedactor

`URLRedactor` has two methods that both parse:
- Line ~12: `isCapableOfRedacting()` parses URL to check capability
- Line ~20: `redact()` parses the same URL again to perform redaction
- Called sequentially on the same URL

**Why it's a problem**: Same URL parsed twice in immediate succession. Unnecessary duplicate work.

## Build Requirements

- Must build successfully with: 
  ```bash
  xcodebuild -project RegexPerformance.xcodeproj \
    -scheme RegexPerformance \
    -sdk iphonesimulator \
    build
  ```
- All tests must pass: `swift test`
- Must be runnable on iOS Simulator
- Must be profileable with Instruments

## UI Behavior

- **ContentView** shows 5 buttons:
  - "Home" → route: `/home`
  - "Profile" → route: `/profile`
  - "Settings" → route: `/settings`
  - "Feature Detail" → route: `/feature/123` (demonstrates the performance issues)
  - "Help" → route: `/help`
- Tapping "Feature Detail" navigates to **FeatureDetailView**
- **FeatureDetailView** shows:
  - Feature ID and parsed route
  - "Simulate Updates" button
- Tapping "Simulate Updates" triggers 5 feature updates, each causing:
  - 3 route parses (update, log, permissions)
  - Multiple regex compilations per parse
  - Visible in Instruments profiling

## Code Comments

The initial state should include detailed comments explaining the performance issues:

```swift
// PERFORMANCE ISSUE: This compiles the regex on every call
// Should pre-compile once and reuse
guard let regex = try? NSRegularExpression(pattern: pattern) else {
    return false
}
```

These comments help students understand what's wrong before they start optimizing.

---

# Optimizations

## Optimization 1: Cache Parsed Routes

**ID**: opt-1

**Description**: Eliminate redundant parsing by caching parsed routes in FeaturePresenter

**Files Changed**:
- `Sources/RegexPerformance/Presentation/FeaturePresenter.swift`

**Theory**:
FeaturePresenter parses the same Route multiple times. Look at line 25—it parses when the feature updates. Then look at line 42—it parses again when logging. And line 58—parses again for permissions.

I want to parse once and reuse the result. Create an Action type that contains both the analytics event and the parsed Route.

**Expected Changes**:
- Add `Action` struct with `feature` and `route` fields
- Parse route once in `update()` method
- Store in `currentAction` property (marked `@Published` for SwiftUI)
- Reuse in `logTap()` and `checkPermissions()` methods
- Ensure FeaturePresenter conforms to `ObservableObject`

**Why it works**:
- Eliminates 2 out of 3 route parses per user interaction
- Reduces regex compilations by ~67%
- No memory trade-off (Action is small)

---

## Optimization 2: Pre-compile Regex Patterns

**ID**: opt-2

**Description**: Store NSRegularExpression instances instead of strings

**Files Changed**:
- `Sources/RegexPerformance/Routing/RouteMatcher.swift`
- `Sources/RegexPerformance/Routing/RouteParser.swift`

**Theory**:
RouteMatcher stores regex patterns as strings. Look at line 18—it compiles the regex on every call to matches(). Profiling shows this accounts for about half of the total parse time.

I want to pre-compile the patterns once at initialization. Store NSRegularExpression instances instead of strings.

**Expected Changes**:
- Change `RouteMatcher.pattern` from `String` to `NSRegularExpression`
- Update `RouteMatcher.init` to accept `NSRegularExpression`
- Remove regex compilation from `matches()` and `extract()` methods
- Update `RouteParser.init` to compile patterns once using `try? NSRegularExpression(pattern:)`
- Handle compilation errors with `compactMap` to filter invalid patterns

**Why it works**:
- Eliminates repeated compilation (most expensive operation)
- NSRegularExpression is thread-safe for matching
- Trade-off: ~1MB persistent memory for 5 compiled patterns
- Massive speed gain for small memory cost

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

I want to remove isCapableOfRedacting and have redact() return an enum indicating success, not-applicable, or error. AggregateRedactor would try each redactor until one succeeds.

**Expected Changes**:
- Add `RedactionResult` enum with cases: `.redacted(String)`, `.notApplicable`
- Remove `isCapableOfRedacting` method from protocol
- Change `redact()` return type from `String` to `RedactionResult`
- Update `ClientRouteURLRedactor.redact()` to return `.redacted()` or `.notApplicable`
- Update `AggregateRedactor.redact()` to try each redactor and return first success
- Update tests to check `RedactionResult` cases instead of boolean + string

**Why it works**:
- Eliminates one full parse per redaction
- Simpler API (one method instead of two)
- No trade-offs (pure improvement)

---

# Commits

## Commit 1: Initial State
**ID**: initial
**Message**: Add initial project with performance issues
**Description**: Create fully buildable iOS app with intentional performance problems. See "Initial State" section for complete requirements. Include detailed comments explaining each performance issue.

## Commit 2: Xcode Project
**ID**: xcode-project
**Message**: Add Xcode project for iOS app
**Description**: Add Xcode project so the app can be built and profiled from the start. This commit should come immediately after the initial state so every commit in the history can be built in Xcode.

## Commit 3: Optimization 1
**ID**: opt-1
**Message**: Reuse parsed routes in FeaturePresenter
**Optimization**: opt-1
**Description**: Eliminate redundant parsing by caching the parsed route in an Action struct and reusing it for logging and permission checks.

## Commit 4: Optimization 2
**ID**: opt-2
**Message**: Pre-compile regex patterns in RouteMatcher
**Optimization**: opt-2
**Description**: Store NSRegularExpression instances instead of strings to eliminate repeated compilation overhead. Trade ~1MB persistent memory for significant speed gain.

## Commit 5: Optimization 3
**ID**: opt-3
**Message**: Eliminate duplicate parsing in URLRedactor
**Optimization**: opt-3
**Description**: Remove isCapableOfRedacting method and have redact() return a Result enum, collapsing two parse operations into one.

## Commit 6: Lesson Documentation
**ID**: lesson
**Message**: Add performance optimization guide
**Description**: Add LESSON.md with complete tutorial following the structure in "Lesson Structure" section. Include all sections, prompts, placeholders, and stylized diffs.

## Commit 7: Update Documentation
**ID**: docs
**Message**: Update documentation with commit links
**Description**: Update README and LESSON.md with correct commit hashes from the actual commits. Ensure all links work and point to the correct branch.

---

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
- `Sources/RegexPerformance/` (directory with subdirectories)
- `Tests/RegexPerformanceTests/` (directory)
- `RegexPerformanceApp/` (directory)

## Validation Requirements
- Every commit must build successfully (exit code 0)
- All tests must pass at every commit (exit code 0)
- App must be runnable on iOS Simulator
- App must be profileable with Instruments (Time Profiler and Allocations)
- No compilation errors (warnings are acceptable)

---

# Lesson Structure

## Section 1: Introduction (300-400 words)

- Present the bug report: "Tapping the Feature Detail button is slow"
- Explain this is a real issue from Cash App (generalized for teaching)
- Set expectations: systematic approach using measurement, analysis, and LLM-assisted implementation
- No "what you'll learn" section
- Mention the repository is available for hands-on practice

## Section 2: Phase 1 - Measure the Problem (500-600 words)

- Explain the importance of establishing a baseline
- Describe the test scenario:
  ```
  1. Launch the app
  2. Tap "Feature Detail" button
  3. Tap "Simulate Updates" button (triggers 5 updates)
  4. Observe the performance
  ```
- Show how to profile with Instruments:
  - In Xcode: Product → Profile (Cmd+I)
  - Choose "Time Profiler"
  - Run the test scenario
  - Stop recording
  - **Save the trace file** (critical for comparison)
- Also profile with Allocations instrument
- Include placeholder for reader's measurements:
  ```markdown
  > **[Profile the app and record your baseline numbers here]**
  > - Total parse time: ___ ms
  > - Time in regex initialization: ___ ms
  > - Main thread blocked: ___ ms
  > - Memory churned: ___ MB
  ```

## Section 3: Phase 2 - Analyze the Profile (900-1100 words)

### Top-Down View
- Explain how to read the call tree
- Look for main thread time
- Drill down from high-level operations to low-level work
- Use "self time" to find where actual work happens
- Show the pattern: UI update → route parsing → regex compilation

### Bottom-Up View
- Explain why bottom-up matters
- Switch view in Instruments
- Focus on expensive operation (NSRegularExpression.init)
- Expand to see all call sites
- Key insight: Same expensive operation called from multiple places

### Forming Theories
- Theory 1: FeaturePresenter parses same route multiple times (from bottom-up view)
- Theory 2: RouteMatcher compiles regex on every parse (from self time)
- Theory 3: URLRedactor parses URL twice sequentially (from call stack)
- Human does this analysis, not LLM
- Use relative measurements: "about half the time", "most of the allocations"

## Section 4: Lesson 1 - Reading Performance Profiles (400-500 words)

- Teach the two views and their purposes:
  - **Top-Down**: Understand call hierarchy, follow expensive paths
  - **Bottom-Up**: Find repeated work, identify optimization opportunities
- When to use each view
- How to spot patterns (repeated calls, high self time, memory churn)
- No "why this works" opinions—just demonstrate the technique

## Section 5: Phase 3 - Optimization #1 (800-1000 words)

- State the theory from Optimization 1
- Show the prompt:
  ```
  FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
  parses the same Route multiple times. Look at line 25—it parses when the 
  feature updates. Then look at line 42—it parses again when logging. And 
  line 58—parses again for permissions.
  
  I want to parse once and reuse the result. Create an Action type that 
  contains both the analytics event and the parsed Route.
  
  Show me your plan for refactoring this.
  ```
- Show LLM's plan (example):
  ```
  1. Create Action struct with feature and route fields
  2. Add currentAction property to FeaturePresenter
  3. Parse route once in update() and store in currentAction
  4. Reuse currentAction.route in logTap() and checkPermissions()
  ```
- Say: "Go ahead and execute the plan."
- Human reviews the diff (don't ask LLM to review)
- Show stylized diff:
  ```diff
   class FeaturePresenter: ObservableObject {
  +    struct Action {
  +        let feature: Feature
  +        let route: Route?
  +    }
  +    
  +    @Published var currentAction: Action?
  +    
       func update(feature: Feature) {
  -        let route = parser.parse(feature.url)
  +        currentAction = Action(
  +            feature: feature,
  +            route: parser.parse(feature.url)
  +        )
       }
       
       func logTap() {
  -        let route = parser.parse(currentFeature.url)
  +        guard let route = currentAction?.route else { return }
           analytics.log(event: .tap, route: route)
       }
  ```
- Link to commit: `[See the full changes in commit 3](../../commit/HASH)`
- Include placeholder:
  ```markdown
  > **[Profile again and record the improvement]**
  > - Total parse time: ___ ms (was ___ ms)
  > - Reduction: ___%
  ```

## Section 6: Phase 4 - Optimization #2 (800-1000 words)

- Same pattern as Optimization #1
- State theory from Optimization 2
- Show prompt (let LLM validate thread-safety and memory cost in its plan)
- Show LLM's plan
- "Go ahead and execute the plan."
- Human reviews diff
- Show stylized diff for both RouteMatcher and RouteParser
- Link to commit
- Include placeholder for measurements

## Section 7: Phase 5 - Optimization #3 (700-900 words)

- Same pattern
- State theory from Optimization 3
- Show prompt
- Show LLM's plan
- "Go ahead and execute the plan."
- Human reviews diff
- Show stylized diff for URLRedactor, AggregateRedactor, and tests
- Link to commit
- Include placeholder for final measurements

## Section 8: Lesson 2 - Working with LLMs (500-600 words)

- Demonstrate the pattern (no "why this works" opinions):
  1. State theory with file paths in monospace
  2. Point to specific lines
  3. Ask "Show me your plan"
  4. Review the plan
  5. Say "Go ahead and execute the plan"
  6. Review the diff yourself
  7. Commit or provide feedback
- Show example prompts from the optimizations
- Emphasize division of labor:
  - Human: analyzes, reasons, decides, verifies
  - LLM: implements, generates, validates assumptions
- Use relative measurements in prompts
- Keep prompts terse and natural

## Section 9: Phase 6 - Measuring Results (700-900 words)

- Run the same test scenario
- Profile with Instruments again
- Compare before/after traces
- Show improvements table:
  ```markdown
  | Metric | Before | After | Change |
  |--------|--------|-------|--------|
  | Parse time | 485ms | 58ms | -88% |
  | Regex init | 245ms | ~0ms | -100% |
  | Memory churn | 70MB | 9MB | -87% |
  | Persistent memory | baseline | +1MB | +1MB |
  ```
- Note: These are example numbers from Cash App; reader's will differ
- Include placeholder:
  ```markdown
  > **[Your profiling results]**
  > - Parse time: ___ ms → ___ ms (___% reduction)
  > - Memory churn: ___ MB → ___ MB (___% reduction)
  > - Memory cost: +___ MB persistent
  ```
- Analyze which optimization had the biggest impact (optimization #2)
- Reference final state in commit

## Section 10: Conclusion (300-400 words)

- Summary of achievements:
  - Three focused optimizations
  - Significant performance improvements
  - Clear before/after measurements
- The process:
  1. Measure with Instruments
  2. Analyze profiles yourself
  3. Form theories
  4. Work with LLM: theory → plan → execute → review
  5. Verify with measurement
- Why it matters:
  - Straightforward changes
  - Big user-facing impact
  - Applicable to many codebases
- Encourage readers:
  ```markdown
  Try it yourself:
  1. Clone the repository
  2. Profile the initial state
  3. Walk through each optimization
  4. Measure your own improvements
  ```
- The LLM is a coding assistant, not a performance analyst
- You do the thinking, it does the typing

---

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

After reviewing the plan:
```
Go ahead and execute the plan.
```

If clarification needed:
```
Make sure FeaturePresenter conforms to ObservableObject and currentAction 
is marked @Published so SwiftUI views can observe changes.
```

## Optimization 2 Prompt

```
RouteMatcher (`Sources/RegexPerformance/Routing/RouteMatcher.swift`) stores 
regex patterns as strings. Look at line 18—it compiles the regex on every 
call to matches(). Profiling shows this accounts for about half of the 
total parse time.

I want to pre-compile the patterns once at initialization. Store 
NSRegularExpression instances instead of strings.

Show me your plan for refactoring this.
```

After reviewing the plan:
```
Go ahead and execute the plan.
```

## Optimization 3 Prompt

```
URLRedactor (`Sources/RegexPerformance/Redaction/URLRedactor.swift`) parses 
each URL twice. Look at line 12—isCapableOfRedacting parses the URL. Then 
look at line 20—redact parses it again.

I want to remove isCapableOfRedacting and have redact() return an enum 
indicating success, not-applicable, or error. AggregateRedactor would try 
each redactor until one succeeds.

Show me your plan for refactoring this.
```

After reviewing the plan:
```
Go ahead and execute the plan.
```
