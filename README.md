# codex-sth

分享与迁移 Codex 技能目录。

## 一键部署本地 skill 到 Codex

克隆后可直接运行：

```bash
./scripts/deploy-skills.sh
```

默认行为：
- 将 `./skills/` 下所有 skill 目录部署到本机 Codex 目录下的 `skills/`
- 目标默认是 `~/.codex/skills`（可通过 `CODEX_HOME` 覆盖）
- 会覆盖同名目录，确保与仓库版本一致

可选参数：

```bash
./scripts/deploy-skills.sh --copy
./scripts/deploy-skills.sh --link
./scripts/deploy-skills.sh --help
```

- `--copy`：复制到目标目录（默认）
- `--link`：创建软链接，后续只要同步本仓库即可实时反映变更
- `--help`：查看完整参数说明

示例：

```bash
CODEX_HOME=/path/to/.codex ./scripts/deploy-skills.sh --link
```
