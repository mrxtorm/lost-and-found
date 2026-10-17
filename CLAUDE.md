# CLAUDE.md — Existing Mobile App Development Rules

## 1. Project Context
This is an existing, ongoing Lost and Found Flutter mobile application. Development is already in progress.

Your responsibility is to continue development using the current codebase, existing architecture, implemented features, and established project conventions.

**Do not treat this project as a new application.**

## 2. Before Making Changes
- Inspect the relevant files before modifying anything.
- Understand how the existing feature works and which files depend on it.
- Check existing models, services, repositories, providers, screens, and database structures before creating new ones.
- Identify the root cause of a problem before attempting a fix.
- If the request is unclear or may affect existing behavior, ask for clarification first.

## 3. Preserve Existing Functionality
- Do not remove, replace, or break working features.
- Do not rewrite entire files when targeted changes are sufficient.
- Do not restructure folders or rename files without a clear need.
- Do not change existing UI designs, navigation, database fields, or workflows unless required by the task.
- Avoid unrelated improvements while implementing a requested feature.
- Preserve existing user data and backward compatibility whenever possible.

## 4. Implementation Rules
- Follow the existing Flutter and Dart coding style.
- Reuse existing components, functions, models, and services.
- Avoid duplicate code and unnecessary dependencies.
- Keep changes consistent with the current architecture.
- Implement complete functionality, including loading states, error handling, and relevant edge cases.
- Do not use mock data or temporary workarounds as a substitute for real functionality unless requested.

## 5. Firebase and Data Integrity
- Preserve the existing Firebase Authentication and Firestore integration.
- Follow the current database structure unless a migration is necessary.
- Never weaken Firestore security rules to bypass errors.
- Protect user information and validate permissions for sensitive operations.
- Handle related database records consistently.
- Never delete posts, claims, conversations, messages, or other user data unless the requested workflow explicitly requires it.
- Before changing a database structure, explain the impact and migration requirements.

## 6. Bug Fixing
When fixing a bug:
1. Reproduce or trace the issue where possible.
2. Identify the root cause.
3. Inspect related code and dependencies.
4. Make the smallest complete fix.
5. Check for regressions and related errors.
6. Explain the cause and the changes made.

Do not introduce a second implementation to work around the first without understanding why the original failed.

## 7. Testing and Verification
- Run `flutter analyze` after relevant code changes when possible.
- Run applicable tests.
- Check affected workflows and related features.
- Verify imports, types, null safety, and database operations.
- Never claim that something works unless the available checks support that conclusion.
- Clearly report any tests that were not run or issues that remain.

## 8. Development Workflow
For each requested task:
1. Understand the request.
2. Inspect the existing implementation.
3. Identify the files that need modification.
4. Make focused changes.
5. Verify the implementation.
6. Summarize the changes and testing results.

For larger tasks, provide a short plan before implementation.

## 9. Git and File Safety
- Never discard or overwrite unrelated user changes.
- Do not reset, revert, or delete existing work without explicit permission.
- Avoid destructive terminal commands.
- Do not commit or push changes unless requested.
- Preserve existing project configuration and dependencies.

## 10. Communication
- Explain technical issues in clear, simple language.
- List modified files and explain why each was changed.
- Mention important side effects, limitations, and required manual steps.
- If the requested approach risks breaking existing functionality, explain the risk and propose a safer alternative.

## Final Priority
Maintain the stability of the existing application while implementing the requested changes. Make only necessary changes, preserve working functionality, and verify your work before declaring a task complete.