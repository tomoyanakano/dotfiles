---
name: github-flow
description: GitHub Flow best practices, issue templates, PR templates, and workflow automation for efficient development.
---

# GitHub Flow Best Practices

Complete guide to GitHub Flow workflow for fast, iterative development.

## Core Principles

1. **Main is always deployable** - Never push broken code to main
2. **Branch from main** - Always create feature branches from latest main
3. **Small, focused PRs** - Keep changes reviewable (<400 lines)
4. **Fast feedback loops** - Review and merge quickly
5. **Automated testing** - CI/CD runs on every PR

## Workflow Overview

```
┌─────────────┐
│   Issue     │  Feature request, bug report, task
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Branch    │  issue-{number} format
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Implement  │  TDD: Test → Code → Refactor
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Review    │  Code review, security scan
└──────┬──────┘
       │
       ▼
┌─────────────┐
│     PR      │  Pull request with issue reference
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Merge    │  Auto-close issue, deploy
└─────────────┘
```

## Issue Templates

### Feature Request

```markdown
---
name: Feature Request
about: Propose a new feature
labels: feature, enhancement
---

## 概要
{機能の簡潔な説明（1-2文）}

## 背景・目的
{なぜこの機能が必要か}

**ユーザーストーリー**:
As a {ユーザータイプ},
I want to {実現したいこと},
So that {得られる価値}

## 提案する実装

### UI/UX
{画面イメージ、ワイヤーフレーム、既存実装への追加内容}

### 技術的アプローチ
{使用する技術、ライブラリ、アーキテクチャ}

## 実装タスク
- [ ] データベーススキーマ設計・実装
- [ ] バックエンドAPI実装
  - [ ] エンドポイント作成
  - [ ] バリデーション追加
  - [ ] エラーハンドリング
- [ ] フロントエンド実装
  - [ ] コンポーネント作成
  - [ ] 状態管理
  - [ ] UIフィードバック
- [ ] テスト追加
  - [ ] ユニットテスト
  - [ ] 統合テスト
  - [ ] E2Eテスト
- [ ] ドキュメント更新

## 完了条件
- [ ] 全ユニットテストがパス
- [ ] E2Eテストがパス
- [ ] カバレッジ80%以上
- [ ] コードレビュー承認
- [ ] セキュリティチェック完了
- [ ] ドキュメント更新完了
- [ ] 手動QA完了

## 技術的考慮事項

### パフォーマンス
{パフォーマンスへの影響、最適化の必要性}

### セキュリティ
{セキュリティリスク、対策}

### スケーラビリティ
{将来的な拡張性、制限事項}

### 依存関係
{新しいライブラリ、既存コードへの影響}

## 代替案
{検討した他のアプローチとその理由}

## 参考資料
- 関連Issue: #X
- 参考PR: #Y
- 外部ドキュメント: [URL]
- デザイン: [Figma/Sketch URL]

## 見積もり
**複雑度**: Low / Medium / High
**予想工数**: X-Y 時間

## ブロッカー
{この作業を始める前に必要な前提条件}
```

### Bug Report

```markdown
---
name: Bug Report
about: Report a bug
labels: bug
---

## 🐛 バグ概要
{バグの簡潔な説明}

## 📋 再現手順
1. {ステップ1}
2. {ステップ2}
3. {ステップ3}

## 🎯 期待する動作
{本来どうあるべきか}

## 🔍 実際の動作
{現在何が起きているか}

## 📸 スクリーンショット
{該当する場合、スクリーンショットを添付}

## 🌍 環境
- OS: {macOS 14.2, Windows 11, etc.}
- Browser: {Chrome 120, Safari 17, etc.}
- Version: {アプリのバージョン}
- Device: {Desktop, Mobile, etc.}

## 📊 影響範囲
**重要度**: Critical / High / Medium / Low
**影響ユーザー数**: {推定}

## 🔬 調査結果
{エラーログ、コンソール出力、スタックトレース}

```
{エラーメッセージ}
```

## 💡 原因の仮説
{わかっている範囲で原因の推測}

## 🛠️ 修正案
{可能であれば修正方針}

## 🔗 関連情報
- 関連Issue: #X
- 類似バグ: #Y
- Sentry/ログURL: [URL]
```

