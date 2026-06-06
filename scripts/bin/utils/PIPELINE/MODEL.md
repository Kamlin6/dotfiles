# PIPELINE 概念模型（Lite 版）

> 核心设计哲学：**Zero-Trust 上游 → 平滑执行下游**

## 分界线

```
阶段线：   PLAN(对话) → DESIGN → ATTACK → CODE → 验证 → 归档
                           ↑___________↑
                              Zero-Trust
                          （被攻击的对象）
```

### Zero-Trust Zone

覆盖范围：DESIGN ↔ ATTACK

- 设计文档是可疑的，直到被审查证明正确
- ATTACK 以 Zero-Trust 红队思维审查 DESIGN
- 回流上限 3 次/Sprint，超限暂停 Sprint 回到 PLAN 重新评估

### 执行区

覆盖范围：CODE → 验证 → 归档

- 输入已验证，执行流不应被打断
- 发现问题 → 记录到 Backlog，不打断当前 Sprint

## 回流规则

回流仅在 Zero-Trust Zone 内（DESIGN ↔ ATTACK），上限 3 次/Sprint。

## 与 Standard 版的差异

| 维度 | Standard | Lite |
|------|---------|------|
| Zero-Trust 范围 | SPEC ↔ ATTACK ↔ DESIGN | DESIGN ↔ ATTACK |
| 回流上限 | 5次/阶段/Sprint | 3次/Sprint |
| 下游管控 | TEST → CODE 不打断 | CODE → 验证不打断 |
| 归档方式 | 独立的 ARCHIVE_*.md | ARCHIVE/ 目录 |

## Backlog 数据流

- 写入者：attacker（审查发现）、coder（边界遗漏）
- 读取者：对话阶段（下一 Sprint 规划）
