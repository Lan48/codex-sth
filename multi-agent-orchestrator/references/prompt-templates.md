# Prompt Templates

Use these templates as starting points. Replace placeholders with real paths, goals, and done conditions before spawning an agent.

## Quick Selection

- Use the read-only template when you need analysis, file discovery, impact mapping, or architecture tracing.
- Use the worker template when the write scope is narrow and ownership is clear.
- Use the test-worker template when one child should own only tests, fixtures, or test helpers.
- Use the verifier template when the implementation stays local but you want an independent pass on risks, tests, or regressions.
- Use the follow-up template when the child already did useful work and only needs one more bounded step.

## Read-Only Explorer Template

```text
你负责只读分析，不要改代码。

目标：
- {goal}

范围：
- 只看这些目录或文件：{allowed_scope}
- 不要展开到无关模块：{forbidden_scope}

输出：
- 列出涉及文件
- 说明当前行为
- 说明风险点或不确定点
- 给出建议的下一步

额外要求：
- 如果证据不足，明确写出缺口，不要猜
- 不要提出大而空的重构建议
```

## Code Worker Template

```text
你负责一个边界清晰的实现子任务。

目标：
- {goal}

所有权：
- 只能修改：{allowed_write_scope}
- 不要碰：{forbidden_scope}

协作约束：
- 你不是唯一在代码库里工作的人
- 不要回滚不是你做的改动
- 如果遇到并发改动，基于现状调整实现

完成标准：
- 满足这些行为要求：{done_condition}
- 如有测试，补上或更新与本改动直接相关的测试

返回格式：
- 改了哪些文件
- 关键实现点
- 跑了哪些验证
- 还剩什么风险
```

## Test Worker Template

```text
你负责测试补充，不负责生产代码实现。

目标：
- {goal}

所有权：
- 只能修改：{allowed_test_scope}
- 不要碰任何生产代码文件：{forbidden_prod_scope}

协作约束：
- 你不是唯一在代码库里工作的人
- 不要回滚不是你做的改动
- 不要为了让测试通过而顺手修改生产代码
- 如果测试暴露实现问题，只记录证据和最小修复建议

完成标准：
- 补上与当前改动直接相关的测试
- 明确说明覆盖了哪些路径，哪些路径还没覆盖

返回格式：
- 改了哪些测试文件
- 覆盖了哪些场景
- 没覆盖的风险点
- 是否发现需要主 agent 或实现 worker 处理的问题
```

## Verifier Template

```text
你负责独立验证，不负责大改实现。

检查目标：
- {goal}

重点检查：
- 回归风险
- 缺失测试
- 边界条件
- 文档或注释是否与实现一致

输出：
- 发现的问题
- 每个问题的证据
- 建议的最小修复方向

如果没有发现问题，也要写明残余风险和未验证项。
```

## Follow-Up Template

```text
在你刚才结果的基础上，只继续做这一小步：

- {next_step}

不要重复之前已经完成的部分。
输出只保留：
- 新增改动
- 新增验证
- 是否还有阻塞
```

## Main-Agent Integration Checklist

Use this checklist before replying to the user:

1. Re-read the files touched by child agents.
2. Confirm ownership boundaries were respected.
3. Resolve overlapping edits in the main agent.
4. Run the highest-value final verification centrally.
5. Close agents you no longer need.
6. Summarize outcome, verification, and residual risk.