### Refactoring Task

```markdown
---
name: Refactoring
about: Code improvement without feature changes
labels: refactor, technical-debt
---

## 🔧 リファクタリング対象
{対象ファイル、コンポーネント、モジュール}

## 📝 現状の問題
- {問題点1}
- {問題点2}
- {問題点3}

## 🎯 目標
{リファクタリングで達成したいこと}

## 📋 タスク
- [ ] {タスク1}
- [ ] {タスク2}
- [ ] {タスク3}

## ✅ 完了条件
- [ ] 既存のテストが全てパス
- [ ] 機能に影響がないことを確認
- [ ] パフォーマンスが悪化していない
- [ ] コードレビュー完了

## ⚠️ リスク
{リファクタリングのリスクと軽減策}

## 🔗 参考資料
{リファクタリングパターン、記事、ドキュメント}
```

## PR Templates

### Standard PR Template

```markdown
## 📝 概要
{変更内容の簡潔な説明（2-3文）}

Closes #{issue番号}

## 🔄 変更内容
- {変更点1}
- {変更点2}
- {変更点3}

## 🎯 変更の種類
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🎨 Style update (formatting, renaming)
- [ ] ♻️ Code refactoring
- [ ] ⚡ Performance improvement
- [ ] ✅ Test update

## 🧪 テスト計画
- [ ] ユニットテストが全てパス
- [ ] 統合テストが全てパス
- [ ] E2Eテストが全てパス
- [ ] カバレッジ80%以上を確認
- [ ] 手動テスト完了

### 手動テストシナリオ
1. {テストステップ1}
2. {テストステップ2}
3. {期待される結果}

## 📸 スクリーンショット（該当する場合）

### Before
{変更前のスクリーンショット}

### After
{変更後のスクリーンショット}

## 👀 レビューポイント
{特に注意してレビューしてほしい箇所}
- {ポイント1}
- {ポイント2}

## 📦 デプロイメモ
{環境変数の追加、マイグレーション実行など、デプロイ時の注意事項}

- [ ] 環境変数の追加: {KEY_NAME}
- [ ] データベースマイグレーション実行が必要
- [ ] 依存関係の更新: `npm install`
- [ ] 特別な設定変更: {説明}

## ✅ チェックリスト
- [ ] コードは自己文書化されている
- [ ] 適切なエラーハンドリングを実装
- [ ] セキュリティチェック完了
- [ ] パフォーマンス影響を確認
- [ ] アクセシビリティを考慮
- [ ] モバイル対応を確認（該当する場合）
- [ ] ドキュメントを更新
- [ ] CHANGELOG.md を更新（該当する場合）

## 🔗 関連リンク
- Issue: #{issue番号}
- Design: {Figma/Sketch URL}
- Documentation: {URL}
- Related PRs: #{PR番号}

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Branch Naming Conventions

### Required Format: `issue-{number}`

```bash
# ✅ Correct
git checkout -b issue-42
git checkout -b issue-123

# ❌ Incorrect
git checkout -b feature/notifications
git checkout -b fix-bug
git checkout -b 42-add-feature
git checkout -b notifications
```

### Why This Format?

1. **Automatic linking**: Easy to trace branch to issue
2. **Consistent**: No ambiguity in naming
3. **Sortable**: Branches sort numerically
4. **Searchable**: `git branch | grep issue-42`
5. **CI/CD friendly**: Easy to extract issue number

## Commit Message Guidelines

### Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation only
- `test`: Test additions or changes
- `chore`: Maintenance tasks
- `perf`: Performance improvement
- `ci`: CI/CD changes
- `style`: Formatting, missing semicolons, etc.
- `revert`: Revert previous commit

### Examples

```bash
# Good commit messages
feat: add user notification system

fix: resolve authentication timeout on slow connections

refactor: extract common validation logic into utils

docs: update API documentation for v2 endpoints

test: add E2E tests for checkout flow

# With body
feat: add real-time notification system

Implemented Supabase Realtime subscriptions for market updates.
Users can now receive notifications when markets they watch resolve.

Closes #42

