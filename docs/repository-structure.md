# Repository Structure and Validation

This document defines how lesson repositories should be structured, how to validate each commit, and how to perform the prompt iteration cycle.

---

## Repository Structure

Every lesson repository should follow this structure:

```
lesson-repo/
├── README.md                          # Build, run, and profile instructions
├── LESSON.md                          # Complete tutorial
├── Package.swift                      # Swift Package Manager support
├── ProjectName.xcodeproj/             # Xcode project (for iOS/macOS apps)
│   └── project.pbxproj
├── ProjectNameApp/                    # App-specific files (if applicable)
│   ├── AppName.swift                  # App entry point
│   ├── ContentView.swift              # Main UI
│   ├── Assets.xcassets/               # Assets
│   └── Info.plist
├── Sources/
│   └── ProjectName/                   # Library code
│       ├── Component1/
│       │   ├── File1.swift
│       │   └── File2.swift
│       └── Component2/
│           └── File3.swift
└── Tests/
    └── ProjectNameTests/
        └── TestFile.swift
```

### Key Principles

1. **Dual Build System**: Support both Xcode and Swift Package Manager
2. **Clear Separation**: App files separate from library code
3. **Organized by Component**: Group related files together
4. **Testable**: Include tests that validate functionality

---

## Commit Structure

Every lesson repository should have commits in this order:

### 1. Initial State Commit

**Purpose**: Create a fully working project with performance issues

**Requirements**:
- Must compile successfully
- Must run on simulator/device
- Must demonstrate the performance problems
- Must include detailed comments explaining the issues
- Must pass all tests

**Contents**:
- Complete project structure
- All source files with performance issues
- Tests
- README with basic build instructions
- Package.swift and/or .xcodeproj

**Example commit message**:
```
Add initial project with performance issues

This project demonstrates three performance problems:
1. Redundant parsing in FeaturePresenter
2. Repeated regex compilation in RouteMatcher
3. Duplicate parsing in URLRedactor
```

### 2. Xcode Project Commit (if applicable)

**Purpose**: Add Xcode project so the app can be built from the start

**Requirements**:
- Must come immediately after initial state
- Must build successfully
- Must not change any source code

**Example commit message**:
```
Add Xcode project for iOS app
```

### 3-N. Optimization Commits

**Purpose**: Apply one optimization per commit

**Requirements**:
- Must compile successfully
- Must pass all tests
- Must only change files related to this optimization
- Must include clear commit message

**Example commit message**:
```
Reuse parsed routes in FeaturePresenter

Eliminate redundant parsing by caching the parsed route
in an Action struct and reusing it for logging and
permission checks.
```

### N+1. Lesson Documentation Commit

**Purpose**: Add complete LESSON.md tutorial

**Requirements**:
- Must follow the lesson structure specification
- Must include all required sections
- Must use placeholder commit links (will be updated in next commit)

**Example commit message**:
```
Add performance optimization guide
```

### N+2. Update Documentation Commit

**Purpose**: Update README and LESSON.md with correct commit hashes

**Requirements**:
- Update all commit links with actual hashes
- Verify all links work
- Ensure README has complete build/run/profile instructions

**Example commit message**:
```
Update documentation with commit links
```

---

## Validation at Each Commit

Every commit must pass these validation steps:

### 1. Build Validation

Run the build command specified in the lesson's Validation section.

**For Xcode projects**:
```bash
xcodebuild -project ProjectName.xcodeproj \
  -scheme ProjectName \
  -sdk iphonesimulator \
  build
```

**For SPM projects**:
```bash
swift build
```

**Success criteria**:
- Exit code 0
- No compilation errors
- Warnings are acceptable

### 2. Test Validation

Run the test command if tests exist.

```bash
swift test
```

**Success criteria**:
- Exit code 0
- All tests pass
- No test failures

### 3. Functional Validation

Verify the commit achieves its stated purpose:

**Initial state**:
- App runs
- Performance issues are present
- UI works as expected

**Optimization commits**:
- Optimization is applied correctly
- App still runs
- No regressions

**Documentation commits**:
- Files are created
- Links are correct
- Content is complete

---

## Prompt Iteration Cycle

For each optimization prompt in the lesson, validate that it produces the expected result.

### Process

1. **Extract the prompt** from the lesson specification
2. **Generate a plan** using a subagent
3. **Compare** the plan to the actual implementation
4. **Add clarifications** if needed
5. **Re-validate** up to 2 more times
6. **Document** the final prompt in LESSON.md

### Step 1: Extract the Prompt

From the lesson's "Prompting Examples" section, get the exact prompt for this optimization.

Example:
```
FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 25—it parses when the 
feature updates. Then look at line 42—it parses again when logging. And 
line 58—parses again for permissions.

I want to parse once and reuse the result. Create an Action type that 
contains both the analytics event and the parsed Route.

Show me your plan for refactoring this.
```

### Step 2: Generate a Plan with Subagent

Use a subagent to generate the LLM's expected response to the prompt.

