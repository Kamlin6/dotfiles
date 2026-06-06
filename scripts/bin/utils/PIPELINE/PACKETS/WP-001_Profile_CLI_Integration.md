# WP-001: Profile 参数矩阵与 CLI 集成

> Sprint 1 — 基线摸底 & Profile 定义
> 等级: P0（核心路径）
> 状态: ⏳ 待 CODE

---

## 目标

在现有 `transcribe` 脚本中引入 `--profile` 参数，将三个 Profile 的参数矩阵接入 CLI，实现参数覆盖逻辑。

## 背景上下文

- 来源: `PIPELINE/DESIGN/DESIGN-001_Profile_and_Baseline.md` → 第 2 节（参数矩阵）、第 3 节（CLI 设计）
- 权威标注: `DESIGN-001` `§2` `§3`
- 当前代码: 73 行单文件串行调用，无 profile 概念

## 允许修改的文件

| 文件 | 修改范围 |
|------|---------|
| `scripts/bin/utils/transcribe` | 添加 PROFILE 字典、--profile argparse 参数、profile 合并逻辑 |

## 禁止修改的文件

| 文件 | 原因 |
|------|------|
| `PIPELINE/` 下的任何文件 | 设计/管道文件，Coder 不得触碰 |
| 任何测试/基准脚本 | 由 WP-002 处理 |

## 输入约束

### 来源 SPEC（DESIGN-001 §2）

- 三个 Profile 必须使用 `DESIGN-001` 附录 A 中定义的精确参数值
- `--profile` 合法值: `default`, `monologue`, `voicelines`
- 默认值: `default`（保证向后兼容）

### 参数优先级规则

```
显式指定参数（--model/--language） > Profile 参数 > faster-whisper 默认值
```

### 错误处理

- 非法 profile 名称: `argparse.ArgumentTypeError` + 打印合法值
- profile 与 --model 同时指定: 模型用 --model，VAD 参数用 profile
- profile 与 --language 同时指定: language 覆盖 profile

## 输出要求

### 代码结构

```python
# 必须在脚本中加入以下结构

PROFILES = {
    "default": { ... },      # 完整参数见 DESIGN-001 附录 A
    "monologue": { ... },
    "voicelines": { ... },
}

def merge_profile_with_args(profile_name: str, model: str, language: str | None) -> dict:
    """合并 profile 参数与显式命令行参数，显式参数优先"""
    ...

def main():
    parser.add_argument("--profile", ...)
    args = parser.parse_args()
    # ... 用 merge_profile_with_args 合并后调用 WhisperModel
```

### 行为验证

```bash
# 1. 向后兼容（不传 --profile 应完全等效于 Sprint 0）
transcribe test.mp3
# 输出保存到 test.txt

# 2. --profile default 应与不传 --profile 结果相同
transcribe test.mp3 --profile default

# 3. --profile monologue/voicelines 正常执行
transcribe test.mp3 --profile monologue
transcribe test.mp3 --profile voicelines

# 4. profile + model 覆盖
transcribe test.mp3 --profile monologue --model large-v3

# 5. profile + language 覆盖
transcribe test.mp3 --profile monologue --language ja

# 6. 非法 profile 报错（以下应 exit 1 + 提示合法值）
transcribe test.mp3 --profile invalid
```

### 验收命令

```bash
# 语法检查
python3 -c "import ast; ast.parse(open('scripts/bin/utils/transcribe').read())"

# 向后兼容检查（对比默认 profile 和 Sprint 0 行为）
# 对同一短音频跑两次，确认输出一致
diff <(transcribe test.mp3 2>/dev/null) <(transcribe test.mp3 --profile default 2>/dev/null)

# --help 输出应包含 --profile
transcribe --help 2>&1 | grep -q "profile" && echo "OK"
```

### 回滚方式

```bash
# 如果合并后引入 bug：
git checkout -- scripts/bin/utils/transcribe
# 或从 git 历史还原
```
