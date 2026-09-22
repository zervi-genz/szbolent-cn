<?php
/**
 * Plugin Name: SZBolent LianTiao Security Guard
 * Description: 联调安全收紧（2026-09-22）：XML-RPC 全禁 + REST users 端点仅登录用户可见。P2 联调起强制（联调方案第 5 节）。
 * Version:     1.0.0
 */

if (!defined('ABSPATH')) {
    exit;
}

// 1) XML-RPC 全禁（接口层面关闭，xmlrpc.php POST 将返回 405/403 且功能不可用）
add_filter('xmlrpc_enabled', '__return_false');

// 2) /wp-json/wp/v2/users* 未登录一律 401（此前匿名可列管理员用户名，泄露 login 名）
add_filter('rest_pre_dispatch', function ($result, $server, $request) {
    if (preg_match('#^/wp/v2/users#', $request->get_route()) && !current_user_can('list_users')) {
        return new WP_Error(
            'rest_forbidden_context',
            __('Sorry, you are not allowed to list users.'),
            ['status' => 401]
        );
    }
    return $result;
}, 10, 3);

// 3) XML-RPC 方法表清空（xmlrpc_enabled 拦不住免认证方法，双保险）
add_filter('xmlrpc_methods', '__return_empty_array');

// 4) 本地 HTTP 仿真环境强制启用应用密码（WP 默认要求 HTTPS/127.0.0.1，局域网联调必须开）
add_filter('wp_is_application_passwords_available', '__return_true');
