-- Identifica e converte termos que não pertencem às macro-categorias protegidas
UPDATE wp_term_taxonomy 
SET taxonomy = 'post_tag' 
WHERE taxonomy = 'category' 
  AND term_id NOT IN (
    SELECT term_id FROM wp_terms WHERE slug IN ('edicoes', 'entrevistas', 'noticias', 'shows', 'arquivos')
  );

-- Recalcula a contagem de posts associados a cada tag/categoria
UPDATE wp_term_taxonomy tt 
SET count = (
    SELECT COUNT(*) 
    FROM wp_term_relationships tr 
    WHERE tr.term_taxonomy_id = tt.term_taxonomy_id
);
