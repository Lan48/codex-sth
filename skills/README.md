# skills 目录说明

本目录用于存放可复用的 Codex Skill。当前仓库收录：

- `autonomous-project-driver/`
- `multi-agent-orchestrator/`

## 目录说明

### autonomous-project-driver

- 目标：持续推进当前项目，优先检测 `.planning/ROADMAP.md`，存在时优先路由到 `\$gsd-autonomous`。
- 适用场景：希望 Codex 避免逐步汇报、需要连续推进直到遇到人工决策点的情况。
- 关键文件：
  - `SKILL.md`：核心行为规则与路由策略
  - `agents/openai.yaml`：UI 展示与默认提示词

### multi-agent-orchestrator

- 目标：在任务复杂、可并行分工时，由主代理驱动分解并发起轻量子代理并行执行。
- 适用场景：需要多角色协同、子任务拆分与并行推进的任务。
- 关键文件：
  - `SKILL.md`：并行编排决策与执行规则
  - `agents/openai.yaml`：UI 展示与默认提示词
  - `references/prompt-templates.md`：子代理提示模板

## 使用约定

- 目录名使用小写连字符（hyphen-case），例如：`my-skill-name/`。
- 变更默认先记录到 `SKILL.md` 再同步 `agents/openai.yaml`。
- 每个 skill 以最小必要上下文原则设计，避免把无关文档混进目录。
- 添加新技能时，优先更新本 `skills/README.md`，保持仓库可读性。

## 一键部署

本仓库提供脚本快速部署：

```bash
bash ./scripts/deploy-skills.sh
```

- 部署目标默认是 `$CODEX_HOME/skills`，`CODEX_HOME` 默认值 `~/.codex`。
- `--copy`：复制所有 skill 到目标目录（默认）。
- `--link`：创建/更新软链接，便于本地持续同步。
- `--help`：查看完整帮助。
