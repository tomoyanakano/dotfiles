# Agent Orchestration

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| build-error-resolver | Fix build errors | When build fails |
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation | Updating docs |

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth.ts
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utils.ts

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Agent Shutdown & Process Cleanup

エージェントをシャットダウンする際、子プロセス（vitest, tsc, build等）が孤立プロセスとして残る可能性がある。

**必須手順:**
1. エージェントに `shutdown_request` を送る**前に**、実行中のテスト/ビルドの完了を確認
2. 全エージェントシャットダウン後、孤立プロセスを確認・削除:
   ```bash
   ps aux | grep -E "vitest|tsc|remix" | grep -v grep
   pkill -f vitest  # 必要に応じて
   ```
3. チーム作業完了時のチェックリスト:
   - [ ] 全エージェントがシャットダウン済み
   - [ ] 孤立プロセスなし
   - [ ] TeamDelete 実行済み

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
