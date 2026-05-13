---
description: "軽量オーケストレーション via cmux. Usage: /manage #42 #43 #45 (issues in priority order), /manage status, /manage cleanup, /manage stop"
---

# Manage Command

cmux経由でWorker Claude Codeセッションを起動する軽量オーケストレーター。
**Managerは計画・起動・ステータス確認のみ。監視ループ・レビュー・PR作成はWorkerが自律実行。**

## Arguments

`$ARGUMENTS` を解析して以下のサブコマンドを判別:

- **issue指定**: `/manage #42 #43 #45` or `/manage 42 43 45` → issueを優先順位順に処理
- **status**: `/manage status` → 現在の進捗を表示
- **cleanup**: `/manage cleanup` → 完了済みworkspace/worktreeを自動検出して削除（状態ファイル不要）
- **stop**: `/manage stop` → 全Workerを停止しクリーンアップ

## 共通: 自動クリーンアップ（全サブコマンド共通）

**どのサブコマンドでも最初に実行する:**

`.claude/orchestration/results/` に `status: done` または `status: failed` の結果ファイルがあれば、即座にクリーンアップ:

```bash
for result_file in .claude/orchestration/results/task-*.json; do
  result_status=$(jq -r '.status' "$result_file" 2>/dev/null)
  if [ "$result_status" = "done" ] || [ "$result_status" = "failed" ]; then
    task_id=$(jq -r '.task_id' "$result_file")
    # workers.jsonからworkspace_idとworktree_pathを取得してclose + remove
    rm -f ".claude/orchestration/blocked/${task_id}.json"
  fi
done
```

これにより、Workerからの通知が届かなくても次回の `/manage` 実行時に必ずクリーンアップされる。

---

## Subcommand: Issue処理（デフォルト）

引数にissue番号がある場合、以下を実行:

### Step 1: Issue取得とタスク分解

```bash
# Managerのsurface IDを取得（タスクファイルに埋め込み、Worker完了時の通知先）
# 出力例: "surface:12" → この値をMGR_SURFACEに保存してタスクJSON全件に埋め込む
MGR_SURFACE=$(cmux identify)
echo "Manager surface: $MGR_SURFACE"

# 各issueの詳細を取得
gh issue view {number}
```

1. 各issueの内容を分析
2. 具体的なタスクに分解（1タスク = 1つの実装単位）
3. タスク間の依存関係を特定
4. `.claude/orchestration/tasks/task-{id}.json` にタスクファイルを書き出す
   **必須**: `manager_surface` フィールドに `$MGR_SURFACE` の値を設定する

タスクファイルのスキーマ:
```json
{
  "id": "task-001",
  "issue_number": 42,
  "type": "implement",
  "priority": 1,
  "status": "pending",
  "assignee_surface": null,
  "manager_surface": "surface:XX",
  "workspace": "workspace:XX",
  "description": "タスクの説明",
  "branch": "issue-42",
  "instructions": "詳細な実装指示",
  "ports": {
    "client": 3000,
    "shop": 3001,
    "admin": 3002,
    "backend": 4003
  },
  "context": {
    "files": ["対象ファイルパス"],
    "dependencies": [],
    "acceptance_criteria": ["受入条件"]
  },
  "created_at": "ISO timestamp",
  "updated_at": "ISO timestamp"
}
```

**ポート割り当てルール**: issue番号からオフセットを計算してポート競合を回避する。
```
offset = issue_number % 900
client:  3000 + offset
shop:    3001 + offset
admin:   3002 + offset
backend: 4003 + offset

例: issue-1366 → offset=466 → client:3466, shop:3467, admin:3468, backend:4469
```

5. `.claude/orchestration/queue.json` を更新
6. **計画を人間に提示してWAIT FOR APPROVAL**

提示フォーマット:
```
## 実行計画

### Issue #42: {title} (優先度: 1)
- task-001: {description} [依存なし]
- task-002: {description} [task-001に依存]

### Issue #43: {title} (優先度: 2)
- task-003: {description} [依存なし]

**並列度**: 最大8 Worker
**推定タスク数**: {n}
**依存関係によるシリアル実行**: {n}タスク

この計画で進めますか？ (yes / modify: {変更内容})
```

### Step 2: Worker起動（承認後）→ 即座に制御を返す

