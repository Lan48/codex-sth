---
name: "multi-agent-orchestrator"
description: "Orchestrate one strong planner agent and multiple lighter worker agents to complete a task in parallel inside Codex. Use when Codex needs multi-agent decomposition, delegation, parallel execution, 子任务拆分, 并行执行, or strong-model planning with lighter-model execution."
---

# Multi-Agent Orchestrator

Use this skill only when the user explicitly wants delegation, sub-agents, or parallel agent work. Keep simple, tightly coupled, or purely advisory tasks local.

## Decide Whether To Fan Out

Fan out only if all of these are true:

- The task is large enough that parallel work will meaningfully reduce time or risk.
- At least two subtasks can proceed independently for a while.
- Each subtask can be expressed with a clear contract, owner, and output.
- Write scopes can stay disjoint if code changes are involved.

Keep work local when any of these are true:

- The immediate next step is blocked on one urgent answer.
- The task is small, mostly exploratory, or highly coupled.
- Multiple agents would need to edit the same files.
- The user only asked for planning, brainstorming, or explanation.

## Keep The Main Agent In Charge

The main agent owns:

1. Goal clarification and constraints
2. Task graph and critical-path decisions
3. Shared contracts and architecture choices
4. Final integration
5. End-to-end verification
6. User-facing summary and tradeoff calls

Do not hand the immediate blocker on the critical path to a child agent unless there is no better local step.

## Pick Roles And Models

This skill follows the global orchestration contract by default:
`<YOUR-CODEX-ROOT>/.codex/skills/.system/orchestration-contract.md`

Default profile (unless user overrides):

- Strong planner and integrator: main agent on `gpt-5.4`, `reasoning_effort="xhigh"`
- Child agents: `gpt-5.4-mini` by default, `reasoning_effort="medium"`

Use `reasoning_effort="medium"` for child agents by default. Raise child reasoning only for unusually tricky subtasks.

## Design Subtasks Before Spawning

For every child agent, specify:

- Exact goal
- Ownership boundaries
- Allowed write scope
- Forbidden files or areas
- Expected output format
- Whether the task is read-only or allowed to edit
- What to verify before returning

For every code-edit worker, explicitly say:

- "你不是唯一在代码库里工作的人。"
- "不要回滚不是你做的改动。"
- "如果发现并发改动，基于现状调整实现。"
- "完成后汇报改了哪些文件，以及为什么这样改。"

Do not assign overlapping write ownership to two workers unless one of them is strictly read-only.

If a worker owns tests only, state that explicitly and forbid production-code edits unless the main agent reassigns the task.

## Execution Workflow

### 1. Plan Locally First

Use `update_plan` before spawning agents. Capture:

- Main-agent critical-path work
- Parallel read-only subtasks
- Parallel write subtasks
- Integration and validation

Decide what the main agent should do locally right now before delegating anything.

### 2. Prefer Read-Only Fan-Out While The Task Is Still Fuzzy

Use `explorer` for:

- Impact analysis
- Architecture tracing
- Candidate file discovery
- Dependency mapping
- Test gap analysis

Prefer read-only fan-out before code fan-out when the approach is still ambiguous.

### 3. Fan Out Writes Only With Disjoint Ownership

Use `worker` only when the subtask has:

- A narrow goal
- A clear owner
- Limited files or modules
- A concrete done condition

Good splits:

- Backend API vs frontend client
- Feature implementation vs tests
- Module A vs module B
- Data migration prep vs app code

Bad splits:

- Two workers editing the same service
- One worker blocked immediately on another worker's result
- Vague asks such as "clean this area up"

### 4. Keep The Critical Path Local

Do the immediate blocker in the main agent instead of delegating it. Delegate sidecar work that can make progress in parallel while the main agent continues moving.

### 5. Wait Sparingly

Use `wait_agent` only when:

- A child result is needed for the next step
- You are ready to integrate that result
- There is no better local work left

Do not busy-wait. If only one result matters next, wait for that child instead of the full batch.

### 6. Integrate Centrally

Review child outputs in the main agent. Resolve conflicts, reroute follow-up work, and run final verification centrally when feasible. Close agents after collecting what you need.

