# ATTACK-002: Profile 参数矩阵 & 基准测试设计 — 二次审查（回流第 1 次后）

> 审查者: @attacker
> 审查目标: `PIPELINE/DESIGN/DESIGN-001_Profile_and_Baseline.md`（修复后版本）
> 审查日期: 2026-06-03
> 状态: ⏳ **有条件的 PASS（3 个待验证项，无阻塞性 P0）**
> 回流次数: 1/3

---

## 1. 审查摘要

DESIGN 团队已基于 ATTACK-001 的 11 项 findings（2 P0 + 4 P1 + 5 P2）完成了系统性的修复。源码事实核查（vad.py、transcribe.py、OpenAI 论文）的融入显著提升了设计的可信度。

### 总体评价

| 维度 | 评价 |
|------|------|
| 修复完整性 | ✅ 所有 P0/P1 findings 已修复，修复方案合理 |
| 源码事实利用 | ✅ 关键参数（chunk_length, min_speech_duration_ms, neg_threshold, condition_on_previous_text）均以源码事实为锚点 |
| 文档一致性 | ✅ ADR 记录完整，参数选择理由清晰，修复对照表透明 |
| 零信任余留 | ⚠️ 发现 1 个 P2 设计隐患 + 2 个 P2/P3 文档/流程不足 + 3 个需基准验证的假设 |

### 结论

**✅ 有条件的 PASS** — 无阻塞性 P0，建议在 CODE 阶段处理 1 个 P2 设计隐患。DESIGN 可流转到 CODE 阶段，但 ATTACK 标记以下条目到 Backlog 供 Sprint 关闭前验证：

| 优先级 | 问题 | 类型 | 要求 |
|--------|------|------|------|
| P1 | N-01: 30s 冷却有效性待验证 | 假设 | 基准测试中通过 therm_state 数据验证 |
| P2 | N-02: 电源状态未记录 | 文档补充 | 在环境声明中增加 power_source |
| P2 | N-03: voicelines BGM 场景下语音段永不结束风险 | 设计隐患 | CODE 阶段确认或增加 neg_threshold 的主动设置 |

---

## 2. 修复验证表

逐个检查 ATTACK-001 中 findings 的修复状态。

### 2.1 P0/P1 修复验证

| 编号 | 问题 | 严重程度 | 修复声明 | 验证结果 | 状态 |
|------|------|---------|---------|---------|------|
| **F-01** | default profile 开启 VAD 与向后兼容冲突 | **P0** | default 的 `vad_filter=False`，`vad_parameters=None` | §2.2 参数表 ✅、§2.3.1 理由 ✅、§3.4 示例 ✅、ADR-005 ✅、附录 A 映射 ✅。与 Sprint 0 源码 `model.transcribe(audio, language=lang)` 无 VAD 参数完全一致 | ✅ **已修复** |
| **F-02** | 基准测试缺少 WER 指标 | **P0** | 4.4 节新增 wer/cer，4.6 节验收标准 | §4.4 指标表包含 wer/cer（jiwer）✅、§4.5 JSON 示例包含 wer/cer ✅、Markdown 汇总表含 WER 列 ✅、验收标准 WER < 10% ✅、F-11 修复确保不同内容拼接，ground truth 可用 ✅ | ✅ **已修复** |
| **F-03** | M1 Air 降频影响数据可比性 | **P1** | 随机化测试顺序 + 30s 冷却 + therm_state 监测 | §4.4 伪代码 `random.shuffle(test_cases)` ✅、`time.sleep(30)` ✅、`therm_state` 指标（`pmset -g therm`）✅、`run_sequence` 指标 ✅。**30s 冷却对 M1 Air 被动散热是否足够需基准验证（见 N-01）** | ✅ **已修复** |
| **F-04** | monologue threshold=0.3 过于激进 | **P1** | 回调到 0.4，标注"待基准验证" | §2.2 参数表 0.4 ✅、§2.3.2 理由引用源码"lazy 0.5 is pretty good" ✅、标注"待基准验证" ✅、§6.4 假设表含对比验证计划 ✅ | ✅ **已修复** |
| **F-05** | 边界条件缺失 | **P1** | 新增第 7 章 | §7.1 <1s 音频 + warning ✅、§7.2 纯静音 + warning ✅、§7.3 采样率不匹配 + warning ✅、§7.4 多语言混合 ✅ | ✅ **已修复** |
| **F-06** | chunk 嵌套未讨论（Sprint 2 隐患）| **P1** | 6.2 节记录风险和缓解方案 | §6.2 嵌套架构图 ✅、3 个风险点 ✅、缓解方案 ✅、ADR-002 废弃 + 三档统一 `chunk_length=0` ✅。**§6.2 缓解方案措辞与当前状态有轻微不一致（见 N-05）** | ✅ **已修复** |

