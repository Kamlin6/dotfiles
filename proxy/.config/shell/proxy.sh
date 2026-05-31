# ──────────────────────────────────────────
# Clash Verge Proxy Configuration
# HTTP/SOCKS5 on 127.0.0.1:7897
# ──────────────────────────────────────────

_PROXY_HOST="127.0.0.1"
_PROXY_PORT="7897"
_PROXY_URL="http://${_PROXY_HOST}:${_PROXY_PORT}"

# ── 设置代理 ──────────────────────────────
proxy_on() {
  export http_proxy="${_PROXY_URL}"
  export https_proxy="${_PROXY_URL}"
  export HTTP_PROXY="${_PROXY_URL}"
  export HTTPS_PROXY="${_PROXY_URL}"
  export all_proxy="socks5://${_PROXY_HOST}:${_PROXY_PORT}"
  export ALL_PROXY="socks5://${_PROXY_HOST}:${_PROXY_PORT}"
  # git 走代理（可选）
  git config --global http.proxy  "${_PROXY_URL}"
  git config --global https.proxy "${_PROXY_URL}"
  echo "✅ Proxy ON  → ${_PROXY_URL}"
}

# ── 关闭代理 ──────────────────────────────
proxy_off() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
  git config --global --unset http.proxy  2>/dev/null
  git config --global --unset https.proxy 2>/dev/null
  echo "🚫 Proxy OFF"
}

# ── 查看当前状态 ───────────────────────────
proxy_status() {
  if [[ -n "${http_proxy}" ]]; then
    echo "🟢 Proxy is ON"
    echo "   HTTP  → ${http_proxy}"
    echo "   SOCKS → ${all_proxy}"
  else
    echo "🔴 Proxy is OFF"
  fi
}

# ── 自动启用（检测 Clash 是否在监听）────────
_auto_proxy() {
  # 用 ss/nc 探测端口，静默失败则不启用
  if ss -tnlp 2>/dev/null | grep -q ":${_PROXY_PORT}" || \
     nc -z -w1 "${_PROXY_HOST}" "${_PROXY_PORT}" 2>/dev/null; then
    proxy_on
  fi
}

# 因为我们设置了很多的镜像源，所以开proxy反而是一件低效的行为了。
# _auto_proxy

