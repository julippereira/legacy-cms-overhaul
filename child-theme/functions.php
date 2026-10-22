<?php
/**
 * Sepulchral Voice Zine Child Theme Functions & Hook Overrides
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit; // Exit if accessed directly
}

/**
 * 1. Enfileira o estilo do tema pai e o CSS do tema filho
 */
function fullframe_child_enqueue_styles() {
    wp_enqueue_style( 'fullframe-parent-style', get_template_directory_uri() . '/style.css' );
    wp_enqueue_style( 'fullframe-child-style', get_stylesheet_uri(), array( 'fullframe-parent-style' ), '1.0.0' );
}
add_action( 'wp_enqueue_scripts', 'fullframe_child_enqueue_styles' );

/**
 * 2. Pre-query optimization: Garante 16 posts por página em arquivos
 * para preencher perfeitamente a grelha de 4 colunas sem órfãos
 */
function custom_archive_posts_per_page( $query ) {
    if ( ! is_admin() && $query->is_main_query() && ( is_archive() || is_category() || is_tag() ) ) {
        $query->set( 'posts_per_page', 16 );
    }
}
add_action( 'pre_get_posts', 'custom_archive_posts_per_page' );

/**
 * 3. Remove os prefixos padrão do WordPress nos títulos dos arquivos ('Categoria:', 'Tag:')
 */
function custom_archive_title_prefix( $title ) {
    if ( is_category() ) {
        $title = single_cat_title( '', false );
    } elseif ( is_tag() ) {
        $title = single_tag_title( '', false );
    } elseif ( is_author() ) {
        $title = get_the_author();
    } elseif ( is_year() ) {
        $title = get_the_date( 'Y' );
    } elseif ( is_month() ) {
        $title = get_the_date( 'F Y' );
    }
    return $title;
}
add_filter( 'get_the_archive_title', 'custom_archive_title_prefix' );

/**
 * 4. Substituição do rodapé: Remove créditos da Catch Themes e injeta direitos autorais customizados
 */
function custom_fullframe_footer_content() {
    ?>
    <div id="site-generator" class="two">
        <div class="wrapper">
            <div id="footer-left-content" class="copyright">
                Copyright &copy; 2007 - <?php echo esc_html( date( 'Y' ) ); ?> <a href="<?php echo esc_url( home_url( '/' ) ); ?>" title="<?php echo esc_attr( get_bloginfo( 'name', 'display' ) ); ?>"><?php bloginfo( 'name' ); ?></a>. Todos os direitos reservados.
            </div>

            <div id="footer-right-content" class="powered">
                Desenvolvido por <a href="https://seusite.com" target="_blank" rel="noopener noreferrer">Seu Site</a>
            </div>
        </div>
    </div>
    <?php
}

function replace_fullframe_footer() {
    remove_action( 'fullframe_footer', 'fullframe_footer_content', 100 );
    add_action( 'fullframe_footer', 'custom_fullframe_footer_content', 100 );
}
add_action( 'init', 'replace_fullframe_footer' );