### 2.2 P2/P3 修复验证

| 编号 | 问题 | 严重程度 | 修复声明 | 验证结果 | 状态 |
|------|------|---------|---------|---------|------|
| **F-07** | voicelines threshold=0.6 遗漏轻声台词 | **P2** | 回调到 0.55 | §2.2 参数表 0.55 ✅、§2.3.2 理由 ✅、标注"待基准验证" ✅、§6.4 假设表含对比计划 ✅ | ✅ **已修复** |
| **F-08** | VAD 参数差异缺乏数据支撑 | **P2** | 间接修复（待基准验证标注 + 假设表） | 设计未直接回复此问题，但 F-04/F-07 的修复标注了"待基准验证"，§6.4 新增假设表。**这是正确做法——用 Sprint 1 的基线与 WER 数据来驱动** | ✅ **已覆盖** |
| **F-09** | CLI 不支持 `--profile help` | **P2** | 未修复 | §3.5 `--help` 输出已含 profile 描述，但 `--profile help` 未实现。这是 P2 非阻塞，可记录到 Backlog 后续 Sprint | ⏳ **未修复（可接受）** |
| **F-10** | `--model` 未做验证 | **P2** | 未修复 | DESIGN 未添加模型名校验。P2 非阻塞 | ⏳ **未修复（可接受）** |
| **F-11** | `-stream_loop` 重复同一段过于人工化 | **P2** | 改为多段不同内容拼接 | §4.3 使用多段 TTS 文本（Project Gutenberg）拼接 ✅、方案 B（LJSpeech）后备 ✅ | ✅ **已修复** |
| **F-12** | 缺少 CPU 温度/降频监测 | **P2** | 新增 therm_state 指标 | §4.4 `therm_state` ✅、`run_sequence` ✅ | ✅ **已修复** |
| **F-13** | 模型加载时间与转录时间未分离 | **P2** | 模型只加载一次，分离加载时间 | §4.4 伪代码: 模型加载一次 + `model_load_time` 记录 ✅ | ✅ **已修复** |
| **F-14** | language 字段声明误导 | **P2** | 修正描述，profile 不维护 language | §3.2 第 2 条：`--language` 显式指定时直接传入 WhisperModel，profile 不维护 ✅ | ✅ **已修复** |
| **F-15** | device="cpu" 一刀切，缺少 mps 对比 | **P2** | 未修复 | §6.3 声明 "mps 有兼容问题"。D-10 仍 open。P2 非阻塞 | ⏳ **未修复（里程碑后）** |
| **F-16** | temperature=0.0 无 fallback | **P3** | 未修复 | §2.2 参数表注明 "全部 greedy，后续再引入 fallback"。合理 | ⏳ **未修复（P3 合理）** |
| **F-17** | compression_ratio_threshold 未说明 | **P3** | 未修复 | P3 合理 | ⏳ **未修复（P3 合理）** |
| **F-18** | 多语言测试语料仅英文 | **P3** | 未修复 | P3，后续 Sprint 补充 | ⏳ **未修复（P3 合理）** |

### 2.3 源码事实审查点验证

DESIGN 团队声称查阅了源码，以下验证这些事实是否被正确应用：

