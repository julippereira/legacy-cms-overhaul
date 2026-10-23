-- ============================================================================
-- Script: search-replace-ssl.sql
-- Description: Sanitizes legacy HTTP URLs across WordPress core tables to 
--              enforce HTTPS, eliminate mixed-content warnings, and preserve
--              media asset links following SSL/TLS provisioning.
-- Target DB: MySQL 8.x / MariaDB 10.x (WordPress Core Schema)
-- Engine: InnoDB
-- Author: Juliana R Pereira
-- Date: October 2026
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Safety Checks & Session Configuration
-- ----------------------------------------------------------------------------
SET NAMES utf8mb4;
SET foreign_key_checks = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES';

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Backup Snapshots (Temporary staging for rollback verification)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS _bkp_wp_options_ssl;
DROP TABLE IF EXISTS _bkp_wp_posts_ssl;
DROP TABLE IF EXISTS _bkp_wp_postmeta_ssl;
DROP TABLE IF EXISTS _bkp_wp_comments_ssl;

CREATE TABLE _bkp_wp_options_ssl AS SELECT * FROM wp_options;
CREATE TABLE _bkp_wp_posts_ssl AS SELECT * FROM wp_posts;
CREATE TABLE _bkp_wp_postmeta_ssl AS SELECT * FROM wp_postmeta;
CREATE TABLE _bkp_wp_comments_ssl AS SELECT * FROM wp_comments;

-- ----------------------------------------------------------------------------
-- 2. Core Site URL Definitions (wp_options)
--    Updates base home and siteurl directives to enforce HTTPS.
-- ----------------------------------------------------------------------------
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com') 
WHERE option_name IN ('home', 'siteurl');

-- Handle potential www variants if historical redirects exist
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'http://www.sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com') 
WHERE option_name IN ('home', 'siteurl');

-- ----------------------------------------------------------------------------
-- 3. Post & Page Content Strings (wp_posts)
--    Remediates inline image tags, anchor links, and embedded asset references.
-- ----------------------------------------------------------------------------
UPDATE wp_posts 
SET post_content = REPLACE(post_content, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com')
WHERE post_content LIKE '%http://sepulchralvoicefanzine.com%';

UPDATE wp_posts 
SET post_content = REPLACE(post_content, 'http://www.sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com')
WHERE post_content LIKE '%http://www.sepulchralvoicefanzine.com%';

-- ----------------------------------------------------------------------------
-- 4. Media Attachments & Canonical GUIDs (wp_posts)
--    Updates media file URLs (wp-content/uploads) and attachment references.
-- ----------------------------------------------------------------------------
UPDATE wp_posts 
SET guid = REPLACE(guid, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com')
WHERE post_type = 'attachment'
  AND guid LIKE '%http://sepulchralvoicefanzine.com%';

-- ----------------------------------------------------------------------------
-- 5. Custom Fields & Attachment Metadata (wp_postmeta)
--    Updates plain text image paths and custom meta values.
--    NOTE: Do NOT apply raw REPLACE on serialized arrays. This targets plain strings.
-- ----------------------------------------------------------------------------
UPDATE wp_postmeta 
SET meta_value = REPLACE(meta_value, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com')
WHERE meta_value LIKE '%http://sepulchralvoicefanzine.com%'
  AND meta_value NOT LIKE 'a:%' 
  AND meta_value NOT LIKE 'O:%';

-- ----------------------------------------------------------------------------
-- 6. Historical User Comments & Trackbacks (wp_comments)
-- ----------------------------------------------------------------------------
UPDATE wp_comments 
SET comment_content = REPLACE(comment_content, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com')
WHERE comment_content LIKE '%http://sepulchralvoicefanzine.com%';

UPDATE wp_comments 
SET comment_author_url = REPLACE(comment_author_url, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com')
WHERE comment_author_url LIKE '%http://sepulchralvoicefanzine.com%';

-- ----------------------------------------------------------------------------
-- 7. Verification Audit Queries (Confirm zero remaining insecure references)
-- ----------------------------------------------------------------------------

-- Check core options
SELECT option_name, option_value 
FROM wp_options 
WHERE option_name IN ('home', 'siteurl');

-- Count any remaining insecure HTTP references in published content
SELECT COUNT(*) AS remaining_insecure_posts 
FROM wp_posts 
WHERE post_content LIKE '%http://sepulchralvoicefanzine.com%';

-- Count any remaining insecure GUID references
SELECT COUNT(*) AS remaining_insecure_guids 
FROM wp_posts 
WHERE guid LIKE '%http://sepulchralvoicefanzine.com%';

-- ----------------------------------------------------------------------------
-- 8. Commit Changes
-- ----------------------------------------------------------------------------
COMMIT;

SET foreign_key_checks = 1;

-- If audit queries show unexpected anomalies before commit:
-- ROLLBACK;
