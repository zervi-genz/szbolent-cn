<?php
/**
 * Plugin Name: szbolent ICP Footer
 * Description: 页脚 ICP 备案号合规展示。号码来自环境变量 ICP_LICENSE（.env / 容器 env 注入），留空则不输出任何内容。
 * Version:     1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

add_action( 'wp_footer', function () {
	$icp = trim( (string) getenv( 'ICP_LICENSE' ) );
	if ( '' === $icp ) {
		return; // 未配置备案号时不输出，避免展示占位符
	}
	printf(
		'<div class="szbolent-icp" style="text-align:center;padding:16px 0 24px;font-size:12px;color:#666;">
			<a href="https://beian.miit.gov.cn/" target="_blank" rel="noopener nofollow" style="color:#666;text-decoration:none;">%1$s</a>
		</div>',
		esc_html( $icp )
	);
} );