## Tool Usage Pattern

Typical orchestration loop:

```python
update_plan(
    plan=[
        {"step": "Clarify goal and constraints", "status": "completed"},
        {"step": "Split into local work and parallel subtasks", "status": "completed"},
        {"step": "Integrate child results", "status": "in_progress"},
        {"step": "Run final verification", "status": "pending"},
    ]
)
```

```python
analysis_agent = spawn_agent(
    agent_type="explorer",
    model="gpt-5.4-mini",
    reasoning_effort="medium",
    fork_context=True,
    message="只分析认证状态在各层之间的传递路径，列出涉及文件和风险点，不要改代码。"
)
```

```python
worker_agent = spawn_agent(
    agent_type="worker",
    model="gpt-5.4-mini",
    reasoning_effort="medium",
    fork_context=True,
    message="""
你负责 /src/api 和 /src/services 下与重试逻辑相关的改动。
只能修改这两个目录。
你不是唯一在代码库里工作的人。
不要回滚不是你做的改动。
如果遇到并发修改，基于现状完成实现。
完成后汇报改动文件、核心改动和验证结果。
"""
)
```

```python
wait_agent(targets=[analysis_agent["id"]], timeout_ms=600000)
send_input(target=worker_agent["id"], message="补一组失败路径测试并说明覆盖范围。")
close_agent(target=worker_agent["id"])
```

Use `fork_context=True` when the child needs the same conversation, assumptions, or file context. Prefer `fork_context=False` when the task can be described cleanly and should run with a smaller, cleaner context.

## Choose `fork_context`

Use `fork_context=True` when:

- The child needs the same user constraints or recent decisions
- The task depends on subtle assumptions already established in the thread
- The child must continue directly from the current conversation state

Use `fork_context=False` when:

- The task can be expressed as a clean standalone brief
- You want the child to avoid inheriting noisy or stale context
- The child is doing a narrow read-only lookup or bounded edit with explicit files

When in doubt, prefer the smaller context if the task brief is already complete.

## Reusable Patterns

### Pattern A: One Planner Plus Many Readers

Use for discovery-heavy work.

- Main agent defines the task graph
- Multiple `explorer` agents gather evidence
- Main agent chooses the implementation path
- Workers start only after ambiguity drops

### Pattern B: One Planner Plus Many Writers

Use for larger changes with clean ownership boundaries.

- Main agent owns shared contracts and architecture
- Each `worker` owns one module or file cluster
- Main agent integrates and verifies

### Pattern C: One Planner Plus One Verifier

Use when implementation is mostly local but an independent second pass is valuable.

- Main agent implements
- One child agent reviews tests, edge cases, or docs
- Main agent decides whether to revise

### Pattern D: Planner Plus Explorer Plus Implementation Worker Plus Test Worker

Use for a medium-to-large feature where architecture is still a little fuzzy, but the code can later split cleanly.

Suggested order:

1. Main agent clarifies the goal, constraints, and provisional split.
2. `explorer` does read-only impact analysis and returns candidate files, risks, and likely dependency edges.
3. Main agent finalizes ownership boundaries using the explorer output.
4. Implementation `worker` edits only production code in its assigned modules.
5. Test `worker` edits only tests, fixtures, or test helpers. Do not allow it to change production code unless the main agent explicitly reassigns ownership.
6. Main agent integrates both outputs, resolves conflicts, and runs final verification.

Use this pattern when the test worker can start from existing behavior, public contracts, or explorer findings without waiting on every implementation detail.

## Failure Handling

If a child agent returns weak or ambiguous output:

- Narrow the ask and resend with `send_input`
- Ask for the missing artifact, not a full redo
- Pull the task back locally if clarification costs more than doing it yourself

If concurrent edits collide:

- Stop spawning more writers
- Re-read the touched files
- Integrate manually in the main agent

If the task no longer benefits from parallelism:

- Finish locally
- Close idle agents

## References

Open only when needed:

- Prompt templates and task briefs: `references/prompt-templates.md`
- Global orchestration contract: `<YOUR-CODEX-ROOT>/.codex/skills/.system/orchestration-contract.md`