| 源码事实 | DESIGN 中的处理 | 验证 | 状态 |
|---------|---------------|------|------|
| **Whisper 内部 30s chunk 是硬编码** | §2.1 确认 ✅、ADR-002 废弃 ✅、三档 `chunk_length=0` ✅ | 正确。faster-whisper 的 `chunk_length` 是外部 chunk 控制，Whisper 内部已是 30s 窗口 | ✅ **正确应用** |
| **min_speech_duration_ms 源码默认 = 0** | §2.1 确认 ✅、monologue=200 / voicelines=100 ✅ | 源码默认 0 意味着不过滤任何短语音。monologue=200 过滤极短噪音但保留正常短语音（"嗯""好"），voicelines=100 保留游戏短句。理由充分 | ✅ **正确应用** |
| **neg_threshold 默认 threshold - 0.15** | §2.1 确认 ✅，未显式设置 | **无需显式设置**，默认值跟随 threshold 自动调整。monologue: 0.4-0.15=0.25，voicelines: 0.55-0.15=0.40。**voicelines 的 0.40 在有 BGM 时存在风险（见 N-03）** | ⚠️ **基本正确，残留风险** |
| **condition_on_previous_text=True** | 未在 DESIGN 中讨论 | D-15 已记录为 Sprint 2 问题 ✅。Sprint 1 单音频串联转录不受影响 | ✅ **正确延期** |

---

## 3. 新发现的问题（二次审查 Zero-Trust）

### N-01 [P1] 30s 冷却间隔对 M1 Air 被动散热有效性待验证

**发现位置**: DESIGN §4.4 伪代码 `time.sleep(30)`

**描述**:
修复 F-03 时引入的 30s 冷却间隔是**启发式值**，未被验证对 M1 Air 被动散热有效。

M1 Air 的散热行为关键数据：

| 阶段 | 温度范围 | 达到时间 |
|------|---------|---------|
| 空闲 | 30-40°C | — |
| heavy load（large-v3 int8 ~100% CPU） | 80-90°C | 5-10 分钟 |
| 停负载后 30s 自然冷却 | 降至 ~65-75°C | 30s |
| 回到接近空闲 | 降至 ~40°C | 2-3 分钟 |

- 30s 冷却只能将芯片温度从 ~85°C 降至 ~70°C，仍处于**温热状态**
- 后续 15min/30min 测试直接从此温度起点开始，加剧热累积
- 随机化顺序已均匀分布热效应，但**绝对 RTF 值反映的是"预热后"而非"冷启动"性能**
- 36 次运行 × 30s = 18 分钟冷却开销，总测试时间约 2 小时

**影响**:
- 热效应对同 profile/时长 的三次重复仍有残余影响（第 3 次可能比第 1 次暖）
- RTF 稳定性验收标准（标准差 < 15%）可能被残余热效应影响
- 这不是修复缺陷，而是需要明确承认的**约束**

**建议**:
1. 基准测试运行后，根据 `therm_state` + `run_sequence` 数据做事后热效应分析
2. 验收标准补充：如果 `therm_state` 显示降频，在结果中标注 `[可能受降频影响]`
3. 不需要修改 DESIGN——这是 CODE 阶段实现时需要注意的约束
4. 记录到待验证假设表（§6.4 补充）

---

### N-02 [P2] 基准测试缺少电源状态记录

**发现位置**: DESIGN §4.7 环境声明

**描述**:
MacBook Air M1 在**电池供电**和**插电**两种状态下的 CPU 调度策略不同：
- 电池模式下 macOS 可能主动限制 CPU 峰值频率以延长续航
- 即使插电，如果电池电量低，macOS 也可能降频
- 如果用户在不同电源状态下复现基准测试，结果不可比

当前 §4.7 环境声明包含 hostname、cpu、ram、os、python、faster_whisper 版本，但**缺少电源状态**。

**影响**:
- 基准测试的可复现性降低
- 如果 SPRINT 2 基于 SPRINT 1 的基线数据做设计决策，电源状态差异可能导致误判