`.claude/orchestration/config.json` を読んで設定を取得。

依存関係が解決済みのpendingタスクから、max_workers数までWorkerを起動:

```bash
# 0. 必要なディレクトリを事前作成（Workerがパーミッションダイアログで詰まるのを防ぐ）
mkdir -p .claude/orchestration/results
mkdir -p .claude/orchestration/tasks
mkdir -p .claude/orchestration/heartbeats
mkdir -p .claude/orchestration/blocked

# 1. git worktree作成
git worktree add .worktrees/issue-{number} -b issue-{number} origin/main

# 1.5. worktreeにシンボリックリンクをセットアップ
WORKTREE=".worktrees/issue-{number}"
REPO_ROOT="$(pwd)"

# shamefully-hoist=true を .npmrc に追加（react-router dev のpnpmインスタンス競合を解消）
echo "shamefully-hoist=true" > "$WORKTREE/.npmrc"

# ルートレベルの .env 系
for f in .env .env.local .env.development .env.development.local .env.test .env.test.local; do
  [ -f "$REPO_ROOT/$f" ] && ln -sf "$REPO_ROOT/$f" "$WORKTREE/$f"
done

# アプリレベルの .env（monorepo対応）
for app_env in apps/client/.env apps/admin/.env apps/shop/.env packages/services/backend/.env apps/client/.env.local apps/admin/.env.local apps/shop/.env.local; do
  if [ -f "$REPO_ROOT/$app_env" ]; then
    mkdir -p "$WORKTREE/$(dirname $app_env)"
    ln -sf "$REPO_ROOT/$app_env" "$WORKTREE/$app_env"
  fi
done

# orchestration ディレクトリもシンボリックリンク（WorkerがManagerと同じresults/を使う）
mkdir -p "$WORKTREE/.claude"
ln -sf "$REPO_ROOT/.claude/orchestration" "$WORKTREE/.claude/orchestration"

# 2. issue用のworkspace作成（名前付き、worktreeディレクトリで起動）
# リポジトリ名を取得
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
cmux new-workspace --name "W:${REPO_NAME}/issue-{number}-{short-title}" --cwd $(pwd)/.worktrees/issue-{number}
# 出力からworkspace IDを取得

# 3. workspaceをウィンドウにアタッチ（必須: in_window=falseだとsendが失敗する）
cmux select-workspace --workspace {workspace_id}
sleep 2

# 4. 作成されたworkspaceのsurface IDを取得
cmux list-pane-surfaces --workspace {workspace_id}
# 初期paneのsurface IDを取得

# 5. Claude Code起動
cmux send --workspace {workspace_id} "claude --dangerously-skip-permissions\n"

# 6. Claude Code起動を待つ（4秒）
sleep 4

# 7. read-screenで起動確認
cmux read-screen --workspace {workspace_id} --lines 5

# 7. ワークスペースカラーをBlue（実装中）に設定
cmux workspace-action --workspace {workspace_id} --action set-color --color Blue

# 8. タスク指示を送信（WorkerはPR作成まで自律実行）
cmux send --surface {surface_id} ".claude/orchestration/tasks/task-{id}.json を読んで、~/.claude/orchestration/worker-instructions.md の手順に従って実装からPR作成まで自律的に完了してください。\n"
# NOTE: \n at end of cmux send = Enter key. Do NOT use send-key separately.
```

`.claude/orchestration/workers.json` を更新:
```json
{
  "workers": [
    {
      "id": "worker-1",
      "workspace": "workspace:XX",
      "surface": "surface:XX",
      "status": "busy",
      "current_task": "task-001",
      "worktree_path": ".worktrees/issue-42",
      "started_at": "ISO timestamp",
      "restarted_count": 0,
      "last_restarted_at": null
    }
  ]
}
```

