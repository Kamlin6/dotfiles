# DESIGN-001: Profile 参数矩阵 & 基准测试基线设计

> Sprint 1 — 基线摸底 & Profile 定义
> 状态: ⏳ 待 ATTACK 二次审查（回流第 1 次）
> 最后更新: 2026-06-03
> 回流原因: ATTACK-001 发现 2 P0 + 4 P1

---

## 目录

1. [架构总览](#1-架构总览)
2. [Profile 参数矩阵](#2-profile-参数矩阵)
3. [CLI 接口设计](#3-cli-接口设计)
4. [基准测试脚本设计](#4-基准测试脚本设计)
5. [架构决策记录 (ADR)](#5-架构决策记录-adr)
6. [扩展点 & 约束](#6-扩展点--约束)
7. [边界条件](#7-边界条件)

---

## 1. 架构总览

**一句话**: 在现有 `transcribe` 单文件脚本上叠加 Profile 抽象层，将参数配置从硬编码解耦为可命名配置集；同时建立基准测试框架量化 Profile 效果，为 Sprint 2 并行切分提供基线数据。

```
                          ┌─────────────────────────┐
                          │       CLI (argparse)      │
                          │  --profile  --model  --lang │
                          └──────────┬──────────────┘
                                     │
                          ┌──────────▼──────────────┐
                          │    Profile 参数解析器      │
                          │  default / monologue     │
                          │  / voicelines            │
                          │  (参数矩阵 → kwargs)      │
                          └──────────┬──────────────┘
                                     │
                          ┌──────────▼──────────────┐
                          │   faster-whisper 调用层    │
                          │  WhisperModel(...)        │
                          │  model.transcribe(...)    │
                          └──────────┬──────────────┘
                                     │
                          ┌──────────▼──────────────┐
                          │      输出层 (stdout +    │
                          │      .txt 文件)          │
                          └─────────────────────────┘
```

### 设计原则

| 原则 | 说明 |
|------|------|
| **向后兼容** | 不传 `--profile` 时行为与 Sprint 0 完全一致（`vad_filter=False`） |
| **显式优先** | Profile 参数覆盖必须对用户透明，`--help` 可查 |
| **数据驱动** | 所有参数默认值来自源码默认值，微调值标注"待基准验证" |
| **M1 优先** | 参数值上限以 MacBook Air 16GB 7 核 M1 为约束 |

---

## 2. Profile 参数矩阵

### 2.1 源码事实核查

在定义参数矩阵前，先记录从源码中确认的事实：

| 事实 | 来源 | 影响 |
|------|------|------|
| Whisper 内部按 30s chunk 处理 | OpenAI 论文："Input audio is split into 30-second chunks" | `chunk_length` 参数在 faster-whisper 中是**外部 chunk 长度**，不是 Whisper 内部窗口 |
| `VadOptions.threshold` 默认 0.5 | vad.py 源码 | 三档以此为基准微调 |
| `VadOptions.min_speech_duration_ms` 默认 **0** | vad.py 源码 | 不是 250，设为 >0 会丢弃短语音段 |
| `VadOptions.neg_threshold` 默认 `threshold - 0.15` | vad.py 源码 | 用于检测语音结束，影响 segment 边界 |
| `VadOptions.max_speech_duration_s` 默认 `inf` | vad.py 源码 | 无上限，长语音段不会被强制切分 |
| 源码注释："lazy 0.5 is pretty good for most datasets" | vad.py 源码 | 微调范围应在 0.4-0.6，0.3 过于激进 |

### 2.2 参数总表

| 参数 | 位置 | default | monologue | voicelines | 说明 |
|------|------|---------|-----------|------------|------|
| `model_size` | WhisperModel | `large-v3` | `large-v3` | `large-v3` | Sprint 1 三档均用大模型 |
| `device` | WhisperModel | `cpu` | `cpu` | `cpu` | mps 有兼容性问题，统一 cpu |
| `compute_type` | WhisperModel | `int8` | `int8` | `int8` | int8 内存占用最低 |
| `vad_filter` | transcribe | **`False`** | `True` | `True` | **修复 F-01**: default 不开 VAD，与 Sprint 0 一致 |
| `vad_threshold` | vad_parameters | — | `0.4` | `0.55` | **修复 F-04/F-07**: 从 0.3/0.6 回调到 0.4/0.55 |
| `vad_min_silence_ms` | vad_parameters | — | `1000` | `1500` | **修复**: monologue 从 600 调到 1000，避免过度切分 |
| `vad_speech_pad_ms` | vad_parameters | — | `300` | `400` | 微调 |
| `vad_min_speech_ms` | vad_parameters | — | `200` | `100` | **修复**: 从 500/100 改为 200/100，不过滤正常短语音 |
| `beam_size` | transcribe | `5` | `5` | `5` | Sprint 1 统一 5 |
| `best_of` | transcribe | `5` | `5` | `5` | 同上 |
| `temperature` | transcribe | `0.0` | `0.0` | `0.0` | 全部 greedy，后续再引入 fallback |
| `compression_ratio_threshold` | transcribe | `2.4` | `2.4` | `2.4` | 保持 faster-whisper 默认 |
| `chunk_length` | transcribe | `0` | `0` | `0` | **修复**: 三档统一为 0，Whisper 内部已是 30s 窗口 |
| `language` | transcribe | `None(自动)` | `None(自动)` | `None(自动)` | `--language` 显式指定时直接传入，profile 不维护此字段 |

### 2.3 参数选择理由

#### 2.3.1 vad_filter — 向后兼容修复（F-01）

| Profile | 值 | 选择理由 |
|---------|-----|---------|
| **default** | `False` | **与 Sprint 0 完全一致**。当前代码没有 VAD，default 必须保持零变更 |
| **monologue** | `True` | 干净语音，VAD 可跳过自然停顿，减少 segment 数量 |
| **voicelines** | `True` | 有 BGM/音效，VAD 可过滤非语音段 |

#### 2.3.2 vad_threshold（语音检测灵敏度）

| Profile | 值 | 选择理由 |
|---------|-----|---------|
| **monologue** | `0.4` | **待基准验证**。从 0.3 回调到 0.4，避免捕获呼吸/咂嘴声（F-04）。源码说 "lazy 0.5 is pretty good"，0.4 比默认略敏感但不极端 |
| **voicelines** | `0.55` | **待基准验证**。从 0.6 回调到 0.55，避免遗漏轻声台词（F-07）。比默认略保守但不极端 |

#### 2.3.3 vad_min_silence_duration_ms（多长静音算断点）

| Profile | 值 | 选择理由 |
|---------|-----|---------|
| **monologue** | `1000` | 从 600 调到 1000。600ms 过于激进，会把喘气当断句。1000ms 在语义完整和不丢失边界间平衡 |
| **voicelines** | `1500` | 从 300 调到 1500。300ms 会把 BGM 间隙当断点，1500ms 更保守 |

#### 2.3.4 vad_min_speech_duration_ms（最短语音段）

| Profile | 值 | 选择理由 |
|---------|-----|---------|
| **monologue** | `200` | 从 500 调到 200。500 会丢弃正常短语音（如 "嗯""好"）。源码默认是 0，200 只过滤极短噪音 |
| **voicelines** | `100` | 保持 100。游戏角色语音可能很短（"哼""啊""yes!"） |

#### 2.3.5 chunk_length — 移除（Whisper 内部已处理）

| Profile | 值 | 选择理由 |
|---------|-----|---------|
| **三档统一** | `0` | **修复**: Whisper 论文明确说 "Input audio is split into 30-second chunks"，这是硬编码的架构设计。faster-whisper 的 `chunk_length` 参数是外部 chunk 长度，Sprint 1 不需要设置 |

**ADR-002 已废弃**（见第 5 章）。

#### 2.3.6 M1 MacBook Air 约束检查

| 约束 | 检查结果 |
|------|---------|
| 模型加载内存 | large-v3 int8 ≈ 2.1~2.5 GB（实测待验证） |
| 单次推理峰值 | Whisper 内部 30s chunk ≈ 3~4 GB |
| 空闲系统内存 | macOS 通常占用 2~3 GB |
| 安全余量 | 2.5 + 4 + 3 = 9.5 GB < 16 GB ✅ |
| 并行限制 | Sprint 1 不涉及并行，Sprint 2 预计最多 2~3 路 |

---

## 3. CLI 接口设计

### 3.1 新参数 `--profile`

```
positional arguments:
  audio_path            音频文件路径

optional arguments:
  --profile {default,monologue,voicelines}
                        音频类型 profile。影响 VAD 参数和 chunk 策略。
                        （默认: default）
  --model MODEL         模型标识（默认 large-v3，Systran 版）
  --language LANG       语言代码，不指定则自动检测
```

### 3.2 参数优先级规则

```
显式指定参数  >  Profile 参数 >  faster-whisper 默认值
```

具体规则：

1. 如果用户传了 `--model`，则无视 profile 中的 `model_size`
2. `--language` 显式指定时直接传入 WhisperModel，profile 不维护语言字段（**修复 F-14**）
3. 如果用户既没传 `--profile` 也没传 `--model`/`--language` → 完全用 default profile（行为同 Sprint 0）
4. 如果用户传了 `--profile` 又传了 `--model` → profile 决定 VAD 参数，model 用显式值

### 3.3 错误处理

| 场景 | 行为 |
|------|------|
| `--profile invalid` | `argparse.ArgumentTypeError` + 列出合法值 |
| `--profile monologue --language ja` | 正常，language 直接传入 WhisperModel |
| `--profile voicelines` + 30min 音频 | 正常，VAD 处理长音频没问题 |
| 不传任何参数 | 完全向后兼容，行为同 Sprint 0（`vad_filter=False`） |

### 3.4 示例用法

```bash
# 完全向后兼容（等价于 --profile default，不开 VAD）
transcribe meeting.mp3

# 显式指定 profile（启用 VAD）
transcribe talk.mp3 --profile monologue
transcribe line.wav --profile voicelines

# profile + 覆盖模型
transcribe talk.mp3 --profile monologue --model large-v3

# profile + 指定语言
transcribe japanese.mp3 --profile monologue --language ja

# 全参数
transcribe game.wav --profile voicelines --model medium --language en
```

### 3.5 `--help` 输出（设计预期）

```
usage: transcribe [-h] [--profile {default,monologue,voicelines}]
                  [--model MODEL] [--language LANGUAGE]
                  audio_path

转录音频文件为纯文本

positional arguments:
  audio_path            音频文件路径

options:
  -h, --help            show this help message and exit
  --profile {default,monologue,voicelines}
                        音频类型 profile。影响 VAD 阈值、chunk 大小等。
                        default: 通用（与当前版本行为一致，不开 VAD）
                        monologue: 单人分享/观点（干净语音，启用 VAD）
                        voicelines: 游戏角色语音（短句，BGM 混叠，启用 VAD）
                        （默认: default）
  --model MODEL         模型标识（默认 large-v3，Systran 版）
  --language LANGUAGE   语言代码，不指定则自动检测
```

---

## 4. 基准测试脚本设计

### 4.1 设计目标

1. **量化** 不同 Profile 在不同时长音频上的 RTF（实时因子）、峰值内存、segment 数量
2. **验证** 线性增长假设（是否 2× 时长 → 2× 时间 + 2× 峰值内存）
3. **发现** 16GB M1 的内存瓶颈点（在哪一时长开始 swap）
4. **数据输出** 给 Sprint 2 的并行切分设计提供基线

### 4.2 测试矩阵

| 维度 | 取值 |
|------|------|
| Profile | `default` / `monologue` / `voicelines` |
| 时长 | `1min` / `5min` / `15min` / `30min` |
| 重复次数 | 每个组合 **3 次**（取中位数，消除冷启动/系统负载波动） |
| 总计运行次数 | 3 profiles × 4 durations × 3 repeats = **36 次** |

### 4.3 测试音频生成

#### 方案 A：合成语音（首选，可复现）

使用 `edge-tts`（免费、高质量、支持多语言）生成语音，再用 `ffmpeg` 拼接。

```bash
# 生成多段不同的 1min 素材（约 150 词英文），避免同一段重复（修复 F-11）
edge-tts --text "$(cat test_corpus_part1.txt)" --voice en-US-JennyNeural --write-media test_part1.wav
edge-tts --text "$(cat test_corpus_part2.txt)" --voice en-US-JennyNeural --write-media test_part2.wav
edge-tts --text "$(cat test_corpus_part3.txt)" --voice en-US-JennyNeural --write-media test_part3.wav

# 拼接为更长音频（不同内容拼接，模拟真实变化）
ffmpeg -i test_part1.wav -i test_part2.wav -i test_part3.wav -filter_complex "concat=n=3:v=0:a=1" test_3min.wav
```

**测试语料准备**：从 Project Gutenberg 等公共领域文本摘取多段不同内容。

#### 方案 B：LJSpeech 等公开数据集

如果 `edge-tts` 网络不可用，使用 LJSpeech 等开源数据集。

#### Fallback：纯 sine tone 占位

用于测试流程完整性，不用于性能评估。

### 4.4 测试流程

```python
# 伪代码逻辑
def run_benchmark():
    results = []
    # 修复 F-03: 随机化测试顺序，避免热累积效应
    test_cases = list(product(profiles, durations, range(3)))
    random.shuffle(test_cases)

    model = WhisperModel(...)  # 修复 F-13: 模型只加载一次，分离加载和转录时间
    load_time = time.time() - start

    for profile, duration, run in test_cases:
        audio_file = get_test_audio(duration)
        result = single_run(model, profile, audio_file)
        result['model_load_time'] = load_time
        result['run_sequence'] = len(results)
        results.append(result)

        # 修复 F-03: 每次运行间加入冷却间隔
        time.sleep(30)

    save_results(results)  # → JSON + Markdown
```

#### `single_run` 返回指标

| 指标 | 来源 | 格式 |
|------|------|------|
| time_wall_sec | `time.time()` 差 | float |
| time_cpu_sec | `time.process_time()` 差 | float |
| peak_memory_mb | `/usr/bin/time -l` 或 `psutil` | int |
| rtf | `time_wall_sec / audio_duration_sec` | float（<1 为实时） |
| segment_count | `len(segments)` | int |
| total_chars | `sum(len(s.text) for s in segments)` | int |
| **wer** | `jiwer` 计算（**修复 F-02**） | float |
| **cer** | `jiwer` 计算（**修复 F-02**） | float |
| **therm_state** | `pmset -g therm` 解析（**修复 F-03/F-12**） | str |
| model | `large-v3` | str |
| profile | 当前测试的 profile | str |
| audio_duration_sec | `ffprobe` 获取 | float |
| run_sequence | 运行序号（**修复 F-12**） | int |

### 4.5 输出格式

#### JSON（供程序消费）

```json
[
  {
    "profile": "default",
    "duration_sec": 300,
    "run": 1,
    "time_wall_sec": 125.3,
    "time_cpu_sec": 98.2,
    "peak_memory_mb": 4280,
    "rtf": 0.418,
    "segment_count": 8,
    "total_chars": 2450,
    "wer": 0.05,
    "cer": 0.02,
    "therm_state": "Normal",
    "run_sequence": 0
  }
]
```

#### Markdown 汇总表（供人阅读）

```markdown
### Profile: default

| Duration | Wall Time | RTF   | Peak Mem | Segments | WER  |
|----------|-----------|-------|----------|----------|------|
| 1 min    | 25.1s     | 0.418 | 3.2 GB   | 2        | 0.03 |
| 5 min    | 125.3s    | 0.418 | 4.3 GB   | 8        | 0.04 |
| 15 min   | 376.0s    | 0.418 | 5.1 GB   | 22       | 0.05 |
| 30 min   | 752.0s    | 0.418 | 6.8 GB   | 45       | 0.06 |
```

### 4.6 验收标准

| 验收项 | 检查方式 |
|--------|---------|
| 测试流程可用 | `python benchmark.py --help` 正常退出 |
| 所有 36 次运行无 crash | `python benchmark.py run --all` 0 退出 |
| JSON 输出完整性 | 36 条记录，字段齐全 |
| RTF 稳定性 | 同 profile/时长 的三次运行 RTF 标准差 < 15% |
| 内存可观测 | peak_memory 非 None |
| **WER 合理性** | **各 profile 的 WER < 10%（合成音频应极低）** |

### 4.7 被测环境声明

每次测试结果输出附带环境信息：

```json
{
  "environment": {
    "hostname": "MacBook Air M1 2020",
    "cpu": "Apple M1 (7-core GPU)",
    "ram_gb": 16,
    "os": "macOS 15.x",
    "python": "3.12.x",
    "faster_whisper": "1.x.x"
  }
}
```

---

## 5. 架构决策记录 (ADR)

### ADR-001: Profile 使用三档独立值而非单一滑条

| 维度 | 方案 A：三档命名 Profile | 方案 B：滑条式（vad_sensitivity=1~10） |
|------|------------------------|-------------------------------------|
| 复杂度 | 低（三组固定值） | 高（需要映射关系文档） |
| 可测试性 | 好（离散状态可穷举） | 差（连续值组合爆炸） |
| 用户心智 | 低（选择场景名） | 中（需要理解 VAD 参数意义） |
| 扩展性 | 加新 Profile 即可 | 需要重新设计映射 |
| **结论** | **✅ 选用** | ❌ |

### ADR-002: ~~chunk_length=30~~ → 三档统一为 0（已废弃）

**原始决策**: monologue 用 `chunk_length=30` 防御 OOM
**修正**: Whisper 论文明确说 "Input audio is split into 30-second chunks"，这是模型内部硬编码。faster-whisper 的 `chunk_length` 参数是外部 chunk 长度控制，Sprint 1 不需要设置。
**新决策**: 三档统一为 `0`（不限制），依赖 Whisper 内部 30s 窗口和 VAD 切分。

| 维度 | 方案 A：chunk_length=0 | 方案 B：chunk_length=30 |
|------|----------------------|------------------------|
| 正确性 | ✅ 符合 Whisper 架构 | ❌ 与内部 30s 窗口重复 |
| 内存安全 | ✅ Whisper 内部已控制 | 无额外收益 |
| **结论** | **✅ 选用** | ❌ 废弃 |

### ADR-003: benchmark 用 edge-tts 合成语音而非真实录音

| 维度 | 方案 A：edge-tts 合成 | 方案 B：真实录音 |
|------|----------------------|----------------|
| 可复现性 | ✅ 完全可复现 | ❌ 录音环境不同 |
| 自动化 | ✅ 可脚本化 | ❌ 需手动录制 |
| 真实性 | ⚠️ TTS 比真人干净 | ✅ 反映真实场景 |
| **结论** | **✅ 选用（基线摸底阶段）** | 后续 Sprint 可补充 |

**注意**: TTS 语音较干净，RTF 可能比真人录音好。Sprint 1 只建立基线，相对比较仍有意义。Sprint 2 引入真实录音对比。

### ADR-004: Sprint 1 所有 profile 统一用 large-v3

| 维度 | 方案 A：统一 large-v3 | 方案 B：不同 profile 不同模型 |
|------|---------------------|----------------------------|
| 对照纯度 | ✅ 只测 VAD 参数影响 | ❌ 模型大小差异混入 |
| Sprint 2 可借鉴 | ✅ 基线干净 | ❌ 分不清是 VAD 还是模型差异 |
| 实用性 | 大模型慢但准 | 可根据场景选 small/base 提速 |
| **结论** | **✅ 选用（基线摸底）** | Sprint 2 再做模型 × Profile 矩阵 |

### ADR-005: default profile 不开 VAD（修复 F-01）

| 维度 | 方案 A：default 不开 VAD | 方案 B：default 开 VAD |
|------|------------------------|----------------------|
| 向后兼容 | ✅ 与 Sprint 0 完全一致 | ❌ 静默行为变更 |
| 用户体验 | ✅ 升级后结果不变 | ❌ 可能丢失内容 |
| 功能完整性 | ⚠️ 需要显式选 profile 才启用 VAD | ✅ VAD 默认生效 |
| **结论** | **✅ 选用** | ❌ |

---

## 6. 扩展点 & 约束

### 6.1 Sprint 2 预留接口

```python
# 当前设计预留的扩展位置

# 1. Profile 可在外部 YAML/TOML 定义（目前硬编码在脚本内）
#    预留：PROFILES = load_profiles("profiles.yaml")  # Sprint 2+

# 2. AudioClassifier 自动检测 -> 自动选 Profile
#    预留：profile = classify_audio(audio_path)  # Sprint 3+

# 3. ChunkedPipeline 长音频切分 -> 并行 -> 合并
#    预留：if profile.parallel:
#              chunks = split_audio(audio_path, chunk_sec=300)
#              results = parallel_map(transcribe_chunk, chunks)
#              transcript = merge(results)  # Sprint 2
```

### 6.2 Sprint 2 chunk 嵌套风险（F-06）

当 Sprint 2 引入外部切分（如 5min）时，与 Whisper 内部 30s 窗口形成两层嵌套：

```
外部切分 (chunk_sec=300) ──┬── chunk 1 (0-300s) ──┬── internal chunk 1 (0-30s)
                           │                        ├── internal chunk 2 (30-60s)
                           │                        └── ...
                           ├── chunk 2 (300-600s) ──┬── internal chunk 1 (0-30s)
                           │                        └── ...
                           └── ...
```

**风险**:
1. 外部 chunk 边界是物理切分，干净无跨边界问题
2. 但 internal chunk 在外部 chunk 内部的 30s 边界处可能截断句子
3. 如果 Sprint 2 并行度较高（2-3 路），每个线程都在跑 internal 30s chunk，M1 内存压力倍增

**缓解**: Sprint 2 设计时，对 monologue profile 考虑 `chunk_length=0`（外部切分已控制每个 worker 的音频长度）。

### 6.3 已知约束

| 约束 | 说明 |
|------|------|
| `device="cpu"` | M1 的 mps 后端在 faster-whisper 1.x 有兼容问题，统一 cpu |
| `compute_type="int8"` | 精度和速度的平衡点，后续可引入 float16 对比 |
| `--language` | 自动检测有第一次推理开销（约 3~5s），指定语言可跳过 |
| large-v3 唯一性 | Sprint 1 不区分模型大小，结论可能不适用于 small/base |
| VAD 参数为初始值 | 所有 VAD 微调值标注"待基准验证"，非最终定值 |

### 6.4 待基准测试验证的假设

| 假设 | 验证方法 | 关联 Backlog |
|------|---------|-------------|
| 音频时长 × 处理时间 ≈ 线性 | 4 个时长点的 RTF 是否恒定 | D-01 |
| M1 16GB 在 30min 时 OOM | Peak memory 是否随时间线性增长 | D-02 |
| faster-whisper VAD 足够好 | Segment 边界人工抽检 + WER 对比 | D-03 |
| monologue threshold=0.4 优于 0.3/0.5 | WER + segment_count 对比 | F-04 |
| voicelines threshold=0.55 优于 0.5/0.6 | WER + segment_count 对比 | F-07 |

---

## 7. 边界条件

### 7.1 <1s 音频

| 场景 | 行为 |
|------|------|
| 音频 < 1s | Whisper 可正常处理。如果 `vad_filter=True` 且 VAD 未检测到语音 → 空 segments |
| 输出 | 打印空行，生成空 .txt 文件 |
| 改进 | 输出 warning: `[警告] 未检测到语音内容，输出为空` |

### 7.2 纯静音/无语音

| 场景 | 行为 |
|------|------|
| 纯静音音频 | VAD 过滤掉所有内容 → 空 segments |
| 输出 | 同上 |
| 改进 | 同上 warning |

### 7.3 采样率不匹配

| 场景 | 行为 |
|------|------|
| 采样率 ≠ 16kHz | WhisperModel 内部使用 PyAV 加载音频，支持重采样 |
| 低采样率（8kHz 电话录音） | 质量显著下降，但不会崩溃 |
| 高采样率（96kHz） | 重采样有额外计算开销 |
| 改进 | 输出 warning: `[警告] 音频采样率 {sr}Hz，Whisper 期望 16kHz` |

### 7.4 多语言混合

| 场景 | 行为 |
|------|------|
| `language=None`（自动检测） | 每个 segment 可能检测到不同语言 |
| 显式指定 `--language` | 混合语言片段被强制用单语言模型处理 |
| 改进 | 文档中说明此行为，不修改代码 |

---

## 附录 A: Profile 参数实现映射（Python 代码级）

```python
# 以下是对应实现的结构，供 Coder 直接使用

PROFILES = {
    "default": {
        "model_size": "large-v3",
        "device": "cpu",
        "compute_type": "int8",
        "vad_filter": False,  # 与 Sprint 0 一致
        "vad_parameters": None,  # 不传，使用 faster-whisper 默认
        "beam_size": 5,
        "best_of": 5,
        "temperature": 0.0,
        "compression_ratio_threshold": 2.4,
        "chunk_length": 0,
        # language 不在此定义，由 --language 参数直接传入
    },
    "monologue": {
        "model_size": "large-v3",
        "device": "cpu",
        "compute_type": "int8",
        "vad_filter": True,
        "vad_parameters": {
            "threshold": 0.4,        # 待基准验证
            "min_silence_duration_ms": 1000,
            "speech_pad_ms": 300,
            "min_speech_duration_ms": 200,
        },
        "beam_size": 5,
        "best_of": 5,
        "temperature": 0.0,
        "compression_ratio_threshold": 2.4,
        "chunk_length": 0,
    },
    "voicelines": {
        "model_size": "large-v3",
        "device": "cpu",
        "compute_type": "int8",
        "vad_filter": True,
        "vad_parameters": {
            "threshold": 0.55,       # 待基准验证
            "min_silence_duration_ms": 1500,
            "speech_pad_ms": 400,
            "min_speech_duration_ms": 100,
        },
        "beam_size": 5,
        "best_of": 5,
        "temperature": 0.0,
        "compression_ratio_threshold": 2.4,
        "chunk_length": 0,
    },
}
```

---

## 附录 B: 与 Backlog 的对应关系

| Backlog ID | 优先级 | 本设计如何响应 |
|-----------|--------|--------------|
| A-02 | P0 | 完整定义了三个 Profile 的参数矩阵 |
| D-01 | P0 | 基准测试设计包含 4 个时长点 × 3 次重复，可检验线性假设 |
| D-02 | P0 | 内存约束检查 + benchmark 记录峰值内存 |
| D-03 | P1 | 设计保留 `vad_filter=True` 仅对 monologue/voicelines 启用；benchmark 统计 segment_count |

## 附录 C: ATTACK-001 修复对照表

| ATTACK 发现 | 严重程度 | 修复状态 | 修复位置 |
|------------|---------|---------|---------|
| F-01: 向后兼容冲突 | P0 | ✅ 已修复 | default profile `vad_filter=False` |
| F-02: 缺少 WER | P0 | ✅ 已修复 | 4.4 节新增 wer/cer 指标，4.6 节新增验收标准 |
| F-03: M1 降频 | P1 | ✅ 已修复 | 4.4 节随机化测试顺序 + 30s 冷却间隔 |
| F-04: threshold=0.3 风险 | P1 | ✅ 已修复 | 回调到 0.4，标注"待基准验证" |
| F-05: 边界缺失 | P1 | ✅ 已修复 | 新增第 7 章边界条件 |
| F-06: chunk 嵌套 | P1 | ✅ 已修复 | 6.2 节记录风险和缓解方案 |
| F-07: threshold=0.6 风险 | P2 | ✅ 已修复 | 回调到 0.55 |
| F-11: 同一段重复 | P2 | ✅ 已修复 | 4.3 节改为多段不同内容拼接 |
| F-12: 缺少温度监测 | P2 | ✅ 已修复 | 4.4 节新增 therm_state 指标 |
| F-13: 模型加载时间未分离 | P2 | ✅ 已修复 | 4.4 节模型只加载一次 |
| F-14: language 字段误导 | P2 | ✅ 已修复 | 3.2 节修正描述，profile 不维护 language |
