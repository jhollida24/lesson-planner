# Voice and Tone Guidelines

These guidelines define how to write prompts and lesson content that effectively teaches developers to work with LLMs for performance optimization.

---

## Writing Perspective

All lesson content is written from the perspective of **the author** (the person who discovered and fixed the performance issue).

- Use first person: "I found", "I measured", "I optimized"
- Share the discovery process: "When I looked at the profile..."
- Explain reasoning: "I formed a theory that..."
- Be honest about trade-offs: "This costs 1MB of memory but..."

**Example:**
```markdown
When I looked at the bottom-up profile, I noticed the same expensive 
operation being called from multiple places. This suggested that caching 
the result could eliminate redundant work.
```

---

## Tone for Prompts

Prompts to the LLM should be **terse, natural, and focused**.

### Key Principles

1. **Terse**: Get to the point quickly. No unnecessary words.
2. **Natural**: Write like you're talking to a colleague, not filling out a form.
3. **Specific**: Point to exact files and line numbers.
4. **Theory-first**: Explain your reasoning before asking for code.

### What to Avoid

❌ **Structured templates** like:
```
Problem: [description]
Reasoning: [analysis]
Task: [what to do]
Requirements:
- Requirement 1
- Requirement 2
```

❌ **Verbose explanations**:
```
I have identified a performance issue in the codebase where the 
FeaturePresenter class is parsing the same route multiple times 
across different methods, which is causing unnecessary overhead...
```

❌ **Asking the LLM to analyze**:
```
Can you analyze this code and tell me what's wrong?
```

### What to Do

✅ **Natural language with file paths and line numbers**:
```
FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 25—it parses when the 
feature updates. Then look at line 42—it parses again when logging. And 
line 58—parses again for permissions.

I want to parse once and reuse the result. Create an Action type that 
contains both the analytics event and the parsed Route.

Show me your plan for refactoring this.
```

✅ **Relative measurements instead of exact numbers**:
```
Profiling shows this accounts for about half of the total parse time.
```

Not:
```
Profiling shows this accounts for 245ms of the 485ms total parse time.
```

✅ **File paths in monospace**:
```
Look at `RouteMatcher.swift` line 18—it compiles the regex on every call.
```

---

## Describing Theories and Reasoning

When explaining your theory about an optimization:

1. **State what you observed** (from profiling or code inspection)
2. **Explain why it's a problem** (performance impact)
3. **Propose a solution** (what to change)
4. **Mention trade-offs** (if applicable)

**Example:**
```
RouteMatcher stores regex patterns as strings. Look at line 18—it compiles 
the regex on every call to matches(). Profiling shows this accounts for 
about half of the total parse time.

I want to pre-compile the patterns once at initialization. Store 
NSRegularExpression instances instead of strings. This will trade a small 
amount of persistent memory for eliminating the compilation overhead.
```

---

## The Plan-First Approach

Always ask the LLM to show its plan before implementing:

1. **State your theory** (as above)
2. **Ask for a plan**: "Show me your plan for refactoring this."
3. **Review the plan** (human does this)
4. **Approve execution**: "Go ahead and execute the plan."
5. **Review the result** (human examines the diff)

**Never skip the plan step.** It catches misunderstandings early.

---

## Human vs LLM Responsibilities

### Human (You) Does:

- **Measure** performance with Instruments
- **Analyze** profiles (top-down and bottom-up views)
- **Form theories** about what's slow and why
- **Reason** through optimization approaches
- **Decide** on trade-offs
- **Review** generated code
- **Verify** improvements through measurement

### LLM Does:

- **Implement** refactorings based on your theories
- **Generate** boilerplate code
- **Update** tests to match API changes
- **Review** code for common issues (when asked)
- **Validate** assumptions like thread-safety (in its plan)

### LLM Does NOT Do:

- Analyze performance profiles
- Form optimization theories
- Make architectural decisions
- Measure actual performance
- Decide on trade-offs

---

## Example Prompts

### Good Prompt (Optimization 1)

```
FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 25—it parses when the 
feature updates. Then look at line 42—it parses again when logging. And 
line 58—parses again for permissions.

I want to parse once and reuse the result. Create an Action type that 
contains both the analytics event and the parsed Route.

Show me your plan for refactoring this.
```

**Why it's good:**
- Points to specific file and lines
- Explains the problem concisely
- States the desired solution
- Asks for a plan first

### Good Prompt (Optimization 2)

```
RouteMatcher (`Sources/RegexPerformance/Routing/RouteMatcher.swift`) stores 
regex patterns as strings. Look at line 18—it compiles the regex on every 
call to matches(). Profiling shows this accounts for about half of the 
total parse time.

I want to pre-compile the patterns once at initialization. Store 
NSRegularExpression instances instead of strings.

Show me your plan for refactoring this.
```

**Why it's good:**
- Uses relative measurement ("about half")
- Explains the optimization clearly
- Lets LLM validate thread-safety and memory cost in its plan

### Bad Prompt

```
Problem: The FeaturePresenter class has a performance issue.

Reasoning: It is parsing routes multiple times which is inefficient.

Task: Refactor the code to be more efficient.

Requirements:
- Parse routes only once
- Cache the results
- Maintain existing functionality
- Ensure thread safety

Please implement this optimization.
```

**Why it's bad:**
- Structured template format
- No specific file paths or line numbers
- Doesn't ask for a plan first
- Too formal and verbose
- Asks LLM to implement without review

---

## Reviewing Generated Code

When the LLM generates code:

1. **Examine the diff yourself** - Don't ask the LLM to review its own work
2. **Check for correctness** - Does it match your theory?
3. **Verify completeness** - Are all necessary changes included?
4. **Look for issues** - Thread safety, memory leaks, edge cases
5. **Provide feedback** - If issues found, tell the LLM specifically what to fix

**Example feedback:**
```
The Action struct needs to be created atomically with the feature update. 
Don't use combineLatest with separate publishers—that can cause the action 
to be out of sync with the feature.
```

---

## Writing Lesson Content

When writing the lesson (LESSON.md):

### Do:

- Write from first person ("I measured", "I found")
- Use conversational tone
- Explain your reasoning process
- Show the actual prompts you used
- Include placeholders for reader's own measurements
- Use relative measurements in explanations
- Point to specific lines when discussing code

### Don't:

- Use "we" or "you" excessively
- Write in passive voice
- Include "what you'll learn" sections
- Add "why this works" opinions
- Make it sound like a textbook
- Assume the reader has the same profiling numbers

### Placeholders for Measurements

Always include placeholders where readers should collect their own data:

```markdown
> **[Profile the app and record your baseline numbers here]**
> - Total parse time: ___ ms
> - Time in regex initialization: ___ ms
> - Main thread blocked: ___ ms
```

This acknowledges that their numbers will differ from yours.

---

## Summary

**Voice**: First person, conversational, sharing your discovery process

**Prompts**: Terse, natural, specific (file paths + line numbers), theory-first, plan-first

**Responsibilities**: Human analyzes and decides, LLM implements and generates

**Reviews**: Human examines diffs, provides specific feedback

**Lesson Content**: Conversational, reasoning-focused, with measurement placeholders
