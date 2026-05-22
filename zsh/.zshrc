export PS1="Kambravolin@Kishin %~ %# "
export PATH="$HOME/.config/shell:$HOME/.local/bin:$PATH"
export HF_HOME="~/models/huggingface"
export TORCH_HOME="~/models/torch"
export MECABRC="/opt/homebrew/etc/mecabrc"
export HF_ENDPOINT="https://hf-mirror.com"
export UV_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/simple"

[[ -f "$HOME/.config/shell/proxy.sh" ]] && source "$HOME/.config/shell/proxy.sh"


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

