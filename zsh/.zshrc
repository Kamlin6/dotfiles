# <Yuri>
# Shell
export PS1="Kambravolin@Kishin %~ %# "
export PATH="$HOME/bin/utils:$HOME/.config/shell:$HOME/.local/bin:$PATH"

alias ls="ls -lah --color=auto"
alias tree='tree -a -I  ".git|node_modules|.DS_Store"'
# </Yuri>

# <Yuri>
# ML/AI 缓存路径（隔离系统盘写入）
export HF_HOME="$HOME/models/huggingface"
export HF_HUB_CACHE="$HOME/models/huggingface/hub"
export TORCH_HOME="$HOME/models/torch"
# </Yuri>

# <Yuri>
# API-keys
export MONICA_API_KEY="sk-lyWUmHsc2xda_j0UE1nyB_t1tX5Vpi94_d_gD4LSOGjJbGuMaGVU5C1pwALbvPvF-cqRhv-_dym3FSdhgWkceG-wNRq_"
export DASHSCOPE_API_KEY="sk-ba1aa8fcd2774a8eaee5de6014a29bd7"
export BAILIAN_API_KEY="sk-cda82bbded88477aade40d16dafb2232"
export SILICONFLOW_API_KEY="sk-wtnhcvepzyfupcstetcnvkzwxotymvolqnirjeazemhhsduz"
# </Yuri>

# <Yuri>
# 语言 / 工具链
export MECABRC="/opt/homebrew/etc/mecabrc"
# </Yuri>

# <Yuri>
# 镜像源（中国大陆加速）
export HF_ENDPOINT="https://hf-mirror.com"
export UV_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/simple"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
# </Yuri>

# <Yuri>
# 代理脚本（可选，按需启用）
[[ -f "$HOME/.config/shell/proxy.sh" ]] && source "$HOME/.config/shell/proxy.sh"
# </Yuri>

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/zhuanzmima0000/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/zhuanzmima0000/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/zhuanzmima0000/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/zhuanzmima0000/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# <Yuri>
# Quarto: 从 skeleton 复制 _quarto.yml + template.qmd 到新目录
# 用法: $ qnew my-blog
qnew() {
  local dir="${1:-untitled}"
  mkdir -p "$dir" && cp ~/.config/quarto/skeleton/_quarto.yml "$dir/" && printf -- "---\ntitle: \"$(basename "$dir")\"\n---\n" > "$dir/index.qmd"
  echo "→ $dir 已初始化（index.qmd + _quarto.yml）"
}
# </Yuri>
