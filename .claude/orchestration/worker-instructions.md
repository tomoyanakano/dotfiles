# Worker Instructions

あなたは自律型Workerです。タスクファイルを読み、**実装からPR作成まで**すべてを独力で完了してください。
Managerへの報告は結果ファイルの書き出しのみ。監視やレビューを待つ必要はありません。

## ワークフロー

### Step 1: タスク読み込み

指示されたタスクファイル（`.claude/orchestration/tasks/task-{id}.json`）を読む。

確認する項目:
- `instructions`: 実装内容
- `context.files`: 対象ファイル
- `context.dependencies`: 依存タスク（依存先の結果ファイルが存在するか確認）
- `context.acceptance_criteria`: 受入条件

### Step 2: 実装

1. 対象ファイルを読んで現状を理解
2. 受入条件を満たす実装を行う
3. CLAUDE.mdやプロジェクトルールに従う

### Step 3: 検証

実装後、以下を順に実行:

```bash
# TypeScript型チェック
pnpm run typecheck 2>&1 | tail -20

# テスト（関連するテストのみ）
pnpm run test -- --run {関連テストファイル} 2>&1 | tail -30

# lint
pnpm run lint 2>&1 | tail -20
```

**全パスするまでStep 2-3を繰り返す。**

### Step 4: セルフレビュー

```bash
git diff --stat
git diff
```

以下を自分で確認:
- [ ] 受入条件をすべて満たしているか
- [ ] 不要なconsole.logが残っていないか
- [ ] ハードコードされた秘密情報がないか
- [ ] 変更が最小限か（余計なリファクタリングをしていないか）

問題があればStep 2に戻って修正。

### Step 5: コミット・プッシュ

```bash
# 変更をステージング（対象ファイルを明示的に指定）
git add {変更したファイル}

# コミット（conventional commits形式）
git commit -m "{type}: {description} (#{issue_number})"

# プッシュ
git push -u origin {branch_name}
```

- `{type}`: feat / fix / refactor / docs / test / chore / perf
- `{branch_name}`: タスクファイルの `branch` フィールド
- `{issue_number}`: タスクファイルの `issue_number` フィールド

### Step 6: PR作成

```bash
gh pr create \
  --title "{type}: {description} (#{issue_number})" \
  --body "$(cat <<'EOF'
Closes #{issue_number}

## Summary
- {変更内容の箇条書き}

## Verification
- typecheck: pass
- test: pass
- lint: pass

## Test plan
- [ ] 受入条件1
- [ ] 受入条件2

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 7: 結果ファイル書き出し + ワークスペースカラー更新

`.claude/orchestration/results/task-{id}.json` に結果を書き出す。
その後、タスクファイルの `workspace` を使ってカラーを更新:

```bash
# 成功時 → Green
cmux workspace-action --workspace {workspace} --action set-color --color Green
# 失敗時 → Red
cmux workspace-action --workspace {workspace} --action set-color --color Red
```

結果ファイルのスキーマ:

```json
{
  "task_id": "task-001",
  "status": "done",
  "pr_url": "https://github.com/owner/repo/pull/XX",
  "pr_number": "XX",
  "summary": "実装内容のサマリー",
  "verification": {
    "typecheck": "pass",
    "test": "pass",
    "lint": "pass"
  },
  "completed_at": "ISO timestamp"
}
```

失敗した場合:
```json
{
  "task_id": "task-001",
  "status": "failed",
  "error": "失敗の詳細",
  "verification": {
    "typecheck": "pass",
    "test": "fail",
    "lint": "pass"
  },
  "completed_at": "ISO timestamp"
}
```

### Step 8: Managerへ完了通知

タスクファイルの `manager_surface` を使って、Managerセッションにクリーンアップを依頼:

```bash
cmux send --surface {manager_surface} "/manage cleanup\n"
```

これによりManagerが自動的に完了済みworkspace/worktreeを検出・削除し、人間に最新状況を表示する。
（`/manage status` ではなく `/manage cleanup` を使うことで、状態ファイルがなくても確実にクリーンアップが走る）

## Important Rules

1. **すべて自律的に完了する** — Managerの監視やレビューを待たない
2. **検証が全パスするまでコミットしない** — typecheck, test, lintすべてpass
3. **コミットメッセージはconventional commits形式** — 英語で記述
4. **PRにはissue番号を含める** — `Closes #XX` でissueを自動クローズ
5. **結果ファイルは必ず書き出す** — Managerがステータス確認に使う
6. **マージコンフリクトが発生したら結果ファイルにfailedで報告** — 自動解決しない
7. **セキュリティルールを守る** — 秘密情報のハードコード禁止
