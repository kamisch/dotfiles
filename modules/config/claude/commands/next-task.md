Read the backlog file at `plans/prd.json` and the progress history at `plans/progress.txt`.

Analyze the backlog and recent history. Determine the most logical next task based on:
- Dependencies between tasks (check the `context` field)
- What has already been completed (`passes: true`)
- Logical ordering (foundational tasks before dependent ones)

Implement that task completely using clean engineering practice and concise code. Use plans/progress.txt as a checkpoint notepad for anything you think will be worth noting down for other people to read, example bugs fixed, pattern, pitalls. After you have successfully implemented and verified the task:
1. Self-review: run pre-commit on changed files, run relevant tests, and check the diff for bugs before committing, make sure no bugs are introduced and feature implemented as defined by the task. 
2. Create unit tests to cover the changes. Keep the unit tests concise, do not write bloated and flaky tests. 
3. Stage and Commit the changes after test passes. If there are lint errors or precommit errors fix those before proceeding.
1. Update `plans/prd.json` to set `"passes": true` for the completed task.
2. Output the following line EXACTLY:
    COMPLETED_TASK_ID: <task-id>
    (IMPORTANT: Replace `<task-id>` with the actual ID string from the backlog, e.g., `task-32` or `task-35`. Do NOT use placeholders.)
