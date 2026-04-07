---
description: "軽量オーケストレーション via cmux. Usage: /manage #42 #43 #45 (issues in priority order), /manage status, /manage stop"
---

# Manage Command

cmux経由でWorker Claude Codeセッションを起動する軽量オーケストレーター。
**Managerは計画・起動・ステータス確認のみ。監視ループ・レビュー・PR作成はWorkerが自律実行。**

## Arguments

`$ARGUMENTS` を解析して以下のサブコマンドを判別:

- **issue指定**: `/manage #42 #43 #45` or `/manage 42 43 45` → issueを優先順位順に処理
- **status**: `/manage status` → 現在の進捗を表示
- **stop**: `/manage stop` → 全Workerを停止しクリーンアップ

## Subcommand: Issue処理（デフォルト）

引数にissue番号がある場合、以下を実行:

### Step 1: Issue取得とタスク分解

```bash
# Managerのsurface IDを取得（タスクファイルに埋め込み、Worker完了時の通知先）
cmux identify

# 各issueの詳細を取得
gh issue view {number}
```

1. 各issueの内容を分析
2. 具体的なタスクに分解（1タスク = 1つの実装単位）
3. タスク間の依存関係を特定
4. `.claude/orchestration/tasks/task-{id}.json` にタスクファイルを書き出す

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
  "context": {
    "files": ["対象ファイルパス"],
    "dependencies": [],
    "acceptance_criteria": ["受入条件"]
  },
  "created_at": "ISO timestamp",
  "updated_at": "ISO timestamp"
}
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
# 1. git worktree作成
git worktree add .worktrees/issue-{number} -b issue-{number} origin/main

# 2. issue用のworkspace作成（名前付き、worktreeディレクトリで起動）
cmux new-workspace --name "issue-{number}-{short-title}" --cwd $(pwd)/.worktrees/issue-{number}
# 出力からworkspace IDを取得

# 3. 作成されたworkspaceのsurface IDを取得
cmux list-panes --workspace {workspace_id}
# 初期paneのsurface IDを取得

# 4. Claude Code起動
cmux send --surface {surface_id} "claude --dangerously-skip-permissions\n"

# 5. Claude Code起動を待つ（3秒）
sleep 3

# 6. read-screenで起動確認
cmux read-screen --surface {surface_id} --lines 5

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
      "started_at": "ISO timestamp"
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
4. 各Workerの `cmux read-screen --surface {id} --lines 10` で最新状態を取得
5. 以下のフォーマットで表示:

```
## Orchestration Status

### Workers (2/3 active)
| Worker | Surface | Task | Status | Uptime |
|--------|---------|------|--------|--------|
| worker-1 | surface:20 | task-001 | busy | 12m |
| worker-2 | surface:21 | task-002 | done (PR #55) | 8m |

### Task Queue
| Task | Issue | Type | Status | Assignee |
|------|-------|------|--------|----------|
| task-001 | #42 | implement | in_progress | worker-1 |
| task-002 | #43 | implement | done | worker-2 |
| task-003 | #42 | test | pending | — |

### Completed: 1 | Pending: 1 | In Progress: 1 | Failed: 0

次のissueがあれば `/manage #XX` で追加できます。
```

### 完了Workerの後処理

statusで完了を確認したWorkerがいる場合:
1. ワークスペースカラーを更新:
   ```bash
   # 完了 → Green
   cmux workspace-action --workspace {workspace_id} --action set-color --color Green
   # 失敗 → Red
   cmux workspace-action --workspace {workspace_id} --action set-color --color Red
   ```
2. 結果ファイルからPR URLを確認・報告
3. 完了Workerに依存関係が解決済みの次タスクがあれば割当（カラーをBlueに戻す）
4. 次タスクがなければ、ペインを閉じてworktreeを削除

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
6. **クリーンアップは `/manage status` か `/manage stop` 時に実行**
7. **マージコンフリクトは人間に報告** — 自動解決しない
8. **queue.json, workers.json を常に最新に保つ** — 全状態変更時に更新
9. **ワークスペースカラーでステータスを示す**:
   - 🔵 **Blue** — 実装中（Worker起動時）
   - 🟡 **Amber** — テスト中
   - 🟢 **Green** — 完了（PR作成済み）
   - 🔴 **Red** — 失敗・要対応
