#!/usr/bin/env bash
# scripts/download_whisper_mlx.sh
# 用途: 下载 mlx-community/whisper-large-v3-turbo-4bit 到 ~/models/whisper-mlx/
# 校验: 3 文件齐(config.json + model.safetensors + multilingual.tiktoken) + sha256
# 镜像: hf-mirror.com (主) + huggingface.co (备用)
# 续传: wget -c

set -euo pipefail

MODEL_DIR="${HOME}/models/whisper-mlx"
EXPECTED_FILES=(
    "config.json"
    "model.safetensors"
    "multilingual.tiktoken"
)
MIRROR_BASE="https://hf-mirror.com/mlx-community/whisper-large-v3-turbo-4bit/resolve/main"
HF_BASE="https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit/resolve/main"

# sha256 实际下载后填入;为空则跳过校验(BK-014 修订)
EXPECTED_SHA256_model="e2d6146b49644c13ed7467060d3c43c402bbdfca1f01f1c21f6fbeda23b6567e"
EXPECTED_SHA256_tiktoken="b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126"

echo "==> Downloading whisper-large-v3-turbo-4bit to ${MODEL_DIR}"
mkdir -p "${MODEL_DIR}"

cd "${MODEL_DIR}"

for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "${file}" ]; then
        echo "==> ${file} already exists, skip"
        continue
    fi
    echo "==> Downloading ${file}..."
    if ! wget -c "${MIRROR_BASE}/${file}" -O "${file}.tmp" 2>&1 | tail -3; then
        echo "==> Mirror failed, fallback to HF"
        wget -c "${HF_BASE}/${file}" -O "${file}.tmp"
    fi

    # sha256 校验(仅当 EXPECTED_ 非空且文件 > 5MB)
    if [ -f "${file}.tmp" ]; then
        file_size=$(stat -f%z "${file}.tmp" 2>/dev/null || stat -c%s "${file}.tmp" 2>/dev/null || echo 0)
        if [ "${file_size}" -gt 5242880 ]; then
            if [ "${file}" = "model.safetensors" ] && [ -n "${EXPECTED_SHA256_model}" ]; then
                echo "${EXPECTED_SHA256_model}  ${file}.tmp" | shasum -a 256 -c -
            elif [ "${file}" = "multilingual.tiktoken" ] && [ -n "${EXPECTED_SHA256_tiktoken}" ]; then
                echo "${EXPECTED_SHA256_tiktoken}  ${file}.tmp" | shasum -a 256 -c -
            else
                echo "==> sha256 EXPECTED empty for ${file}, skip verification"
            fi
        fi
        mv "${file}.tmp" "${file}"
    fi
done

echo "==> Verifying 3 files present..."
for f in config.json model.safetensors multilingual.tiktoken; do
    test -f "${MODEL_DIR}/${f}" || { echo "MISSING: ${f}"; exit 1; }
    echo "  OK: ${f}"
done

echo "==> Done. Model at ${MODEL_DIR}"
ls -lh "${MODEL_DIR}"
