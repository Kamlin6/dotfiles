# ~/bin/utils — 工程工具集

本目录包含跨项目可复用的 CLI 工具。

## 工具列表

### srt-slice — SRT 解析 + 音频切片

从 SRT 字幕文件切片音频，输出 32kHz/mono/16bit WAV + manifest JSON。

```
# 只解析 SRT
srt-slice parse --srt audio.srt --output segments.json

# 只切片
srt-slice slice --audio audio.wav --segments segments.json --outdir sliced/ --manifest manifest.json --tag jp1

# 全流程
srt-slice all --srt audio.srt --audio audio.wav --outdir sliced/ --tag jp1
```

依赖：`ffmpeg`

### tts-eval — TTS 合成质量量化评估

对比参考音频和合成音频，计算 WER/CER（基于 whisper ASR + jiwer）和 DNSMOS。

```
tts-eval --ref_dir original_slices/ --syn_dir synthesized/ --manifest manifest.json --output report.json
```

依赖：`openai-whisper`, `jiwer`, `speechmos`, `librosa`

## 安装

```bash
chmod +x ~/bin/utils/*
```

确认 `~/bin/utils` 在 `$PATH` 中（`echo $PATH`），否则在 `.zshrc` 中追加：

```bash
export PATH="$HOME/bin/utils:$PATH"
```