**Worker起動後、即座に人間に制御を返す:**
```
Workers起動完了。各Workerが自律的にPR作成まで実行します。
- `/manage status` で進捗確認
- `/manage #50 #51` で追加issueを投入
- `/manage stop` で全Worker停止
```

---

## Subcommand: status

`/manage status` の場合:

1. `.claude/orchestration/queue.json` を読む
2. `.claude/orchestration/workers.json` を読む
3. `.claude/orchestration/results/` の結果ファイルを確認
4. **`.claude/orchestration/blocked/` のファイルを確認** — ファイルが存在するWorkerは `⚠️ NEEDS INPUT` 状態
5. 各Workerの `cmux read-screen --surface {id} --lines 15` で最新状態を取得
   - **Worker発信のブロック（優先）**: `.claude/orchestration/blocked/task-{id}.json` が存在する場合は `needs_input` 状態とみなす（read-screenより優先）
   - **詰まり検知**: 出力に以下のキーワードが含まれる場合は `blocked` 状態とみなす:
     - `Do you want to` / `❯ 1. Yes` （パーミッションダイアログ）
     - `AskUserQuestion` / `waiting for` / `Please confirm`
   - **停止検知**: `cmux read-screen` の出力が以下のパターンなら `stopped` とみなす:
     - シェルプロンプト（`$ ` / `% `）のみ表示 → Claude Code が終了した
     - 出力が空 / 空白のみ
   - **ハートビート確認**: `.claude/orchestration/heartbeats/task-{id}.json` の `updated_at` が10分以上前なら `stale` とみなす（stopped として扱う）
6. 以下のフォーマットで表示:

```
## Orchestration Status

