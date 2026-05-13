# Worker Instructions

あなたは自律型Workerです。タスクファイルを読み、**実装からPR作成まで**すべてを独力で完了してください。
Managerへの報告は結果ファイルの書き出しのみ。監視やレビューを待つ必要はありません。

## ハートビート

各ステップの開始時・完了時に必ずハートビートファイルを更新する。
Managerはこのファイルが10分以上更新されていない場合、Workerが停止したと判断して再起動する。

```bash
# ハートビート書き込みコマンド（{task_id} と {step} を実際の値に置換）
REPO_ROOT="$(git worktree list | head -1 | awk '{print $1}')"
mkdir -p "$REPO_ROOT/.claude/orchestration/heartbeats"
cat > "$REPO_ROOT/.claude/orchestration/heartbeats/task-{task_id}.json" <<EOF
{
  "task_id": "{task_id}",
  "step": "{step}",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

stepの値: `started` / `implementing` / `verifying` / `reviewing` / `committing` / `pr_creating` / `dev_server` / `done`

## ワークフロー

### Step 1: タスク読み込み

指示されたタスクファイル（`.claude/orchestration/tasks/task-{id}.json`）を読む。

確認する項目:
- `instructions`: 実装内容
- `context.files`: 対象ファイル
- `context.dependencies`: 依存タスク（依存先の結果ファイルが存在するか確認）
- `context.acceptance_criteria`: 受入条件

**タスク読み込み完了後、即座にハートビートを書く（step: `started`）**

### Step 2: 実装

1. 対象ファイルを読んで現状を理解
2. 受入条件を満たす実装を行う（**ハートビートを step: `implementing` で更新**）
3. CLAUDE.mdやプロジェクトルールに従う

### Step 3: 検証

実装後、以下を順に実行（**ハートビートを step: `verifying` で更新してから実行**）:

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

**ハートビートを step: `reviewing` で更新してから実施。**

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

**ハートビートを step: `committing` で更新してから実施。**

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

**ハートビートを step: `pr_creating` で更新してから実施。**

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

### Step 6.5: スクリーンショット撮影

**ハートビートを step: `dev_server` で更新してから実施。**

React Router v7（frameworkモード）はworktreeでdev serverを起動するとpnpmのモジュール解決の制約で動作しない。
代わりに、プロダクションビルド + `react-router-serve` + Playwright でスクリーンショットを撮影する。

タスクファイルの `ports` フィールドからポートを取得:
```bash
TASK_FILE=".claude/orchestration/tasks/task-{task_id}.json"
CLIENT_PORT=$(jq -r '.ports.client // 3000' "$TASK_FILE")
MANAGER_SURFACE=$(jq -r '.manager_surface // empty' "$TASK_FILE")
TASK_ID=$(jq -r '.id' "$TASK_FILE")
```

#### 1. ビルド

```bash
# worktreeルートから（shared パッケージを先にビルド）
REPO_ROOT="$(git worktree list | head -1 | awk '{print $1}')"
cd "$REPO_ROOT"
pnpm run build:shared

# client をビルド（apps/client/.env を読まず環境変数は次のステップで注入）
cd apps/client
npx react-router build
cd "$REPO_ROOT"
```

#### 2. サーバー起動

`react-router-serve` は `.env` を自動読込しないため `source` で注入する。

```bash
# 既存プロセスをクリア
lsof -ti :${CLIENT_PORT} | xargs kill -9 2>/dev/null || true

# .env を読み込んでサーバー起動（バックグラウンド）
(cd apps/client && set -a && source .env && set +a && \
  NODE_ENV=development PORT=${CLIENT_PORT} \
  npx react-router-serve build/server/index.js) &
SERVER_PID=$!
sleep 5  # 起動待機
```

#### 3. Playwright でスクリーンショット

```bash
SCREENSHOT_DIR="/tmp/screenshots/${TASK_ID}"
mkdir -p "$SCREENSHOT_DIR"

# スクリーンショットスクリプトを生成（CJS形式 — Playwright は CommonJS）
PLAYWRIGHT_BIN="$(cd apps/client && node -e "console.log(require.resolve('playwright'))" 2>/dev/null || echo "")"
PLAYWRIGHT_PKG_DIR="$(dirname $(dirname ${PLAYWRIGHT_BIN:-apps/client/node_modules/playwright/index.js}))"

cat > /tmp/pw-screenshot-${TASK_ID}.cjs << SCRIPT
const { chromium } = require('${PLAYWRIGHT_PKG_DIR}');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.setDefaultTimeout(20000);

  // dev-bypass 認証
  await page.goto('http://localhost:${CLIENT_PORT}/auth/dev-bypass', { waitUntil: 'networkidle' });

  // ストア選択ボタンをクリック（最初のストア）
  const storeBtn = page.locator('a, button').first();
  if (await storeBtn.isVisible()) {
    await storeBtn.click();
    await page.waitForURL('**\/app**', { timeout: 15000 });
    await page.waitForLoadState('networkidle');
  }

  // スクリーンショット対象 URL（タスクに応じて変更可）
  const targets = [
    { url: 'http://localhost:${CLIENT_PORT}/app/fulfillments?tab=fulfillments&type=normal', name: '01-normal' },
    { url: 'http://localhost:${CLIENT_PORT}/app/fulfillments?tab=fulfillments&type=stock',  name: '02-stock' },
  ];

  for (const { url, name } of targets) {
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.screenshot({ path: '${SCREENSHOT_DIR}/' + name + '.png', fullPage: false });
    console.log('captured: ' + name);
  }

  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
SCRIPT

