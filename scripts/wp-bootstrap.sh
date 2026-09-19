#!/usr/bin/env bash
# =============================================================
# wp-bootstrap.sh — 修复 WordPress 卡安装向导（wp-config.php 缺失）
#   现象（2026-09-19 实测）：volume 中 wp-config.php 缺失，
#   站点所有路径 302 → /wp-admin/setup-config.php，卡在安装
#   向导第一步；官方镜像未在首启时自动生成。
#   本脚本在容器内用镜像自带模板 wp-config-docker.php 重新
#   生成配置（读取容器 env 的 DB 配置），幂等可重复跑。
#   用法：bash /opt/szbolent-cn/scripts/wp-bootstrap.sh
# =============================================================
set -euo pipefail

if docker exec bolent_wp test -f /var/www/html/wp-config.php 2>/dev/null; then
  echo "✅ wp-config.php 已存在，无需处理"
else
  echo "[*] 容器内缺失 wp-config.php，用镜像自带模板生成 ..."
  if docker exec bolent_wp test -f /usr/src/wordpress/wp-config-docker.php 2>/dev/null; then
    docker exec bolent_wp cp /usr/src/wordpress/wp-config-docker.php /var/www/html/wp-config.php
  else
    echo "❌ 模板 /usr/src/wordpress/wp-config-docker.php 不存在，请手动生成："
    echo "    docker exec -it bolent_wp sh -c 'cp /usr/src/wordpress/wp-config-sample.php /var/www/html/wp-config.php'"
    echo "    然后按容器 env（WORDPRESS_DB_* / WORDPRESS_TABLE_PREFIX）填 DB 四项。"
    exit 3
  fi
  docker exec bolent_wp chown www-data:www-data /var/www/html/wp-config.php
  echo "✅ wp-config.php 已生成"
fi

echo "[*] 验证安装状态 ..."
loc=$(curl -s -D - -o /dev/null http://127.0.0.1:8080/ | tr -d '\r' | grep -i '^location:' || true)
if echo "$loc" | grep -qi 'setup-config'; then
  echo "⚠️ 仍在安装向导（DB 配置已就位但库未初始化）："
  echo "    方式 A：浏览器走 http://szbolent.cn 安装向导完成安装；"
  echo "    方式 B：wp-cli 非交互安装（需站点 URL / 管理员账号密码，未配置则不自动执行）。"
  exit 2
fi
echo "✅ WP 已越过安装向导"
