---
description: Complete work on current issue by running code review, committing changes, pushing to remote, and creating a PR that closes the issue.
---

# Finish Work Command

Complete work on the current issue with automated review, commit, push, and PR creation.

## What This Command Does

1. **Verify Branch** - Ensure you're on `issue-{number}` branch
2. **Run Code Review** - Automatically invoke `/code-review`
3. **Fix Critical Issues** - Block if CRITICAL/HIGH issues found
4. **Create Commit** - Add and commit changes with conventional commit message
5. **Push to Remote** - Push branch to origin with `-u` flag
6. **Create PR** - Use `gh pr create` with issue reference
7. **Display PR URL** - Show PR link and next steps

## When to Use

Use `/finish-work` when:
- Implementation is complete
- Tests are passing
- Ready to submit for review
- All acceptance criteria met
- Issue tasks completed

## How It Works

The github-flow-manager agent will:

1. **Check current branch**
   ```bash
   git branch --show-current
   # Must be issue-{number} format
   ```

2. **Check for uncommitted changes**
   ```bash
   git status
   ```

3. **Run code review**
   - Invokes `/code-review` agent
   - Analyzes security, quality, performance
   - Reports CRITICAL/HIGH/MEDIUM issues

4. **Block if issues found**
   - CRITICAL or HIGH issues → Must fix before PR
   - MEDIUM issues → Warning, can proceed with confirmation

5. **Generate commit message**
   - Analyzes changes with `git diff`
   - Follows conventional commits format
   - Includes Co-Authored-By: Claude

6. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add real-time notifications

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

7. **Push to remote**
   ```bash
   git push -u origin issue-42
   ```

8. **Create PR**
   ```bash
   gh pr create --title "..." --body "..."
   ```

9. **Display results**
   - PR URL
   - GitHub Actions status
   - Next steps (request reviewers, etc.)

## Example Usage

```
User: /finish-work

Agent (github-flow-manager):
Current branch: issue-42 ✓

Checking for uncommitted changes...
Found changes in:
  - src/lib/notifications.ts
  - src/components/NotificationBell.tsx
  - src/app/api/notifications/route.ts
  - tests/notifications.test.ts

Running code review...

[Code Review Results]

✅ SECURITY: No issues found
✅ QUALITY: No critical issues
⚠️  MEDIUM: Found 2 suggestions
  - src/lib/notifications.ts:45 - Consider adding error boundary
  - src/components/NotificationBell.tsx:20 - Memoize callback

Proceed with PR creation? (yes/no): yes

Analyzing git diff for commit message...

Proposed commit message:
  feat: add real-time notification system

  - Implement Supabase Realtime subscriptions
  - Add NotificationBell component
  - Create notification preferences page
  - Add unit and E2E tests

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

Approve commit message? (yes/edit): yes

Committing changes...
✓ Changes committed

Pushing to origin...
✓ Pushed to origin/issue-42

Creating pull request...

Proposed PR:
  Title: "feat: Add real-time notification system (#42)"

  Body:
  ## 概要
  マーケット解決時にユーザーへリアルタイム通知を送信する機能を実装

  Closes #42

  ## 変更内容
  - Supabase Realtime を使用した通知システム実装
  - NotificationBell コンポーネント追加
  - 通知設定ページ追加
  - ユニットテストとE2Eテスト追加

  ## テスト計画
  - [x] ユニットテストが全てパス
  - [x] E2Eテストが全てパス
  - [x] カバレッジ80%以上を確認
  - [ ] 手動テスト完了（レビュアー確認待ち）

  ## レビューポイント
  - Supabase Realtime の接続管理
  - 通知のレート制限実装

  🤖 Generated with Claude Code

Create PR? (yes/edit): yes

✓ Pull request created!
  https://github.com/user/repo/pull/55

GitHub Actions: Running...
  https://github.com/user/repo/actions/runs/12345

Next steps:
  1. Request reviewers: gh pr edit 55 --add-reviewer @teammate
  2. Monitor CI/CD: gh pr checks 55
  3. Address review comments if any
  4. Merge when approved: gh pr merge 55

Issue #42 will auto-close when PR is merged.
```

## Commit Message Format

