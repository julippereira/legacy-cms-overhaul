<?php
/**
 * The template for displaying archive pages (4-column grid layout).
 */

get_header(); ?>

<div id="primary" class="content-area">
    <main id="main" class="site-main" role="main">

    <?php if ( have_posts() ) : ?>

        <header class="page-header">
            <?php
                the_archive_title( '<h1 class="page-title">', '</h1>' );
                the_archive_description( '<div class="taxonomy-description">', '</div>' );
            ?>
        </header>

        <div class="archive-gallery-grid">
            <?php while ( have_posts() ) : the_post(); ?>

                <article id="post-<?php the_ID(); ?>" <?php post_class( 'gallery-post-card' ); ?>>
                    <?php if ( has_post_thumbnail() ) : ?>
                        <div class="gallery-card-thumb">
                            <a href="<?php the_permalink(); ?>">
                                <?php the_post_thumbnail( 'medium_large' ); ?>
                            </a>
                        </div>
                    <?php endif; ?>

                    <div class="gallery-card-body">
                        <h2 class="gallery-card-title">
                            <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                        </h2>

                        <div class="gallery-card-excerpt">
                            <?php 
                                $excerpt = get_the_excerpt();
                                echo esc_html( wp_trim_words( $excerpt, 18, '...' ) ); 
                            ?>
                            <a href="<?php the_permalink(); ?>" class="gallery-read-more">Ler mais &rarr;</a>
                        </div>

                        <div class="gallery-card-date">
                            <?php echo get_the_date( 'd/m/Y' ); ?>
                        </div>
                    </div>
                </article>

            <?php endwhile; ?>
        </div>

        <?php
            the_posts_pagination( array(
                'prev_text'          => __( '&larr; Anterior', 'full-frame-child' ),
                'next_text'          => __( 'Próximo &rarr;', 'full-frame-child' ),
                'before_page_number' => '<span class="meta-nav screen-reader-text">' . __( 'Página', 'full-frame-child' ) . ' </span>',
            ) );
        ?>

    <?php else : ?>
        <section class="no-results not-found">
            <header class="page-header">
                <h1 class="page-title"><?php _e( 'Nada Encontrado', 'full-frame-child' ); ?></h1>
            </header>
            <div class="page-content">
                <p><?php _e( 'Nenhuma publicação corresponde aos critérios selecionados.', 'full-frame-child' ); ?></p>
            </div>
        </section>
    <?php endif; ?>

    </main>
</div>

<?php get_footer(); ?>
