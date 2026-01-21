---
description: Create a well-structured GitHub issue from feature requirements. Breaks down tasks and generates issue via gh CLI.
---

# Create Issue Command

Create a GitHub issue with proper structure, task breakdown, and acceptance criteria.

## What This Command Does

1. **Analyze Requirements** - Understand the feature/bug from user description
2. **Break Down Tasks** - Decompose into actionable implementation tasks
3. **Define Acceptance Criteria** - Specify when the issue is complete
4. **Create Issue** - Use `gh issue create` to create the issue
5. **Return Issue Number** - Provide issue number for next steps

## When to Use

Use `/create-issue` when:
- Starting a new feature
- Reporting a bug that needs tracking
- Planning a refactoring task
- Documenting a technical debt item
- Creating a spike/investigation task

## How It Works

The github-flow-manager agent will:

1. **Clarify requirements** if needed
2. **Generate issue body** following template:
   - 概要（Overview）
   - 背景・目的（Background & Purpose）
   - 実装タスク（Implementation Tasks）
   - 完了条件（Acceptance Criteria）
   - 技術的考慮事項（Technical Considerations）
   - 参考資料（References）

3. **Create issue** using `gh issue create`
4. **Return issue number** for use with `/start-work`

## Example Usage

```
User: /create-issue リアルタイム通知機能の追加

Agent (github-flow-manager):
# Issue Preview

## 概要
マーケット解決時にユーザーへリアルタイム通知を送信する機能

## 背景・目的
ユーザーがマーケット解決を即座に知ることができ、エンゲージメント向上につながる

## 実装タスク
- [ ] 通知データベーステーブル作成
- [ ] 通知サービス実装（lib/notifications.ts）
- [ ] Supabase リアルタイム購読設定
- [ ] NotificationBell コンポーネント作成
- [ ] 通知一覧モーダル実装
- [ ] 通知設定ページ追加
- [ ] ユニットテスト追加
- [ ] E2Eテスト追加

## 完了条件
- [ ] 全テストがパス（カバレッジ80%以上）
- [ ] マーケット解決時に通知が送信される
- [ ] ユーザーが通知設定を変更可能
- [ ] リアルタイム更新が動作する
- [ ] コードレビュー完了

## 技術的考慮事項
- Supabase Realtime の接続数制限を考慮
- 通知のバッチ処理でデータベース負荷を軽減
- 通知スパム防止のため、レート制限を実装

Creating issue...

✓ Created issue #42: "Feature: リアルタイム通知機能の追加"
  https://github.com/user/repo/issues/42

Next steps:
  /start-work 42    # Start working on this issue
```

## Issue Labels

Automatically applies appropriate labels:
- `feature` - New functionality
- `bug` - Bug fixes
- `enhancement` - Improvements to existing features
- `documentation` - Documentation updates
- `refactor` - Code refactoring
- `security` - Security-related changes
- `performance` - Performance improvements

## Issue Types

### Feature Request
```
Title: Feature: [機能名]
Labels: feature, enhancement
```

### Bug Report
```
Title: Bug: [不具合の説明]
Labels: bug
Include: Steps to reproduce, Expected vs Actual behavior
```

### Refactoring
```
Title: Refactor: [対象コンポーネント]
Labels: refactor
Include: Current issues, Target architecture
```

### Documentation
```
Title: Docs: [ドキュメント対象]
Labels: documentation
Include: What needs documentation, Target audience
```

## Integration with Workflow

After creating an issue:

```bash
# Start work immediately
/start-work 42

# Or review/plan later
gh issue list
gh issue view 42
```

## Important Notes

**Requirements**:
- `gh` CLI must be installed and authenticated
- Repository must have issues enabled
- User must have write access to repository

**Best Practices**:
- Be specific in issue title
- Include clear acceptance criteria
- Link to related issues/PRs
- Add labels for organization
- Assign to yourself if starting work immediately

## Related Commands

- `/start-work {issue_number}` - Start working on the issue
- `/plan` - Create implementation plan (called by /start-work)
- `/finish-work` - Complete work and create PR

## Related Agents

This command invokes the `github-flow-manager` agent located at:
`~/.claude/agents/github-flow-manager.md`

And references the `github-flow` skill at:
`~/.claude/skills/github-flow.md`
