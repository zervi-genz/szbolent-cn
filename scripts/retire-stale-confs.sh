#!/usr/bin/env bash
# =============================================================
# retire-stale-confs.sh — 归档宿主 nginx 中的旧手写配置（幂等）
#   背景：机器上残留 /etc/nginx/conf.d/szbolent-h5.conf
#   （443 块指向已死的 8081），与 CI 管理的 00-szbolent.conf
#   并存；将来开 443 时会 502。本脚本将其移入归档目录，
#   不直接删除，可重复跑。
#   用法：bash /opt/szbolent-cn/scripts/retire-stale-confs.sh
#   （建议 merge 后在 deploy.yml 的 nginx 步骤前调用一次）
# =============================================================
set -euo pipefail

STALE_LIST="szbolent-h5.conf"
ARCHIVE_DIR="/root/conf-archive-$(date +%Y%m%d-%H%M%S)"
retired=0

for name in $STALE_LIST; do
  f="/etc/nginx/conf.d/$name"
  if [ -f "$f" ]; then
    mkdir -p "$ARCHIVE_DIR"
    mv "$f" "$ARCHIVE_DIR/$name"
    echo "📦 已归档 $f → $ARCHIVE_DIR/$name"
    retired=$((retired + 1))
  else
    echo "⏭ $f 不存在（已处理过），跳过"
  fi
done

if [ "$retired" -gt 0 ]; then
  echo "[*] nginx -t 校验 ..."
  nginx -t
  systemctl reload nginx
  echo "✅ 已归档 $retired 个旧配置并 reload nginx"
else
  echo "✅ 无需处理"
fi
