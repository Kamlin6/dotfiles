# PACKETS — 工作包（Work Packets）

存放由 Designer 生成的执行工单，供 Coder 消费。

每个 Work Packet 包含：
- 目标、背景上下文、允许/禁止修改的文件
- 输入/输出约束、验收命令、回滚方式、WP 等级

## 命名规范
- `WP-<序号>_<主题>.md`
- 例：`WP-001_LoginAPI.md`
