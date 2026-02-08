# Lesson Generation Task

You are tasked with generating a complete lesson repository based on the following specification.

## Voice and Tone Guidelines

{{voice_and_tone}}

---

## Repository Structure Requirements

{{repository_structure}}

---

## Lesson Specification

{{lesson_content}}

---

## Target Repository

**Path**: `{{target_repo}}`
**Branch**: `{{branch_name}}`

---

## Your Task

Generate a complete lesson repository following these steps:

### 1. Repository Setup

- Create the repository at `{{target_repo}}` if it doesn't exist
- Initialize as a git repository
- Create and checkout branch `{{branch_name}}`

### 2. Create Initial State (Commit 1)

Follow the **Initial State** section from the lesson specification exactly. This commit must:

- Be a fully compilable project with the specified performance issues
- Include all required files and directory structure
- Build successfully with the specified build command
- Pass all tests
- Be runnable and profileable

**Critical**: The initial state must demonstrate the performance problems that will be fixed in later commits.

### 3. Add Xcode Project (Commit 2)

If the project type requires an Xcode project:
- Add the `.xcodeproj` file
- Ensure the project builds from this commit forward
- Commit with message from the **Commits** section

### 4. Apply Optimizations (Commits 3-5)

For each optimization in the **Optimizations** section:

1. Read the optimization's **Theory** and **Expected Changes**
2. Apply the changes to the specified files
3. Ensure the project still builds and tests pass
4. Commit with the message from the **Commits** section

### 5. Generate LESSON.md (Commit 6)

Create a complete `LESSON.md` file following the **Lesson Structure** section:

- Use the exact section structure specified
- Include prompts from **Prompting Examples**
- Add placeholders for reader profiling data
- Include stylized diffs showing key changes
- Use relative commit links (will be updated in next commit)

### 6. Update Documentation (Commit 7)

- Update `README.md` with build/run/profile instructions
- Update commit links in both `LESSON.md` and `README.md` with actual commit hashes
- Ensure all links are correct

---

## Validation Requirements

At each commit:

1. **Build**: Run the build command from **Validation** section
2. **Test**: Run the test command (if tests exist)
3. **Verify**: Ensure the commit achieves its stated purpose

If any validation fails, fix the issues before proceeding to the next commit.

---

## Important Notes

- Follow the **Voice and Tone Guidelines** for all prompts in LESSON.md
- Follow the **Repository Structure Requirements** for project layout
- Use the exact commit messages specified in **Commits** section
- Ensure every commit builds and runs successfully
- The initial state must be a working project with performance issues
- Each optimization must be in a separate commit
- Include detailed comments explaining the performance issues in the initial state

---

## Output

When complete, report:

- ✅ Branch created: `{{branch_name}}`
- ✅ Number of commits
- ✅ Build status at each commit
- ✅ Test status at each commit
- ✅ Any issues encountered and how they were resolved

Begin generating the lesson repository now.