Follows [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>

<optional body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

Types:
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation
- `test:` - Test additions
- `chore:` - Maintenance
- `perf:` - Performance improvement
- `ci:` - CI/CD changes

## PR Title Format

```
<type>: <description> (#<issue_number>)
```

Examples:
- `feat: Add real-time notifications (#42)`
- `fix: Resolve authentication bug (#123)`
- `refactor: Improve market search performance (#87)`

## Code Review Blocking

### CRITICAL Issues (PR Blocked)
```
❌ CRITICAL ISSUES FOUND

Cannot create PR until these are fixed:

[CRITICAL] Hardcoded API key
File: src/api/client.ts:42
Issue: API key exposed in source code
Fix: Move to environment variable

[CRITICAL] SQL Injection vulnerability
File: src/lib/db.ts:28
Issue: User input concatenated into SQL query
Fix: Use parameterized queries

Please fix these issues and run /finish-work again.
```

### HIGH Issues (PR Blocked)
```
❌ HIGH PRIORITY ISSUES FOUND

[HIGH] Missing error handling
File: src/lib/notifications.ts:15
Issue: Async function has no try/catch
Fix: Add comprehensive error handling

Fix these before creating PR? (yes/cancel): _
```

### MEDIUM Issues (Warning)
```
⚠️  MEDIUM PRIORITY ISSUES FOUND

[MEDIUM] Missing memoization
File: src/components/NotificationBell.tsx:20
Issue: Callback not memoized, may cause re-renders
Fix: Wrap with useCallback

[MEDIUM] Large function
File: src/lib/notifications.ts:45
Issue: Function is 65 lines (>50 line limit)
Fix: Extract helper functions

Continue with PR creation? (yes/no): _
```

## PR Template

Auto-generated PR body includes:

```markdown
## 概要
{変更内容の簡潔な説明}

Closes #{issue番号}

## 変更内容
- {変更点1}
- {変更点2}
- {変更点3}

## テスト計画
- [ ] ユニットテストが全てパス
- [ ] E2Eテストが全てパス
- [ ] カバレッジ80%以上を確認
- [ ] 手動テスト完了

## レビューポイント
{特に注意してレビューしてほしい箇所}

## スクリーンショット
{UIの変更がある場合}

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Safety Checks

### Not on Feature Branch
```
⚠️  Warning: Not on issue-{number} branch

Current branch: main

You should be on a feature branch. Create one with:
  /start-work {issue_number}
```

### No Changes to Commit
```
⚠️  No uncommitted changes found

Either:
1. All changes already committed
2. No changes made since last commit

View commit history: git log
Create PR for existing commits? (yes/no): _
```

### Tests Failing
```
❌ Tests are failing

npm test output:
  FAIL src/lib/notifications.test.ts
    ✕ sends notification on market resolution (23ms)

Fix tests before creating PR? (yes/force): _

Warning: Using 'force' will create PR with failing tests
```

## Integration with Hooks

Respects hooks configured in `~/.claude/settings.json`:

### PreToolUse Hooks
- **git push review**: Opens editor for review before push
- **doc blocker**: Warns if unnecessary .md files created

### PostToolUse Hooks
- **PR creation**: Logs PR URL and GitHub Actions status
- **console.log warning**: Final check for console.log statements

### Stop Hooks
- **console.log audit**: Scans all modified files before session end

## Branch Protection

If branch protection is enabled:

```
⚠️  Branch protection active

Required checks:
  - Status checks must pass
  - At least 1 approval required
  - No force push allowed

PR created: https://github.com/user/repo/pull/55

Waiting for:
  ⏳ CI/CD to pass
  👤 Reviewer approval

Monitor status: gh pr checks 55
```

## Best Practices

1. **Run tests before /finish-work**
   ```bash
   npm test
   npm run build
   ```

2. **Review your changes**
   ```bash
   git diff main
   git log origin/main..HEAD
   ```

3. **Update documentation** if needed

4. **Add screenshots** for UI changes

5. **Self-review** before requesting team review

## Common Workflows

### Happy Path
```bash
# Implementation complete
npm test              # Verify tests pass
/finish-work         # Review, commit, PR
# → Review code
# → Approve commit message
# → Approve PR
# → Done!
```

### With Issues Found
```bash
/finish-work
# → Code review finds CRITICAL issues
# → Fix issues
/finish-work
# → Code review passes
# → PR created
```

### Multiple Commits
```bash
git add src/lib/notifications.ts
git commit -m "feat: add notification service"

git add src/components/NotificationBell.tsx
git commit -m "feat: add notification UI component"

/finish-work
# → Will push all commits and create PR
```

## Error Handling

- **No issue branch**: Warns and suggests creating one
- **Uncommitted changes**: Prompts to review or commit
- **Tests failing**: Blocks PR creation
- **Push fails**: Shows error, suggests `git pull --rebase`
- **PR creation fails**: Shows error, suggests manual creation via `gh`

## Required Tools

- **Git**: Version control
- **GitHub CLI (`gh`)**: PR management
- **npm/pnpm**: Test runner (optional, for test verification)

## Important Notes

- **No force push**: Uses `git push -u` (never `--force`)
- **No skip hooks**: Respects `--no-verify` setting in global config
- **Always link issues**: PR body includes "Closes #X"
- **Automatic attribution**: Adds Co-Authored-By: Claude

## Related Commands

- `/start-work {issue_number}` - Start working on issue
- `/code-review` - Called automatically by /finish-work
- `/tdd` - Used during implementation
- `/create-issue` - Create issue before starting work

## Related Agents

This command invokes the `github-flow-manager` agent located at:
`~/.claude/agents/github-flow-manager.md`

And may invoke:
- `code-reviewer` agent (via `/code-review`)
- `security-reviewer` agent (for security checks)
