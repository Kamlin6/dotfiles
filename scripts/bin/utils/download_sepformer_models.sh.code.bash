#!/bin/bash
# SepFormer 全模型下载脚本
# 使用方式：bash download_sepformer_models.sh
# 可选：将 BASE_URL 换成镜像源 https://hf-mirror.com

# BASE_URL="https://huggingface.co"
BASE_URL="https://hf-mirror.com"  # 国内网络慢时取消注释这行

SAVE_DIR="$HOME/models/huggingface"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

download_model() {
  local REPO=$1
  local DIR=$2
  shift 2
  local FILES=("$@")

  echo -e "\n${BLUE}>>> 下载 $REPO ${NC}"
  mkdir -p "$SAVE_DIR/$DIR"

  for FILE in "${FILES[@]}"; do
    URL="$BASE_URL/$REPO/resolve/main/$FILE"
    DEST="$SAVE_DIR/$DIR/$FILE"

    if [ -f "$DEST" ]; then
      echo "  ✅ 已存在，跳过：$FILE"
    else
      echo "  ⬇️  下载中：$FILE"
      curl -L --retry 3 --retry-delay 2 -o "$DEST" "$URL"
    fi
  done

  echo -e "  ${GREEN}✔ $DIR 完成${NC}"
}

# ─────────────────────────────────────────
# 1. sepformer-wsj02mix（2人，WSJ数据集）
# ─────────────────────────────────────────
download_model "speechbrain/sepformer-wsj02mix" "sepformer-wsj02mix" \
  "README.md" \
  "brain.ckpt" \
  "config.json" \
  "decoder.ckpt" \
  "encoder.ckpt" \
  "hyperparams.yaml" \
  "hyperparams_train.yaml" \
  "masknet.ckpt" \
  "test_mixture.wav"

# ─────────────────────────────────────────
# 2. sepformer-wsj03mix（3人，WSJ数据集）
# ─────────────────────────────────────────
download_model "speechbrain/sepformer-wsj03mix" "sepformer-wsj03mix" \
  "README.md" \
  "CKPT.yaml" \
  "brain.ckpt" \
  "config.json" \
  "counter.ckpt" \
  "decoder.ckpt" \
  "encoder.ckpt" \
  "hyperparams.yaml" \
  "hyperparams_train.yaml" \
  "lr_scheduler.ckpt" \
  "masknet.ckpt" \
  "optimizer.ckpt" \
  "test_mixture_3spks.wav"

# ─────────────────────────────────────────
# 3. sepformer-libri2mix（2人，LibriSpeech，更泛化）
# ─────────────────────────────────────────
download_model "speechbrain/sepformer-libri2mix" "sepformer-libri2mix" \
  "README.md" \
  "brain.ckpt" \
  "config.json" \
  "counter.ckpt" \
  "decoder.ckpt" \
  "encoder.ckpt" \
  "hyperparams.yaml" \
  "masknet.ckpt" \
  "optimizer.ckpt"

# ─────────────────────────────────────────
# 4. sepformer-libri3mix（3人，LibriSpeech，更泛化）
# ─────────────────────────────────────────
download_model "speechbrain/sepformer-libri3mix" "sepformer-libri3mix" \
  "README.md" \
  "brain.ckpt" \
  "config.json" \
  "counter.ckpt" \
  "decoder.ckpt" \
  "encoder.ckpt" \
  "hyperparams.yaml" \
  "masknet.ckpt" \
  "optimizer.ckpt"

echo -e "\n${GREEN}🎉 全部下载完成！${NC}"
echo "保存位置：$SAVE_DIR"
ls -lh "$SAVE_DIR"