node /tmp/pw-screenshot-${TASK_ID}.cjs
SCREENSHOT_STATUS=$?
```

#### 4. サーバーを停止してスクリーンショットパスを記録

```bash
kill $SERVER_PID 2>/dev/null || true
lsof -ti :${CLIENT_PORT} | xargs kill -9 2>/dev/null || true

if [ $SCREENSHOT_STATUS -eq 0 ]; then
  SCREENSHOT_PATHS="${SCREENSHOT_DIR}/01-normal.png, ${SCREENSHOT_DIR}/02-stock.png"
  echo "✅ Screenshots saved: $SCREENSHOT_PATHS"
else
  SCREENSHOT_PATHS="(撮影失敗)"
  echo "⚠️  Screenshot failed"
fi
```

#### 5. Managerへ完了通知

```bash
cmux send --surface "$MANAGER_SURFACE" "✅ PR作成完了。スクリーンショット: ${SCREENSHOT_PATHS}\n"
```

### Step 7: 結果ファイル書き出し + ワークスペースカラー更新

**注意**: 結果ファイルを書く前に、worktreeには `.claude/orchestration/results/` が存在しない場合がある。
シンボリックリンクが正しく設定されているか確認し、なければ直接Managerリポジトリのパスに書く:

```bash
# orchestrationディレクトリがシンボリックリンクになっているか確認
ls -la .claude/orchestration 2>/dev/null || {
  # なければManagerリポジトリのパスを特定して直接書く
  # worktreeは通常 {repo_root}/.worktrees/issue-{number}/ にある
  REPO_ROOT="$(git worktree list | head -1 | awk '{print $1}')"
  mkdir -p "$REPO_ROOT/.claude/orchestration/results"
}
```

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
  "screenshot_paths": [
    "/tmp/screenshots/task-001/01-normal.png",
    "/tmp/screenshots/task-001/02-stock.png"
  ],
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

**結果ファイルがソース・オブ・トゥルース。** Managerは次回の `/manage` 実行時に自動的にクリーンアップを検出する。

タスクファイルの `manager_surface` を使ってManagerに通知する:

```bash
# タスクファイルからmanager_surfaceを取得
TASK_FILE=".claude/orchestration/tasks/task-{task_id}.json"
MANAGER_SURFACE=$(jq -r '.manager_surface // empty' "$TASK_FILE" 2>/dev/null)

if [ -n "$MANAGER_SURFACE" ] && [ "$MANAGER_SURFACE" != "null" ]; then
  # Managerのsurfaceに /manage status を送信（statusはcleanupも兼ねる）
  cmux send --surface "$MANAGER_SURFACE" "/manage status\n"
  echo "✅ Manager notified: $MANAGER_SURFACE"
else
  echo "⚠️  manager_surface not found in task file — Manager will detect completion on next /manage status"
fi
```

通知後、このWorkerセッションでの作業は完了。Claude Codeを終了する:

```bash
# Claude Codeを終了（worktreeのcloseはManagerが行う）
exit
```

## 確認が必要な場合（BLOCKED）

実装中に**人間の判断が必要な状況**（仕様の曖昧さ、破壊的変更のリスク、セキュリティ上の懸念等）が発生した場合:

### Step B1: Managerへ通知

```bash
# 1. blockedファイルを書き出す
REPO_ROOT="$(git worktree list | head -1 | awk '{print $1}')"
mkdir -p "$REPO_ROOT/.claude/orchestration/blocked"
cat > "$REPO_ROOT/.claude/orchestration/blocked/task-{task_id}.json" <<EOF
{
  "task_id": "{task_id}",
  "question": "{確認内容を簡潔に記述}",
  "context": "{判断に必要な背景情報}",
  "options": ["{選択肢A}", "{選択肢B}"],
  "blocked_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# 2. ワークスペースカラーをAmber（待機中）に変更
cmux workspace-action --workspace {workspace} --action set-color --color Amber

# 3. ハートビートをblocked状態で更新
cat > "$REPO_ROOT/.claude/orchestration/heartbeats/task-{task_id}.json" <<EOF
{
  "task_id": "{task_id}",
  "step": "blocked",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# 4. Managerのsurfaceに通知を送信
cmux send --surface {manager_surface} "⚠️ Worker [task-{task_id}] needs input: {確認内容の要約} → .claude/orchestration/blocked/task-{task_id}.json\n"
```

### Step B2: Manager回答を待つ

通知送信後、**その場で待機する**（ループしない）。
Managerが `cmux send --surface {worker_surface} "{回答}\n"` で指示を送ってくる。

回答受信後:
1. blockedファイルを削除: `rm "$REPO_ROOT/.claude/orchestration/blocked/task-{task_id}.json"`
2. ワークスペースカラーをBlueに戻す: `cmux workspace-action --workspace {workspace} --action set-color --color Blue`
3. ハートビートを `implementing` に戻す
4. 指示に従ってStep 2（実装）を再開

---

## Important Rules

1. **すべて自律的に完了する** — Managerの監視やレビューを待たない
2. **検証が全パスするまでコミットしない** — typecheck, test, lintすべてpass
3. **コミットメッセージはconventional commits形式** — 英語で記述
4. **PRにはissue番号を含める** — `Closes #XX` でissueを自動クローズ
5. **結果ファイルは必ず書き出す** — Managerがステータス確認に使う
6. **マージコンフリクトが発生したら結果ファイルにfailedで報告** — 自動解決しない
7. **セキュリティルールを守る** — 秘密情報のハードコード禁止
8. **`AskUserQuestion` ツールを絶対に使わない** — 確認が必要な場合は必ず「確認が必要な場合（BLOCKED）」セクションのblockedファイルメカニズムを使うこと。`AskUserQuestion` はWorkerのターミナルに表示されManagerには届かない