# Multiple paragraphs
refactor: improve market search performance

Replaced linear search with binary search for sorted arrays.
Reduced time complexity from O(n) to O(log n).

Added benchmarks to verify improvement:
- Before: 150ms for 10k items
- After: 12ms for 10k items

Closes #87
```

### Bad Examples

```bash
# ❌ Too vague
fix: bug fix
update: changes

# ❌ No type
Added notification feature

# ❌ Multiple concerns in one commit
feat: add notifications and fix bug and update docs
```

## PR Review Checklist

### For Authors

Before requesting review:

- [ ] **Tests pass locally**: Run `npm test` and verify all tests pass
- [ ] **Linter passes**: Run `npm run lint` with no errors
- [ ] **Build succeeds**: Run `npm run build` successfully
- [ ] **Self-review**: Review your own diff on GitHub
- [ ] **Remove debug code**: No `console.log`, commented code, TODO without ticket
- [ ] **Update documentation**: README, API docs, inline comments
- [ ] **Add tests**: For new features and bug fixes
- [ ] **Check coverage**: Maintain 80%+ test coverage
- [ ] **Small PR**: <400 lines changed (if possible)
- [ ] **Descriptive title**: Follows format `<type>: <description> (#issue)`
- [ ] **Complete description**: Fill out PR template completely
- [ ] **Link issue**: Include "Closes #X" in description

### For Reviewers

When reviewing PRs:

- [ ] **Understand context**: Read linked issue and PR description
- [ ] **Check tests**: Verify tests cover new code and edge cases
- [ ] **Security**: Look for vulnerabilities (XSS, SQL injection, secrets)
- [ ] **Performance**: Check for inefficient algorithms, N+1 queries
- [ ] **Readability**: Code is clear and well-documented
- [ ] **Architecture**: Follows project patterns and conventions
- [ ] **Edge cases**: Handles errors, null values, empty states
- [ ] **Breaking changes**: Assess impact on existing functionality
- [ ] **Documentation**: Updated if public API changes
- [ ] **Accessibility**: UI changes meet a11y standards

## Workflow Automation

### Using Commands

```bash
# 1. Create issue from feature requirements
/create-issue Add user notification preferences page

# Returns: Issue #42 created

# 2. Start work (creates branch, runs planner)
/start-work 42

# Creates: issue-42 branch
# Runs: /plan automatically
# Waits: for approval

# 3. Implement with TDD
/tdd Add notification preferences API endpoint

# Writes: tests first
# Implements: minimal code to pass
# Refactors: for quality

# 4. Finish work (review, commit, PR)
/finish-work

# Runs: /code-review
# Creates: commit with conventional message
# Pushes: to origin/issue-42
# Creates: PR with "Closes #42"
# Returns: PR URL
```

### Manual Workflow (Without Commands)

```bash
# 1. Create issue manually
gh issue create --title "Feature: User notification preferences" \
                --body "Allow users to configure notification settings"

# 2. Create branch
git fetch origin main
git checkout -b issue-42 origin/main

# 3. Implement with commits
git add .
git commit -m "feat: add notification preferences API"

git add .
git commit -m "feat: add notification preferences UI"

git add .
git commit -m "test: add notification preferences tests"

# 4. Push and create PR
git push -u origin issue-42

gh pr create --title "feat: Add user notification preferences (#42)" \
             --body "Closes #42"
```

## Best Practices

### Issue Management

1. **Create issues for everything**: Features, bugs, refactoring, spikes
2. **Use labels**: Categorize with `feature`, `bug`, `enhancement`, etc.
3. **Keep issues small**: Split large features into multiple issues
4. **Write clear descriptions**: Include context, requirements, acceptance criteria
5. **Link related issues**: Reference dependencies and related work
6. **Update status**: Comment on progress, blockers, changes
7. **Close stale issues**: Clean up outdated or completed issues

### Branch Management

1. **Always branch from main**: `git checkout -b issue-42 origin/main`
2. **One branch per issue**: Don't mix unrelated changes
3. **Keep branches short-lived**: Merge within 1-2 days
4. **Delete after merge**: Clean up merged branches
5. **Rebase before merge**: Keep history clean with `git rebase main`
6. **Never force push**: Except to your own feature branches

### Commit Management

1. **Commit often**: Small, logical commits
2. **Write good messages**: Descriptive and following convention
3. **One concern per commit**: Don't mix unrelated changes
4. **Test before commit**: Ensure tests pass
5. **Squash when needed**: Combine related commits before merge

### PR Management

1. **Keep PRs small**: <400 lines is ideal
2. **Request specific reviewers**: Tag people with relevant expertise
3. **Respond promptly**: Address feedback within 24 hours
4. **Discuss in comments**: Don't resolve disagreements offline
5. **Use suggestions**: GitHub's suggestion feature for quick fixes
6. **Mark resolved**: Check off completed review comments
7. **Merge quickly**: After approval, merge within a few hours

## Common Patterns

### Feature Flag Pattern

For large features that need multiple PRs:

```typescript
// Use feature flag to hide incomplete work
const FEATURE_NOTIFICATIONS = process.env.NEXT_PUBLIC_FEATURE_NOTIFICATIONS === 'true'

export function NotificationBell() {
  if (!FEATURE_NOTIFICATIONS) return null

  return <div>Notification bell component</div>
}
```

This allows:
- Merging incomplete features to main
- Progressive development across PRs
- Testing in production without exposing to users
- Easy rollback if issues occur

### Spike Pattern

For investigative work:

```markdown
## Issue: Spike - Investigate Redis vs Valkey for caching

**Type**: Spike (time-boxed investigation)
**Time Box**: 4 hours
**Outcome**: Decision document

### Questions to Answer
1. Performance comparison
2. Feature parity
3. Migration effort
4. Cost comparison

### Deliverable
- [ ] Performance benchmark results
- [ ] Feature comparison table
- [ ] Migration plan outline
- [ ] Recommendation with rationale
```

### Hotfix Pattern

For urgent production bugs:

```bash
# 1. Create hotfix issue
gh issue create --title "Hotfix: Critical auth bug" --label bug,critical

# 2. Branch from main (or production tag)
git checkout -b issue-999 origin/main

# 3. Implement minimal fix
# (Skip /plan and /tdd for speed, but don't skip /code-review)

# 4. Fast-track PR
/finish-work
gh pr create --label hotfix

# 5. Request immediate review
gh pr edit --add-reviewer @on-call-engineer

# 6. Merge and deploy ASAP
gh pr merge --squash
```

## Troubleshooting

### Branch diverged from main

```bash
# Rebase onto latest main
git fetch origin main
git rebase origin/main

# If conflicts, resolve and continue
git add .
git rebase --continue
```

### PR has merge conflicts

```bash
# Update branch with latest main
git fetch origin main
git rebase origin/main

# Resolve conflicts
# Edit conflicting files
git add .
git rebase --continue

# Force push (safe for feature branches)
git push --force-with-lease
```

### Accidentally committed to main

```bash
# Create branch from current state
git branch issue-42

# Reset main to origin
git checkout main
git reset --hard origin/main

# Switch to feature branch
git checkout issue-42
```

### Need to update commit message

```bash
# Last commit
git commit --amend -m "new message"

# Older commits
git rebase -i HEAD~3  # Interactive rebase last 3 commits
# Change 'pick' to 'reword' for commits to change
```

## Tools Integration

### GitHub CLI (`gh`)

```bash
# Issue management
gh issue list
gh issue view 42
gh issue create
gh issue close 42

# PR management
gh pr list
gh pr view 55
gh pr create
gh pr review 55
gh pr merge 55
gh pr checks 55  # View CI/CD status

# Useful aliases
gh alias set prc 'pr create --fill'
gh alias set prv 'pr view --web'
```

### Git Aliases

Add to `~/.gitconfig`:

```ini
[alias]
  co = checkout
  br = branch
  ci = commit
  st = status
  unstage = reset HEAD --
  last = log -1 HEAD
  visual = log --graph --oneline --all
  cleanup = !git branch --merged | grep -v '\\*\\|main\\|develop' | xargs -n 1 git branch -d
```

**Remember**: GitHub Flow is about speed and quality. Keep PRs small, review quickly, merge often, and deploy continuously.
