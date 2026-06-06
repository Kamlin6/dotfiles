# PIPELINE Status (Lite)

> 状态机：供所有工程线 Agent 启动前读取。

## 当前Sprint
`Sprint 1 — 基线摸底 & Profile 定义`

## Sprint启动检查清单
- [x] 上一Sprint状态为 ✅（首个Sprint，跳过）
- [x] 上一Sprint所有P0条目已关闭（首个Sprint，跳过）

## 阶段状态
| 阶段 | 状态 | 回流次数/上限 | 关键结论 | 最后更新 |
|------|------|--------------|---------|----------|
| PLAN | ✅ | — | 对话已确认需求边界 | 2026-06-03 |
| DESIGN | ✅ | 1/3 | 回流修复完成，ATTACK-002 二次审查有条件的 PASS | 2026-06-03 |
| ATTACK | ✅ | 1/3 | 二次审查完成：无 P0 阻塞，3 个条件需 CODE 阶段验证 | 2026-06-03 |
| CODE | ⏳ | — | — | — |
| 验证 | ⏳ | — | — | — |
| 归档 | ⏳ | — | — | — |

## 回流记录（当前Sprint）
| 从 | 到 | 原因 | 时间 |
|----|----|------|------|
| ATTACK | DESIGN | P0: default profile 开启 VAD 与向后兼容原则冲突；P0: 基准测试缺少 WER 指标 | 2026-06-03 |
| ATTACK-002 | PASS | 二次审查通过，有条件的 PASS → CODE | 2026-06-03 |
## 本Sprint Backlog摘要
| ID | 类型 | 描述 | 优先级 | 状态 |
|----|------|------|--------|------|
| A-02 | 主动 | Profile 模式：monologue / voicelines / default | P0 | open |
| D-01 | 被动 | 验证"线性增长"假设是否成立 | P0 | open |
| D-02 | 被动 | MacBook Air 16GB 内存限制并行度上限 | P0 | open |
| D-03 | 被动 | faster-whisper 内置 VAD 可能与外部切分冲突 | P1 | open |

## 阻塞规则
- `DESIGN` 依赖 `PLAN ✅`
- `ATTACK` 依赖 `DESIGN ✅`
- `CODE` 依赖 `ATTACK ✅`
- `验证` 依赖 `CODE ✅`
- `归档` 依赖 `验证 ✅`
- 下一Sprint启动依赖 `上一Sprint ✅` + `所有P0已关闭`

## 手动解锁
如需跳过阻塞，手动将对应阶段状态改为 `✅` 并填写摘要。解锁即承担返工风险。

## 当前Sprint文档清单
| 文档 | 位置 | 状态 |
|------|------|------|
| DESIGN | `PIPELINE/DESIGN/` | ✅ |
| ATTACK | `PIPELINE/ATTACK/` | ✅ |
| WP | `PIPELINE/PACKETS/` | ⏳ |
| ARCHIVE | `PIPELINE/ARCHIVE/` | ⏳ |
