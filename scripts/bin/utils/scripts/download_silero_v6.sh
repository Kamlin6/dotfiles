#!/usr/bin/env bash
# scripts/download_silero_v6.sh
# 用途: 下载 Silero v6 ONNX 到 ~/models/silero-v6/silero_vad.onnx
# 校验: sha256
# 镜像: hf-mirror.com (主) + huggingface.co (备用)

set -euo pipefail

MODEL_DIR="${HOME}/models/silero-v6"
MODEL_FILE="silero_vad.onnx"

# URL 候选(WP 验证取准确:优先 onnx-community)
URLS=(
    "https://hf-mirror.com/onnx-community/silero-vad/resolve/main/onnx/model.onnx"
    "https://hf-mirror.com/snakers4/silero-vad/resolve/main/src/silero_vad/data/silero_vad.onnx"
)
HF_FALLBACK=(
    "https://huggingface.co/onnx-community/silero-vad/resolve/main/onnx/model.onnx"
    "https://huggingface.co/snakers4/silero-vad/resolve/main/src/silero_vad/data/silero_vad.onnx"
)

# sha256 实际下载后填入;为空则跳过校验
EXPECTED_SHA256="a4a068cd6cf1ea8355b84327595838ca748ec29a25bc91fc82e6c299ccdc5808"

echo "==> Downloading Silero v6 ONNX to ${MODEL_DIR}/${MODEL_FILE}"
mkdir -p "${MODEL_DIR}"

cd "${MODEL_DIR}"

if [ -f "${MODEL_FILE}" ]; then
    echo "==> ${MODEL_FILE} already exists, skip"
else
    downloaded=0
    for i in "${!URLS[@]}"; do
        url="${URLS[$i]}"
        echo "==> Trying ${url}..."
        if wget -c "${url}" -O "${MODEL_FILE}.tmp" 2>&1 | tail -3; then
            if [ -s "${MODEL_FILE}.tmp" ]; then
                downloaded=1
                break
            fi
        fi
        echo "==> Mirror URL $((i+1)) failed, trying next..."
    done

    if [ "${downloaded}" -eq 0 ]; then
        echo "==> All mirror URLs failed, trying HF fallback..."
        for url in "${HF_FALLBACK[@]}"; do
            echo "==> Trying ${url}..."
            if wget -c "${url}" -O "${MODEL_FILE}.tmp" 2>&1 | tail -3; then
                if [ -s "${MODEL_FILE}.tmp" ]; then
                    downloaded=1
                    break
                fi
            fi
        done
    fi

    if [ "${downloaded}" -eq 0 ] || [ ! -s "${MODEL_FILE}.tmp" ]; then
        echo "ERROR: All download attempts failed"
        rm -f "${MODEL_FILE}.tmp"
        exit 1
    fi

    # sha256 校验(可选)
    if [ -n "${EXPECTED_SHA256}" ]; then
        echo "${EXPECTED_SHA256}  ${MODEL_FILE}.tmp" | shasum -a 256 -c -
    else
        echo "==> sha256 EXPECTED empty, skip verification"
    fi

    mv "${MODEL_FILE}.tmp" "${MODEL_FILE}"
fi

echo "==> Verifying ${MODEL_FILE}..."
test -f "${MODEL_DIR}/${MODEL_FILE}" || { echo "MISSING: ${MODEL_FILE}"; exit 1; }
file_size=$(stat -f%z "${MODEL_DIR}/${MODEL_FILE}" 2>/dev/null || stat -c%s "${MODEL_DIR}/${MODEL_FILE}" 2>/dev/null || echo 0)
echo "  OK: ${MODEL_FILE} (${file_size} bytes, ~$((file_size/1024/1024))MB)"

echo "==> Done. VAD model at ${MODEL_DIR}"
ls -lh "${MODEL_DIR}"