**建议**:
1. 在环境声明中增加 `power_source` 字段：`"battery"` / `"ac_power"`
2. 在基准测试脚本启动时自动检测：`pmset -g batt` 解析
3. 验收标准补充：基准测试应在插电状态下进行

---

### N-03 [P2] voicelines 的 neg_threshold 在有 BGM 时可能阻止语音段结束

**发现位置**: DESIGN §2.3.2 voicelines threshold=0.55 + §2.1 neg_threshold 默认值

**描述**:
Silero-VAD 的工作机制使用迟滞比较器：

| 参数 | voicelines 值 | 含义 |
|------|--------------|------|
| `threshold` | 0.55 | VAD 信心 > 0.55 → 语音开始 |
| `neg_threshold` | **0.40**（默认 threshold - 0.15） | VAD 信心 < 0.40 → 语音结束 |

当音频有持续 BGM/环境音时：

```
VAD 信心曲线:
1.0 ┤
    │    ┌───┐         BGM 产生持续 0.40-0.50 的信心值
0.5 ┤────┤   ├────────────────────────────── threshold=0.55
0.4 ┤────┤   ├────────────────────────────── neg_threshold=0.40
    │    │   │
0.0 ┤────┴───┴──────────────────────────────
         ↑语音开始          ↑语音永不结束？
```

**关键问题**: 如果 BGM/音效使 VAD 信心值维持在 0.40-0.50 区间（高于 neg_threshold 但低于 threshold），**语音段一旦开始就永远不会结束**，直到音频结束或 silent 区域使信心值降至 0.40 以下。

**影响范围**:
- ❗ **严重情况**: 持续 BGM 的游戏音频 → 整个音频被标记为单个语音段 → `vad_min_silence_ms` 和 `segment_count` 失效
- ⚠️ **典型情况**（角色台词间有停顿）: BGM 在停顿处降至 < 0.40 → 正常分段。但轻声 BGM 可能仍保持 0.35-0.45，在边界处产生模糊
- ✅ **无 BGM 场景**: 影响为零

**建议**:
1. **短期（CODE 阶段）**: 在 voicelines 的 `vad_parameters` 中**显式设置** `neg_threshold=0.35`（比默认 0.40 降低 0.05），给 BGM 场景更多余量。或保持默认但在文档中标注此风险
2. **中期（基准测试）**: 在测试语料中加入一段带 BGM 的合成音频（TTS + 背景音乐混合），验证 voicelines 的 segment 行为
3. **长期（Sprint 2+）**: 考虑对 voicelines 引入 `max_speech_duration_s` 约束，防止单段无限延长
4. 此问题切换到 `vad_parameters` 的显式设置即可解决，建议在 CODE 阶段处理

---

### N-04 [P2] `max_speech_duration_s` 未设置（默认 inf）— 长语音段保护缺失

**发现位置**: DESIGN §2.1 源码事实 + 附录 A vad_parameters

**描述**:
Silero-VAD 的 `max_speech_duration_s` 默认值为 `inf`（无限）。当 `neg_threshold` 不够灵敏（如 N-03 场景），或连续说话时间极长时，单个 VAD 语音段可能对应数十秒甚至数分钟的连续音频。

**这与 Whisper 的内部 30s 窗口的关系**:
- Whisper 内部 30s 窗口：模型层面的切分，不影响 VAD 的 segment 计数
- VAD segment：影响 `segment_count` 指标和后续的并行切分粒度
- 如果 VAD 输出一个 5 分钟的 segment，内部仍由多个 30s 窗口处理，但 `segment_count` 只计 1

**影响**:
- `segment_count` 指标在 monologue（连续说话）场景下可能偏低——一个长段落只计 1 个 segment
- 但这不是 bug，是设计特征——monologue 本就不预期细粒度分段
- Sprint 2 如果依赖 `segment_count` 作为并行切分的粒度参考，可能被误导

**建议**:
1. 在 §6.4 待验证假设中增加：`segment_count` 在 monologue 长音频场景的实际分布
2. 不修改当前设计，Sprint 2 引入外部切分时需重新考虑此参数
3. 此问题的优先级实际低于 N-03，可合并处理

