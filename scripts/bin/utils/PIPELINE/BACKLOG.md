# PIPELINE Backlog (Lite)

> 记录待处理需求和问题。替代正式的 PLAN 文档，由对话驱动。

## 主动需求（"我想到了什么"）
| ID | 描述 | 优先级 | 状态 | 计划Sprint |
|----|------|--------|------|-----------|
| A-01 | 长音频切分 → 并行 transcribe → 合并 | P1 | open | Sprint 2 |
| A-02 | Profile 模式：`monologue` / `voicelines` / `default` | P0 | open | Sprint 1 |
| A-03 | 可选：自动检测音频类型（启发式） | P2 | open | Sprint 3+ |

## 被动发现（"发现还有没做"）
| ID | 描述 | 来源阶段 | 关联文档 | 优先级 | 状态 | 计划Sprint |
|----|------|---------|---------|--------|------|-----------|
| D-01 | 验证"线性增长"假设是否成立 | 对话 | — | P0 | open | Sprint 1 |
| D-02 | MacBook Air 16GB 内存限制并行度上限 | 对话 | MODEL.md | P0 | open | Sprint 1 |
| D-03 | faster-whisper 内置 VAD 可能与外部切分冲突 | 对话 | — | P1 | open | Sprint 1 |
| D-04 | default profile 开启 VAD 导致与 Sprint 0 行为不兼容 | ATTACK | ATTACK-001 (F-01) | P0 | ✅ resolved | Sprint 1 |
| D-05 | 基准测试缺少 WER/准确率指标 | ATTACK | ATTACK-001 (F-02) | P0 | ✅ resolved | Sprint 1 |
| D-06 | M1 Air 长测试中热降频影响数据可比性 | ATTACK | ATTACK-001 (F-03/F-12) | P1 | ✅ resolved | Sprint 1 |
| D-07 | monologue 的 vad_threshold=0.3 无数据支撑 | ATTACK | ATTACK-001 (F-04/F-08) | P1 | ✅ resolved | Sprint 1 |
| D-08 | 边界条件未定义（<1s/纯静音/采样率不匹配） | ATTACK | ATTACK-001 (F-05) | P1 | ✅ resolved | Sprint 1 |
| D-09 | chunk_length=30 与 Sprint 2 外部切分嵌套未讨论 | ATTACK | ATTACK-001 (F-06) | P1 | ✅ resolved | Sprint 1 |
| D-10 | device="cpu" 一刀切，未验证 mps 可用性 | ATTACK | ATTACK-001 (F-15) | P2 | open | Sprint 1 |
| D-11 | 基准测试用 stream_loop 重复同一段过于人工化 | ATTACK | ATTACK-001 (F-11) | P2 | ✅ resolved | Sprint 1 |
| D-12 | Whisper 内部 30s chunk 是硬编码，外部 chunk_length 参数含义不同 | 源码审查 | DESIGN-001 §2.1 | P1 | ✅ resolved | Sprint 1 |
| D-13 | min_speech_duration_ms 源码默认值是 0，不是 250 | 源码审查 | DESIGN-001 §2.1 | P1 | ✅ resolved | Sprint 1 |
| D-14 | neg_threshold 参数（语音结束检测）未在原始设计中考虑 | 源码审查 | DESIGN-001 §2.1 | P2 | ✅ resolved | Sprint 1 |
| D-15 | condition_on_previous_text 影响上下文连贯性，切分后必须考虑 | 源码审查 | DESIGN-001 §3.2 | P1 | open | Sprint 2 |
| D-16 | voicelines 的 neg_threshold（0.40）在有 BGM 时可能导致语音段永不结束 | ATTACK | ATTACK-002 (N-03) | P2 | open | Sprint 1 |
| D-17 | 基准测试环境缺少电源状态记录（电池/插电） | ATTACK | ATTACK-002 (N-02) | P2 | open | Sprint 1 |

## 优先级定义
| 级别 | 定义 | Sprint关闭条件 |
|------|------|---------------|
| P0 | 阻塞性，核心路径不通 | 必须解决，否则Sprint不能关闭 |
| P1 | 高优先级，影响主要功能 | 可记录原因后延期 |
| P2 | 中优先级，影响体验 | 记录到Backlog |
| P3 | 低优先级，边缘场景 | 记录到Backlog |
