#!/usr/bin/env bash
# scripts/download_silero_v6.sh — Sprint 20 T05 thin wrapper.
# Behavior is identical to the original: download silero_vad.onnx to
# ~/models/silero-v6/ with 4-URL fallback chain (2 hf-mirror + 2 huggingface)
# and sha256 verification.  The real work now lives in
# mcp/shared/shared/loader.py.
set -euo pipefail

exec /opt/homebrew/bin/uv run --directory /Users/zhuanzmima0000/.config/opencode/mcp/shared \
    python -m shared.loader \
    --name silero-v6 \
    --dest "${HOME}/models/silero-v6" \
    --url "https://hf-mirror.com/onnx-community/silero-vad/resolve/main/onnx/model.onnx" \
    --url "https://hf-mirror.com/snakers4/silero-vad/resolve/main/src/silero_vad/data/silero_vad.onnx" \
    --url "https://huggingface.co/onnx-community/silero-vad/resolve/main/onnx/model.onnx" \
    --url "https://huggingface.co/snakers4/silero-vad/resolve/main/src/silero_vad/data/silero_vad.onnx" \
    --file "silero_vad.onnx:sha256:a4a068cd6cf1ea8355b84327595838ca748ec29a25bc91fc82e6c299ccdc5808"
