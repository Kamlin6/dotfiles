#!/usr/bin/env bash
# scripts/download_whisper_mlx.sh — Sprint 20 T05 thin wrapper.
# Behavior is identical to the original: download 3 files
# (config.json + model.safetensors + multilingual.tiktoken) to
# ~/models/whisper-mlx/, with hf-mirror first + huggingface.co fallback
# and sha256 verification.  The real work now lives in
# mcp/shared/shared/loader.py.
set -euo pipefail

exec /opt/homebrew/bin/uv run --directory /Users/zhuanzmima0000/.config/opencode/mcp/shared \
    python -m shared.loader \
    --name whisper-mlx \
    --dest "${HOME}/models/whisper-mlx" \
    --url "https://hf-mirror.com/mlx-community/whisper-large-v3-turbo-4bit/resolve/main/{filename}" \
    --url "https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit/resolve/main/{filename}" \
    --file config.json \
    --file "model.safetensors:sha256:e2d6146b49644c13ed7467060d3c43c402bbdfca1f01f1c21f6fbeda23b6567e" \
    --file "multilingual.tiktoken:sha256:b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126"
