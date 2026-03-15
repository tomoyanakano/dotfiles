# Claude Code Hooks

`settings.json` に設定されているフックの説明。

## PreToolUse（ツール実行前）

| matcher | スクリプト | 説明 |
|---------|-----------|------|
| `Bash` | `block-dangerous-git.sh` | 危険なgitコマンド（force push, reset --hard等）をブロック |
| `Read\|Write\|Edit` | `block-secret-access.sh` | .env, 秘密鍵等の機密ファイルへのアクセスをブロック |
| `Bash` | `rtk-rewrite.sh` | RTK（Rust Token Killer）によるコマンド書き換え。トークン節約 |
| `*` | `send_observability.sh PreToolUse` | Observabilityサーバーにイベント送信 |

## PostToolUse（ツール実行後）

| matcher | スクリプト | 説明 |
|---------|-----------|------|
| `*` | `send_observability.sh PostToolUse` | Observabilityサーバーにイベント送信 |

## Stop（セッション停止時）

| matcher | スクリプト | 説明 |
|---------|-----------|------|
| `*` | `terminal-notifier` | macOS通知「タスクが完了しました」 |
| `*` | `send_observability.sh Stop --add-chat` | チャット履歴付きでObservabilityサーバーに送信 |

## Notification（ユーザー確認待ち）

| matcher | スクリプト | 説明 |
|---------|-----------|------|
| `*` | `terminal-notifier` | macOS通知「ユーザー確認待ちです」 |
| `*` | `send_observability.sh Notification` | Observabilityサーバーにイベント送信 |

## SessionStart / SessionEnd

| スクリプト | 説明 |
|-----------|------|
| `send_observability.sh SessionStart` | セッション開始をObservabilityサーバーに記録 |
| `send_observability.sh SessionEnd` | セッション終了をObservabilityサーバーに記録 |

## SubagentStart / SubagentStop

| スクリプト | 説明 |
|-----------|------|
| `send_observability.sh SubagentStart` | サブエージェント起動をObservabilityサーバーに記録 |
| `send_observability.sh SubagentStop` | サブエージェント停止をObservabilityサーバーに記録 |

## UserPromptSubmit（ユーザー入力時）

| スクリプト | 説明 |
|-----------|------|
| `send_observability.sh UserPromptSubmit` | ユーザープロンプトをObservabilityサーバーに記録 |

## Observabilityサーバー

- リポジトリ: `~/projects/claude-code-observability/`
- サーバー: `http://localhost:4000`（API）
- ダッシュボード: `http://localhost:5173`（Vue.js UI）
- 起動: `cd ~/projects/claude-code-observability && just start`
- 停止: `cd ~/projects/claude-code-observability && just stop`
- `--source-app` はカレントディレクトリ名から自動取得

### アンインストール

サーバー停止・リポジトリ削除・フック設定の除去を一括で行う:

```bash
~/.claude/hooks/cleanup-observability.sh
```
