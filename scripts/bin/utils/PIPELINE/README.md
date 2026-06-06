# PIPELINE — Lite 工程流水线（简化版）

> 轻量级工程交付流水线，保留核心质量控制阶段，跳过冗余文档开销。

## 目录结构

```
PIPELINE/
├── README.md        ← 本文件：总纲 + WP 定义 + 回流规则
├── STATUS.md        ← 状态机：Sprint标识、阶段状态、回流计数、Backlog摘要
├── MODEL.md         ← 概念模型：Zero-Trust Zone 分界线
├── BACKLOG.md       ← 需求与问题池：主动需求 + 被动发现
├── DESIGN/          ← 设计文档（架构决策 + 接口定义，合并 SPEC）
├── ATTACK/          ← 攻击审查文档（Zero-Trust 审查报告）
├── PACKETS/         ← 工作包（Work Packets，供 Coder 执行的工单）
└── ARCHIVE/         ← 归档（Sprint 完结后移入）
```

## 执行流程（简化版）

```
PLAN(对话) → DESIGN → ATTACK → CODE → 验证(手动) → 归档
```

| 阶段 | 方式 | 产出 | 前置依赖 |
|------|------|------|---------|
| PLAN | 对话 + BACKLOG.md | 需求梳理、边界定义 | — |
| DESIGN | @designer | 架构设计 + 接口定义 + WP | PLAN ✅ |
| ATTACK | @attacker | Zero-Trust 审查报告 | DESIGN ✅ |
| CODE | @coder | 代码 + 配置 | ATTACK ✅ |
| 验证 | 手动 / 脚本 | 功能验收 | CODE ✅ |
| 归档 | 手动 | STATUS 快照 + 文档移入 ARCHIVE/ | 验证 ✅ |

## Sprint 定义

- Sprint 按**核心功能**划分，不按时间
- 每个 Sprint 包含完整的简化流程
- Sprint 启动条件：上一 Sprint ✅ + 所有 P0 已关闭
- Sprint 关闭条件：归档完成 + 无 P0 遗留

## 回流规则

回流仅在 DESIGN ↔ ATTACK 之间发生。

| 触发条件 | 回流路径 | 上限 | 超限处理 |
|---------|---------|------|---------|
| 设计被审查发现问题 | 从 ATTACK 回到 DESIGN | 3次/Sprint | 暂停 Sprint，重新评估需求 |
| 发现新需求 | 记录到 Backlog | — | 下一 Sprint 处理 |
| 编码中发现设计遗漏 | 记录到 Backlog，继续编码 | — | 下一 Sprint 处理 |

## Backlog

- **主动需求**："我想到了什么"
- **被动发现**："发现还有没做"
- 优先级：P0（阻塞）/ P1 / P2 / P3
- P0 未解决 → Sprint 不能关闭

## WP（Work Packet）定义

1 WP = 标准 Agent 调用在单轮交互内可完成的工作量。

| 等级 | WP 数 | 典型场景 | Agent 调用策略 |
|------|-------|---------|---------------|
| WP-1 | 1 | 实现一个独立函数、写一个接口定义 | 单 Coder 调用 |
| WP-3 | 2-3 | 模块级改动（实现 + 测试 + 文档） | Coder → 手动验证 |
| WP-5 | 5-7 | 跨模块功能 | Designer → Coder → 手动验证 |
| WP-8+ | 8+ | 系统级重构 | 建议先拆解为多个 WP-5 的子项 |

## 概念模型

详见 `MODEL.md`。核心设计哲学：

- **Zero-Trust Zone**（DESIGN ↔ ATTACK）：设计文档是可疑的，必须经过审查
- 回流仅在 DESIGN ↔ ATTACK 之间发生，上限 3 次/Sprint
- CODE 阶段发现问题 → 记录到 Backlog，不打断当前执行

## 什么时候用 Standard 版？

| 场景 | 推荐 |
|------|------|
| 个人小项目 / 小 Sprint | **Lite（当前）** |
| 团队项目 / 大功能 | Standard |
| 安全敏感 / 生产环境 | Standard + 额外审查 |
| 接口复杂 / 多模块交互 | Standard（SPEC 不可省） |

## 通用规则

1. **STATUS 前置检查** — 所有工程线 Agent 启动前必须读取 `PIPELINE/STATUS.md`
2. **手动解锁** — 如需跳过阻塞，手动修改 STATUS.md，解锁即承担返工风险
3. **Zero-Trust** — ATTACK 阶段对所有上游文档持怀疑态度
4. **Work Packet** — DESIGN 阶段输出工单文件（存放于 PACKETS/），供 Coder 直接执行
5. **验证** — CODE 完成后手动验证或运行脚本，通过后归档