### Workers (2/3 active)
| Worker | Surface | Task | Status | Uptime |
|--------|---------|------|--------|--------|
| worker-1 | surface:20 | task-001 | busy | 12m |
| worker-2 | surface:21 | task-002 | ✅ done (PR #55) | 8m |
| worker-3 | surface:22 | task-003 | ⚠️ BLOCKED | 5m |

### Task Queue
| Task | Issue | Type | Status | Assignee |
|------|-------|------|--------|----------|
| task-001 | #42 | implement | in_progress | worker-1 |
| task-002 | #43 | implement | done | worker-2 |
| task-003 | #42 | test | blocked | worker-3 |

### Completed: 1 | Pending: 1 | In Progress: 1 | Failed: 0 | Blocked: 1

🙋 **NEEDS INPUT Workers の対処（Worker発信の確認要求）:**

`.claude/orchestration/blocked/task-{id}.json` を読んで質問内容を確認し、Workerに回答を送信:
```bash
# blockedファイルで質問内容を確認
cat .claude/orchestration/blocked/task-{id}.json

# Workerに回答を送信
cmux send --surface {surface_id} "{回答・指示内容}\n"
```
Workerが回答を受け取るとblockedファイルを自動削除し、実装を再開する。

⚠️ **BLOCKED Workers の対処（パーミッションダイアログ等）:**
- `cmux read-screen --surface {id} --lines 20` で詰まり内容を確認
- パーミッションダイアログの場合: `cmux send --surface {id} "1\n"` で承認（またはWorkerに `--dangerously-skip-permissions` 確認）
- それ以外: `cmux send --surface {id} "{解決指示}\n"` でアンブロック

🔄 **STOPPED Workers の自動再起動:**

`stopped` または `stale` と判定されたWorkerは、以下の手順で自動的に再起動する:

```bash
# 1. 該当Workerのtask_idとworktree_pathをworkers.jsonから取得

# 2. Claude Codeを再起動（既にshellプロンプトがある状態を想定）
cmux send --workspace {workspace_id} "claude --dangerously-skip-permissions\n"

# 3. 起動待機
sleep 5

# 4. 起動確認
cmux read-screen --workspace {workspace_id} --lines 5

# 5. タスク指示を再送信（同じタスクファイルを再実行）
cmux send --surface {surface_id} ".claude/orchestration/tasks/task-{id}.json を読んで、~/.claude/orchestration/worker-instructions.md の手順に従って実装からPR作成まで自律的に完了してください。なお、すでに完了済みのステップはスキップして、ハートビートファイルの step フィールドから再開点を判断してください。\n"

# 6. workers.jsonのstatusをbusyに更新、restarted_atを記録
```

再起動後にステータステーブルに `🔄 RESTARTED` を表示し、人間に通知する。
再起動が2回以上失敗した場合（restarted_count >= 2）は `🔴 FAILED` として人間に手動対応を依頼する。

次のissueがあれば `/manage #XX` で追加できます。
```

### 完了Workerの後処理

statusで完了を確認したWorkerがいる場合:
1. 結果ファイルからPR URLを確認・報告
2. 完了Workerに依存関係が解決済みの次タスクがあれば割当:
   ```bash
   cmux workspace-action --workspace {workspace_id} --action set-color --color Blue
   ```
3. 次タスクがなければ即座にクリーンアップ:
   ```bash
   cmux close-workspace --workspace {workspace_id}
   git worktree remove --force .worktrees/issue-{number}
   ```
4. `workers.json` から該当Workerを削除して保存

---

## Subcommand: cleanup

`/manage cleanup` の場合（状態ファイルがなくても動作）:

1. `cmux list-workspaces` で全workspaceを取得
2. 名前が `W:issue-` で始まるworkspaceを対象にする
3. 各workspaceについて `.claude/orchestration/results/` を確認:
   ```bash
   # results/ 配下のファイルを確認
   ls .claude/orchestration/results/ 2>/dev/null
   ```
4. `status: done` または `status: failed` の結果ファイルが存在するworkspaceをクリーンアップ:
   ```bash
   cmux close-workspace --workspace {workspace_id}
   # worktree名はworkspace名から推定（W:{repo}/issue-{number}-{title} → .worktrees/issue-{number}）
   git worktree remove --force .worktrees/issue-{number} 2>/dev/null || true
   # blockedファイルも削除
   rm -f .claude/orchestration/blocked/task-{id}.json
   ```
5. 結果ファイルが存在しないworkspace（実行中と判断）はスキップ
6. クリーンアップレポートを表示:
   ```
   ## Cleanup Result
   - 削除: workspace:XX (issue-42), workspace:YY (issue-43)
   - スキップ（実行中）: workspace:ZZ (issue-44)
   - worktree削除: .worktrees/issue-42, .worktrees/issue-43
   ```

---

## Subcommand: stop

`/manage stop` の場合:

1. `.claude/orchestration/workers.json` の全Workerに対して:
   ```bash
   cmux send --surface {surface_id} "/exit\n"
   sleep 3
   # workspace単位で閉じる（中のpaneも全て閉じられる）
   cmux close-workspace --workspace {workspace_id}
   ```
2. 全worktreeを削除:
   ```bash
   git worktree list
   # .worktrees/ 配下のみ削除
   git worktree remove .worktrees/issue-{number}
   ```
3. 状態ファイルをリセット（queue.jsonのin_progressタスクをpendingに戻す）
4. 停止レポートを表示

---

## Important Rules

1. **計画フェーズでは必ず人間の承認を待つ** — 勝手に実行開始しない
2. **ファイルベース通信が正** — cmux sendは起動トリガーのみ
3. **1 issue = 1 branch = 1 worktree = 1 workspace** — 複数タスクが同じissueなら同じworktreeで実行
4. **Managerは監視ループを回さない** — Worker起動後は即座に制御を返す
5. **レビュー・コミット・プッシュ・PR作成はWorkerが行う** — Managerは関与しない
6. **クリーンアップは `/manage status`・`/manage cleanup`・`/manage stop` 時に実行** — statusで完了を確認したら即座にclose-workspace + worktree remove
7. **マージコンフリクトは人間に報告** — 自動解決しない
8. **queue.json, workers.json を必ず書き出す** — Worker起動時・完了時・クリーンアップ時に必ず更新。セッションが飛んでも `/manage cleanup` で復旧できるよう結果ファイルが唯一の真実
9. **ワークスペースカラーでステータスを示す**:
   - 🔵 **Blue** — 実装中（Worker起動時）
   - 🟡 **Amber** — テスト中
   - 🟢 **Green** — 完了（PR作成済み）
   - 🔴 **Red** — 失敗・要対応
10. **Worker起動前に必ずディレクトリを事前作成** — `results/`, `tasks/`, `heartbeats/` を `mkdir -p` で作成してからWorkerを起動。Workerがパーミッションダイアログで詰まる主因はディレクトリ不存在
11. **orchastrationディレクトリをworktreeにシンボリックリンク** — WorkerがManagerと同じ `results/` に書き込めるよう `ln -s` でリンクする
12. **`/manage status` でBlocked Workerを必ず報告** — `cmux read-screen` の出力に `Do you want to` / `❯ 1. Yes` が含まれる場合は `⚠️ BLOCKED` として人間に報告し、対処法を提示する
