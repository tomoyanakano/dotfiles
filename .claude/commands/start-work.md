---
description: Start working on a GitHub issue by creating a branch (issue-{number}), running /plan, and guiding implementation setup.
---

# Start Work Command

Start working on a GitHub issue with automated branch creation and implementation planning.

## What This Command Does

1. **Fetch Issue Details** - Get issue information from GitHub
2. **Create Branch** - Create `issue-{number}` branch from main
3. **Run Planning** - Automatically invoke `/plan` to create implementation plan
4. **Wait for Approval** - Get user confirmation on the plan
5. **Guide Implementation** - Suggest using `/tdd` for test-driven implementation

## When to Use

Use `/start-work {issue_number}` when:
- Ready to implement a GitHub issue
- Starting work on assigned issue
- Picking up an issue from backlog
- Continuing work on existing issue

## How It Works

The github-flow-manager agent will:

1. **Validate issue exists**
   ```bash
   gh issue view {issue_number}
   ```

2. **Fetch latest main**
   ```bash
   git fetch origin main
   ```

3. **Create feature branch**
   ```bash
   git checkout -b issue-{issue_number} origin/main
   ```

4. **Read issue description** and extract requirements

5. **Launch planner agent**
   - Analyzes issue requirements
   - Creates detailed implementation plan
   - Identifies risks and dependencies

6. **Wait for user approval** of the plan

7. **Guide to implementation**
   - Suggest using `/tdd` for test-first development
   - Reference relevant patterns from skills

## Example Usage

```
User: /start-work 42

Agent (github-flow-manager):
Fetching issue #42...

Issue #42: Feature: リアルタイム通知機能の追加
Status: Open
Labels: feature, enhancement
Assigned to: @you

Fetching latest from origin/main...
✓ Fetched

Creating branch issue-42...
✓ Branch created and checked out

Now analyzing requirements and creating implementation plan...

[Planner agent output follows]

# Implementation Plan: リアルタイム通知機能

## Overview
マーケット解決時にユーザーへリアルタイム通知を送信

## Requirements
- Supabase Realtime を使用したリアルタイム通知
- 通知設定ページでユーザーが通知ON/OFF可能
- NotificationBell コンポーネントでUI表示

## Implementation Phases

### Phase 1: Database Schema
1. **Create notifications table** (File: supabase/migrations/XXX_notifications.sql)
   - Action: テーブル作成（id, user_id, market_id, type, message, read_at）
   - Why: 通知データを永続化
   - Dependencies: None
   - Risk: Low

2. **Create user_notification_preferences table**
   - Action: ユーザー設定テーブル作成
   - Why: 通知のON/OFF設定を保存
   - Dependencies: None
   - Risk: Low

### Phase 2: Backend Implementation
... [Full plan continues]

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes/no/modify)

User: yes

✅ Plan approved!

Next steps:
1. Use /tdd to implement with test-driven development
2. Start with Phase 1: Database Schema
3. Run /code-review before each commit

Ready to start? Type: /tdd {first task description}
```

## Branch Naming Convention

The command enforces the `issue-{number}` naming convention:

✅ **Correct**:
- `issue-42` (for issue #42)
- `issue-123` (for issue #123)

❌ **Incorrect** (will be auto-corrected):
- `feature/notifications`
- `42-feature`
- `notifications`

## Safety Checks

### Uncommitted Changes
```
⚠️ Warning: You have uncommitted changes

Would you like to:
1. Stash changes (git stash)
2. Commit changes first
3. Cancel and review changes

Choose option: _
```

### Branch Already Exists
```
⚠️ Branch issue-42 already exists

Would you like to:
1. Switch to existing branch
2. Delete and recreate branch
3. Create new branch with suffix (issue-42-v2)
4. Cancel

Choose option: _
```

### Issue Already in Progress
```
⚠️ Issue #42 is already assigned to another developer

PR #55 is already open for this issue
  https://github.com/user/repo/pull/55

Would you like to:
1. View the PR
2. Continue anyway (collaborate)
3. Cancel

Choose option: _
```

## Integration with Planning

After branch creation, automatically runs `/plan` with:
- Issue title as feature name
- Issue description as requirements
- Implementation tasks from issue checklist
- Acceptance criteria from issue

The planner agent will:
1. Restate requirements from issue
2. Break down into detailed implementation steps
3. Identify dependencies and risks
4. Estimate complexity
5. Wait for user approval before proceeding

## Best Practices

1. **Always start from main**: Branch is created from `origin/main` to ensure latest code
2. **One issue, one branch**: Don't work on multiple issues in same branch
3. **Small, focused issues**: Break large features into multiple issues
4. **Update issue status**: Mark issue as "In Progress" when starting work

## Common Workflows

### Simple Bug Fix
```bash
/start-work 42          # Create branch, plan
yes                     # Approve plan
/tdd {task description} # Implement with TDD
/finish-work           # Review, commit, PR
```

### Complex Feature
```bash
/start-work 42          # Create branch, plan
modify: {changes}       # Request plan modifications
yes                     # Approve revised plan
/tdd {phase 1 task}    # Implement phase 1
# ... continue implementation
/finish-work           # Review, commit, PR
```

## Error Handling

- **Issue not found**: Shows available issues via `gh issue list`
- **Not in git repository**: Prompts to initialize git or cd to repo
- **Network error**: Retries GitHub API calls with backoff
- **Permission denied**: Shows authentication help for `gh` CLI

## Required Tools

- **Git**: Version control
- **GitHub CLI (`gh`)**: Issue and PR management
  ```bash
  brew install gh
  gh auth login
  ```

## Important Notes

- Branch is created from `origin/main` by default
- If you want to branch from different base, use:
  ```bash
  /start-work 42 --base develop
  ```
- Always fetch latest before creating branch
- Plan is mandatory - cannot skip planning phase

## Integration with Other Commands

```
/create-issue     → /start-work → /tdd → /finish-work
     ↓                 ↓            ↓          ↓
  Create issue    Create branch  Implement  Create PR
```

## Related Commands

- `/create-issue` - Create issue before starting work
- `/plan` - Called automatically by /start-work
- `/tdd` - Implement with test-driven development
- `/finish-work` - Complete work and create PR

## Related Agents

This command invokes the `github-flow-manager` agent located at:
`~/.claude/agents/github-flow-manager.md`