**Subagent prompt**:
```
You are validating a prompt for a performance optimization tutorial.

Given this prompt:
[paste the prompt]

Generate a concise plan (max 20 lines) for how you would implement this 
refactoring. Focus on the key steps and decisions.
```

**Example subagent response**:
```
Plan:
1. Create Action struct with feature and route fields
2. Add currentAction property to FeaturePresenter
3. In update() method:
   - Parse the route once
   - Store in currentAction
4. In logTap() method:
   - Use currentAction.route instead of parsing
5. In checkPermissions() method:
   - Use currentAction.route instead of parsing
6. Ensure Action is created atomically with feature update
```

### Step 3: Compare to Actual Implementation

Look at the actual commit that implements this optimization.

**Check**:
- Does the plan match what was actually implemented?
- Are the key steps present?
- Are there important details the plan missed?

**Example comparison**:
- ✅ Action struct created
- ✅ currentAction property added
- ✅ Route parsed once in update()
- ✅ Reused in logTap() and checkPermissions()
- ⚠️ Plan doesn't mention using ObservableObject (needed for SwiftUI)

### Step 4: Add Clarifications (if needed)

If the plan doesn't match the implementation, add clarifying instructions.

**Guidelines for clarifications**:
- Use the same terse, natural tone as the original prompt
- Point to specific issues
- Don't be overly prescriptive
- Focus on what the plan missed

**Example clarification**:
```
Make sure FeaturePresenter conforms to ObservableObject and currentAction 
is marked @Published so SwiftUI views can observe changes.
```

### Step 5: Re-validate

Generate a new plan with the clarifications included.

**Updated prompt**:
```
[original prompt]

Make sure FeaturePresenter conforms to ObservableObject and currentAction 
is marked @Published so SwiftUI views can observe changes.

Show me your plan for refactoring this.
```

**New subagent response**:
```
Plan:
1. Make FeaturePresenter conform to ObservableObject
2. Create Action struct with feature and route fields
3. Add @Published currentAction property
4. In update() method:
   - Parse the route once
   - Store in currentAction
5. In logTap() method:
   - Use currentAction.route instead of parsing
6. In checkPermissions() method:
   - Use currentAction.route instead of parsing
```

**Check again**:
- ✅ Now includes ObservableObject
- ✅ Now includes @Published
- ✅ All key steps present

### Step 6: Document Final Prompt

Include the final prompt (with clarifications) in LESSON.md.

**Maximum iterations**: 3 total
- Initial attempt
- First clarification + re-validation
- Second clarification + re-validation (if needed)

**After 3 iterations**: The prompt should be good enough. If not, there may be an issue with the implementation or the prompt needs major revision.

---

## Testing the Repository

After generating the complete repository, perform these checks:

### 1. Clone Test

```bash
git clone <repo-url>
cd <repo-name>
```

Verify the repository clones successfully.

### 2. Build Test (Each Commit)

```bash
# Check out each commit
for commit in $(git log --reverse --format=%H); do
  git checkout $commit
  # Run build command
  xcodebuild -project ... build || echo "FAILED: $commit"
done
```

Verify every commit builds.

### 3. Test Suite

```bash
swift test
```

Verify tests pass at every commit.

### 4. Run Test

Build and run the app on simulator.

Verify:
- App launches
- UI works
- Performance issues are present in initial state
- Performance improves after optimizations

### 5. Profile Test

Use Instruments to profile the app.

Verify:
- Initial state shows performance issues
- Optimized state shows improvements
- Profiling instructions in README work

### 6. Documentation Test

Read through LESSON.md.

Verify:
- All sections are present
- Commit links work
- Code examples are correct
- Placeholders are clearly marked

---

## Common Issues and Solutions

### Issue: Commit doesn't build

**Cause**: Missing files, syntax errors, incorrect dependencies

**Solution**:
1. Check error message
2. Fix the issue
3. Amend the commit
4. Re-validate

### Issue: Tests fail

**Cause**: API changes not reflected in tests, logic errors

**Solution**:
1. Update tests to match new API
2. Fix logic errors
3. Amend the commit
4. Re-validate

### Issue: Prompt doesn't produce expected result

**Cause**: Prompt is ambiguous, missing context, or unclear

**Solution**:
1. Add clarifying instructions
2. Re-validate with subagent
3. Repeat up to 2 more times
4. If still failing, revise the implementation or prompt

### Issue: Commit links are broken

**Cause**: Commit hashes changed (rebase, amend)

**Solution**:
1. Get new commit hashes: `git log --oneline`
2. Update LESSON.md and README.md
3. Commit the updates

---

## Summary

**Structure**: Dual build system, clear separation, organized by component

**Commits**: Initial state → Xcode project → Optimizations → Lesson → Update docs

**Validation**: Build, test, and functional checks at every commit

**Prompt Iteration**: Extract → Generate plan → Compare → Clarify → Re-validate (max 3 times)

**Testing**: Clone, build all commits, run tests, profile, verify documentation