---

### N-05 [P3] 6.2 节缓解方案措辞与当前状态不一致

**发现位置**: DESIGN §6.2

**描述**:
§6.2 缓解方案写道：

> Sprint 2 设计时，对 monologue profile 考虑 `chunk_length=0`

但 ADR-002 已废弃 `chunk_length=30`，且 §2.2 参数表显示**三档统一已是 `chunk_length=0`**。所以 Sprint 2 不需要再"考虑"——这已是当前基线。

**影响**:
- 文档轻微不一致，可能误导 Sprint 2 的设计者认为 `chunk_length=0` 是"未来选项"而非当前状态
- 对设计正确性无影响

**建议**:
将措辞改为：

> Sprint 1 已统一设置 `chunk_length=0`（三档），Sprint 2 的外部切分在此基线之上工作，无 chunk 嵌套冲突。

---

## 4. 图表审查

DESIGN 目录下仍未创建 PlantUML 图表文件（`PIPELINE/DESIGN/DIAGRAM-*.puml` 不存在）。

架构图仍以 ASCII 图嵌入在 §1。该 ASCII 图与设计描述一致，未发现误导内容。

**建议**: 为 CODE 阶段保留此 ASCII 图即可，PlantUML 图可在 Sprint 2 引入并行架构时补充。

---

## 5. Backlog 联动更新建议

| 新发现 | 建议 Backlog ID | 优先级 | 关联原有条目 |
|--------|----------------|--------|-------------|
| N-01: 30s 冷却有效性待验证 | → D-01（扩展） | P1 | D-01 "线性增长假设验证"新增子项 |
| N-02: 电源状态记录 | — | P2 | 独立新条目 |
| N-03: voicelines neg_threshold BGM 风险 | → D-03（扩展） | P2 | D-03 "VAD 与外部切分冲突"扩展 |
| N-04: max_speech_duration_s 未设置 | — | P2 | 可合并到 N-03 处理 |
| N-05: 措辞不一致 | — | P3 | 文档微调 |

---

## 6. 审查结论

### ✅ 有条件的 PASS

**DESIGN-001 修复版本可以通过审查，进入 CODE 阶段。** 理由：

1. **所有 P0 问题已修复**：向后兼容性（F-01）和 WER 指标（F-02）的修复方案坚实且与源码事实一致
2. **所有 P1 问题已修复**：M1 降频策略（F-03）、VAD 阈值回调（F-04）、边界条件（F-05）、chunk 嵌套风险（F-06）均有合理的解决方案
3. **源码事实被正确利用**：chunk_length 修正、min_speech_duration_ms 重新校准、neg_threshold 默认值保持

### 条件

以下 3 个**非阻塞条件**需在 Sprint 关闭前满足：

| # | 条件 | 验证方式 | 负责方 |
|---|------|---------|--------|
| C-01 | 基准测试运行后验证热效应分布 `therm_state` 数据可解释 RTF 变化 | 运行 36 次基准测试后分析 therm_state 与 RTF 的相关性 | CODE + TEST |
| C-02 | CODE 阶段确认 or 处理 voicelines 的 neg_threshold BGM 风险（N-03）| CODE 阶段在 `vad_parameters` 中显式设置 `neg_threshold` 或保持默认 + 文档说明 | CODE |
| C-03 | 基准测试环境声明包含 `power_source` 字段（N-02）| CODE 阶段在基准测试脚本中自动检测 | CODE |

### 回流决策

| 维度 | 值 |
|------|-----|
| 回流次数 | 1/3 |
| 是否再次回流 | **否** — 无 P0 阻塞问题，有条件的 PASS |
| 下一阶段 | → **CODE** |
| ATTACK 关闭条件 | C-01/02/03 在 Sprint 关闭前验证 |

### 一句话总结

> DESIGN 团队在回流中扎实地修复了所有严重问题，源码事实核查增强了设计的可信度。二次审查发现的主要是新细节（neg_threshold BGM 风险、电源状态遗漏），这些是 CODE 阶段可处理的，不需要再回流 DESIGN。
