#!/usr/bin/env bash
# =============================================================
# healthcheck.sh — 健康检查（带重试，容忍服务启动时间）
#   CI 部署后立即调用时，WordPress/MySQL 可能还在初始化，
#   故对每项做有限重试（默认 12 次 × 5s = 60s 上限）。
#
#   v2（2026-09-19）：增加 WP 安装状态检测。
#   踩坑实录：WP 未完成安装时，任何路径都 302 →
#   /wp-admin/setup-config.php；curl -sf 只拦 >=400，302 被
#   放行 → 「CI 绿灯但站点实际卡在安装向导」的假健康。
#
#   v2.1（2026-09-19）：wp-login 检查改用显式 HTTP 200 判定——
#   -f 同样放行 302（生产实测），未安装时会假绿。
# =============================================================
set -uo pipefail
fail=0

# check <名称> <命令> [重试次数=12] [间隔秒=5]
check() {
  local name="$1" cmd="$2" tries="${3:-12}" delay="${4:-5}" i=1
  while [ "$i" -le "$tries" ]; do
    if eval "$cmd" >/dev/null 2>&1; then
      echo "✅ $name"
      return 0
    fi
    [ "$i" -lt "$tries" ] && sleep "$delay"
    i=$((i + 1))
  done
  echo "❌ $name (重试 ${tries} 次仍失败)"
  fail=1
}

check "nginx :80"       'curl -sf -o /dev/null http://127.0.0.1:80'
check "wordpress :8080" 'curl -sf -o /dev/null http://127.0.0.1:8080'
# WP 安装状态：:8080 响应头不得出现 302 → setup-config
check "wp 已完成安装"    '! curl -s -D - -o /dev/null http://127.0.0.1:8080/ | tr -d "\r" | grep -qi "^location:.*setup-config"'
# wp-login.php 仅在安装完成后才 200（未安装时同样被 302）
check "wp-login 200"    '[ "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/wp-login.php)" = "200" ]'
check "pgvector :5433"  'docker exec pgvector pg_isready -U postgres'
check "mysql 存活"       'docker exec bolent_wp_mysql mysqladmin ping -h localhost'

if [ "$fail" -eq 0 ]; then
  echo "=== 全部健康 ==="
else
  echo "=== 有服务异常（若为 wp 未安装：跑 scripts/wp-bootstrap.sh 修配置，"
  echo "    再浏览器走 http://szbolent.cn 安装向导完成安装后重试） ==="
fi
exit $fail
