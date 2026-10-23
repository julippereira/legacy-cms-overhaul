-- ============================================================================
-- Script: taxonomy-migration.sql
-- Description: Standardizes and consolidates legacy WordPress categories, 
--              tags, and term taxonomies for the Sepulchral Voice Fanzine archive.
-- Target DB: MySQL 8.x / MariaDB 10.x (WordPress Core Schema)
-- Engine: InnoDB
-- Author: Juliana R Pereira
-- Date: October 2026
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Safety Checks & Session Parameters
-- ----------------------------------------------------------------------------
SET NAMES utf8mb4;
SET foreign_key_checks = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES';

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Backup Snapshots (Temporary staging for safety and rollback verification)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS _bkp_wp_terms;
DROP TABLE IF EXISTS _bkp_wp_term_taxonomy;
DROP TABLE IF EXISTS _bkp_wp_term_relationships;

CREATE TABLE _bkp_wp_terms AS SELECT * FROM wp_terms;
CREATE TABLE _bkp_wp_term_taxonomy AS SELECT * FROM wp_term_taxonomy;
CREATE TABLE _bkp_wp_term_relationships AS SELECT * FROM wp_term_relationships;

-- ----------------------------------------------------------------------------
-- 2. Term Consolidation & Typo Remediation
--    Standardizes historical terms and ensures correct URL slugs.
-- ----------------------------------------------------------------------------

-- Fix encoding, capitalization, and slug mismatches in wp_terms
UPDATE wp_terms 
SET name = 'Entrevistas', slug = 'entrevistas' 
WHERE slug IN ('entrevista', 'interview', 'interviews');

UPDATE wp_terms 
SET name = 'Notícias', slug = 'noticias' 
WHERE slug IN ('news', 'noticia', 'noticias-recentes');

UPDATE wp_terms 
SET name = 'Edições', slug = 'edicoes' 
WHERE slug IN ('edicoes-impressas', 'edicao', 'print-issues');

UPDATE wp_terms 
SET name = 'Shows & Eventos', slug = 'shows-eventos' 
WHERE slug IN ('shows', 'eventos', 'live-reports');

-- ----------------------------------------------------------------------------
-- 3. Deduplication & Relationship Re-mapping
--    Merges duplicate taxonomy IDs pointing to overlapping terms.
-- ----------------------------------------------------------------------------

-- Reassign posts associated with redundant term_taxonomy_ids
-- Example: Remap all posts linked to redundant taxonomy ID 105 to primary taxonomy ID 42
-- (Adjust target IDs as defined in your specific taxonomy inventory)
UPDATE IGNORE wp_term_relationships
SET term_taxonomy_id = 42
WHERE term_taxonomy_id = 105;

-- Remove remaining orphaned assignments after re-mapping
DELETE FROM wp_term_relationships 
WHERE term_taxonomy_id = 105;

-- Remove the redundant taxonomy record
DELETE FROM wp_term_taxonomy 
WHERE term_taxonomy_id = 105;

-- ----------------------------------------------------------------------------
-- 4. Taxonomy Assignment Cleanup
--    Ensures categories and post_tags do not cross boundaries unexpectedly.
-- ----------------------------------------------------------------------------

-- Ensure core editorial sections remain strictly classified as 'category'
UPDATE wp_term_taxonomy 
SET taxonomy = 'category'
WHERE term_id IN (
    SELECT term_id FROM wp_terms 
    WHERE slug IN ('noticias', 'entrevistas', 'edicoes', 'shows-eventos')
);

-- ----------------------------------------------------------------------------
-- 5. Term Count Synchronization
--    Recalculates the actual post count associated with each term.
-- ----------------------------------------------------------------------------
UPDATE wp_term_taxonomy tt 
SET tt.count = (
    SELECT COUNT(tr.object_id)
    FROM wp_term_relationships tr
    INNER JOIN wp_posts p ON tr.object_id = p.ID
    WHERE tr.term_taxonomy_id = tt.term_taxonomy_id
      AND p.post_status = 'publish'
      AND p.post_type IN ('post')
);

-- ----------------------------------------------------------------------------
-- 6. Verification Queries (Post-Migration Audit)
-- ----------------------------------------------------------------------------

-- Audit 1: Check primary categories and updated post counts
SELECT 
    t.term_id,
    t.name,
    t.slug,
    tt.term_taxonomy_id,
    tt.taxonomy,
    tt.count AS post_count
FROM wp_terms t
INNER JOIN wp_term_taxonomy tt ON t.term_id = tt.term_id
WHERE tt.taxonomy = 'category'
ORDER BY t.name ASC;

-- Audit 2: Identify any orphaned taxonomy records with zero associations
SELECT 
    tt.term_taxonomy_id,
    tt.term_id,
    t.name,
    tt.taxonomy
FROM wp_term_taxonomy tt
LEFT JOIN wp_terms t ON tt.term_id = t.term_id
WHERE tt.count = 0 
  AND tt.taxonomy = 'category';

-- ----------------------------------------------------------------------------
-- 7. Transaction Finalization
-- ----------------------------------------------------------------------------
COMMIT;

SET foreign_key_checks = 1;

-- To undo changes before commit, execute:
-- ROLLBACK;
