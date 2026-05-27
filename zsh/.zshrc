# <Yuri>
# Shell
export PS1="Kambravolin@Kishin %~ %# "
export PATH="$HOME/.config/shell:$HOME/.local/bin:$PATH"
# </Yuri>

# <Yuri>
# ML/AI 缓存路径（隔离系统盘写入）
export HF_HOME="~/models/huggingface"
export TORCH_HOME="~/models/torch"
# </Yuri>

# <Yuri>
# 语言 / 工具链
export MECABRC="/opt/homebrew/etc/mecabrc"
# </Yuri>

# <Yuri>
# 镜像源（中国大陆加速）
export HF_ENDPOINT="https://hf-mirror.com"
export UV_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/simple"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
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
