# WP-002: 基准测试脚本

> Sprint 1 — 基线摸底 & Profile 定义
> 等级: P0（核心路径）
> 状态: ⏳ 待 CODE

---

## 目标

创建一个独立的基准测试脚本 `scripts/bin/utils/benchmark_profile.py`，用于运行 Profile × 时长的性能测试，输出 JSON 结果。

## 背景上下文

- 来源: `PIPELINE/DESIGN/DESIGN-001_Profile_and_Baseline.md` → 第 4 节（基准测试设计）
- 权威标注: `DESIGN-001` `§4`
- 输出: 36 条测试记录 + Markdown 汇总表
- 依赖: WP-001 需要先合并（benchmark 脚本将调用 `transcribe` CLI）

## 允许修改的文件

| 文件 | 修改范围 |
|------|---------|
| `scripts/bin/utils/benchmark_profile.py` | **新建**。独立脚本，不修改现有 transcribe |

## 禁止修改的文件

| 文件 | 原因 |
|------|------|
| `scripts/bin/utils/transcribe` | 由 WP-001 处理 |
| `PIPELINE/` 下的任何文件 | 设计/管道文件 |
| 测试音频文件 | 由 benchmark 脚本生成 |

## 输入约束

### 来源 SPEC（DESIGN-001 §4）

测试矩阵：

| Profile | Durations | Repeats |
|---------|-----------|---------|
| `default` | 1 / 5 / 15 / 30 min | 3 |
| `monologue` | 1 / 5 / 15 / 30 min | 3 |
| `voicelines` | 1 / 5 / 15 / 30 min | 3 |

### 测试音频生成

首选方案: 使用 `edge-tts` 生成 1 分钟英文语音
```bash
pip install edge-tts
edge-tts --text "..." --write-media test_1min.wav
```

备选方案（edge-tts 不可用时）:
```bash
# 使用 ffmpeg 生成 1kHz sine tone（纯占位，无意义）
ffmpeg -f lavfi -i "sine=frequency=1000:duration=60" test_1min.wav
```

时长扩展:
```bash
ffmpeg -i test_1min.wav -stream_loop 4 -c copy test_5min.wav
ffmpeg -i test_1min.wav -stream_loop 14 -c copy test_15min.wav
ffmpeg -i test_1min.wav -stream_loop 29 -c copy test_30min.wav
```

音频文件存储位置: `scripts/bin/utils/test_audio/`（自动创建）

## 输出要求

### CLI 接口

```bash
# 用法
python3 benchmark_profile.py --help

# 运行完整矩阵
python3 benchmark_profile.py --all

# 运行特定组合
python3 benchmark_profile.py --profile monologue --duration 5

# 自定义音频
python3 benchmark_profile.py --audio my_audio.wav --profile voicelines

# 输出目录
python3 benchmark_profile.py --all --output-dir ./results
```

### 输出指标（每条记录）

| 字段 | 类型 | 来源 |
|------|------|------|
| `profile` | str | 配置 |
| `duration_sec` | int | 配置 |
| `run` | int | 第几次 (1/2/3) |
| `time_wall_sec` | float | `time.monotonic()` |
| `time_cpu_sec` | float | `time.process_time()` |
| `peak_memory_mb` | int | 见下 |
| `rtf` | float | `time_wall_sec / duration_sec` |
| `segment_count` | int | `len(segments)` |
| `total_chars` | int | 字符数统计 |
| `model` | str | "large-v3" |
| `timestamp` | str | ISO 8601 |

### 峰值内存测量（三选一，降序优先级）

1. **最佳**: 使用 `psutil` 库
   ```python
   import psutil
   peak = psutil.Process().memory_info().rss // 1024 // 1024  # MB
   ```
2. **次选**: 使用 `resource` 模块（`resource.getrusage().ru_maxrss`）
3. **兜底**: macOS `/usr/bin/time -l` 解析输出

### JSON 输出格式

```json
{
  "metadata": {
    "timestamp": "2026-06-03T10:00:00",
    "environment": {
      "hostname": "MacBook Air M1 2020",
      "cpu": "Apple M1",
      "ram_gb": 16,
      "os": "macOS 15.x",
      "python": "3.12.x",
      "faster_whisper": "x.x.x"
    }
  },
  "results": [
    {
      "profile": "default",
      "duration_sec": 60,
      "run": 1,
      "time_wall_sec": 25.1,
      "time_cpu_sec": 18.3,
      "peak_memory_mb": 3280,
      "rtf": 0.418,
      "segment_count": 2,
      "total_chars": 450,
      "model": "large-v3"
    }
  ]
}
```

### Markdown 汇总表

脚本执行完毕后应打印 Markdown 格式的汇总表：

```markdown
# Benchmark Results

## default

| Duration | Wall Time | RTF   | Peak Mem | Segments | Chars  |
|----------|-----------|-------|----------|----------|--------|
| 1 min    | 25.1s     | 0.418 | 3.2 GB   | 2        | 450    |
| 5 min    | ...       | ...   | ...      | ...      | ...    |

## monologue

...
```

### 验收命令

```bash
# 1. --help 正常
python3 scripts/bin/utils/benchmark_profile.py --help && echo "OK"

# 2. 单组合运行（1min，仅 1 次，快速验证）
python3 scripts/bin/utils/benchmark_profile.py --profile default --duration 1

# 3. JSON 输出格式检查
python3 scripts/bin/utils/benchmark_profile.py --profile default --duration 1 \
  | python3 -c "import json,sys; d=json.load(sys.stdin); assert len(d['results'])>0; print('JSON OK')"

# 4. 测试音频生成
ls scripts/bin/utils/test_audio/test_1min.wav && echo "audio OK"
```

### 回滚方式

```bash
# benchmark 脚本是独立文件，删除即可
rm scripts/bin/utils/benchmark_profile.py
rm -rf scripts/bin/utils/test_audio/
```
