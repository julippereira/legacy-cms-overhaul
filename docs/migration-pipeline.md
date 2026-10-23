# Historical Content Migration Pipeline: Google Blogger to Self-Hosted WordPress

Technical specification, Extract-Transform-Load (ETL) runbook, and database remediation documentation for the **Sepulchral Voice Fanzine** legacy content migration.

---

## 1. Architectural Overview & Ingestion Context

The *Sepulchral Voice Fanzine* digital archive originally resided on Google Blogger (`*.blogspot.com`) from its inception (circa 2007) through its transition to a self-hosted WordPress infrastructure.

Due to architectural incompatibilities between Blogger's flat document-store model and WordPress's normalized relational schema (`InnoDB`), raw automated XML imports introduced systemic data integrity issues. This pipeline documents the audit, ingestion mechanics, taxonomy re-structuring, and SQL data remediation workflows required to stabilize the production archive.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        UPSTREAM INGESTION (ETL)                        │
│  Google Blogger XML Export (Atom) ──> WP Importer Core Parsing         │
│  Flat Label Mapping               ──> Unstructured Taxonomy Tables     │
│  External Media Embeds            ──> Static Host Dependencies         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                    SCHEMA NORMALIZATION & REMEDIATION                  │
│  sql/taxonomy-migration.sql       ──> Taxonomy Categorization & Resync │
│  sql/search-replace-ssl.sql       ──> Domain Rewrites & SSL Enforcing  │
│  wp-content/uploads/              ──> Media Relinking & Local Hosting  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       PRODUCTION PRESENTATION                          │
│  child-theme/archive.php          ──> Standardized CSS Grid (4-Col)    │
│  child-theme/style.css            ──> Responsive Editorial Styling     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Ingestion Mechanics (Phase 1: Extraction & Staging)

### 2.1 Extraction (Source Environment)
- **Source:** Google Blogger Export Tool (`blog-MM-DD-YYYY.xml`).
- **Protocol:** Atom 1.0 XML syndication format containing post bodies, comments, timestamp metadata, author tags, and untyped label elements.

### 2.2 Transform & Load (Staging Ingestion)
- **Engine:** WordPress Core XML Importer (`wordpress-importer` plugin / WP-CLI).
- **Execution:**
  ```bash
  wp import blog-archive.xml --authors=mapping.csv --skip=attachment
  ```
- **Post-Import Artifacts:**
  - Post entities successfully staged into `wp_posts` with `post_type = 'post'`.
  - Nested historical permalink structures retained in post metadata (`/yyyy/mm/slug.html`).
  - Google user profile links mapped to administrative author IDs.

---

## 3. Upstream Technical Debt & Structural Mismatches

| Domain | Google Blogger Origin | WordPress Relational Model | Impact / Technical Debt |
| :--- | :--- | :--- | :--- |
| **Taxonomies** | Flat `term` labels. No hierarchy. | Two-tier relational (`category` vs. `post_tag`). | 100% of labels imported as flat tags, leaving primary categories unpopulated. |
| **Media Storage** | Google UserContent CDN (`bp.blogspot.com`, `lh3.googleusercontent.com`). | Local filesystem (`wp-content/uploads/YYYY/MM/`). | Broken images due to referer blocking, third-party link rot, and HTTP mixed content. |
| **Permalinks** | Date-based `.html` static endpoints (`/2008/11/post.html`). | Canonical rewrite rules (`/%postname%/`). | 404 indexing errors and broken internal backlink topologies. |
| **Encodings** | Mixed legacy Latin-1 / UTF-8 entity fragments. | `utf8mb4_unicode_ci` / `utf8mb4_520_ci`. | Broken diacritics, typography symbols, and corrupted quote entities. |

---

## 4. Remediation & Transformation Runbook (Phase 2: Database Layer)

### 4.1 Step 1: Media Localization & Host Decoupling
Blogger images referenced direct CDN paths. Assets were extracted and rematerialized into local storage to guarantee permanent preservation:

1. **Extraction:** Downloaded all external assets matching `*.googleusercontent.com` and `*.blogspot.com` paths referenced in `post_content`.
2. **Directory Mount:** Placed into `wp-content/uploads/imported-archive/`.
3. **Database Remapping:** Executed targeted SQL string replacement routines to redirect requests from remote origins to local media stores:
   ```sql
   UPDATE wp_posts 
   SET post_content = REPLACE(post_content, 'http://1.bp.blogspot.com/', 'https://sepulchralvoicefanzine.com/wp-content/uploads/imported-archive/')
   WHERE post_type = 'post';

   UPDATE wp_posts 
   SET post_content = REPLACE(post_content, 'http://2.bp.blogspot.com/', 'https://sepulchralvoicefanzine.com/wp-content/uploads/imported-archive/')
   WHERE post_type = 'post';
   ```

### 4.2 Step 2: Taxonomy Restructuring & Entity Deduplication
Blogger's untyped labels resulted in hundreds of redundant, synonymous, or malformed taxonomy associations.

The transformation script (`sql/taxonomy-migration.sql`) enforced the following operations:
- **Taxonomy Elevation:** Elevated broad editorial labels (*Notícias*, *Entrevistas*, *Edições*, *Shows & Eventos*) from `post_tag` to first-class `category` entries in `wp_term_taxonomy`.
- **Deduplication:** Merged overlapping synonym terms (e.g., `interview`, `interviews`, `entrevista` $\rightarrow$ `Entrevistas`) by updating `wp_term_relationships.term_taxonomy_id` and deleting redundant records.
- **Relational Count Resynchronization:** Recomputed real-time association counts for all terms against published posts:
  ```sql
  UPDATE wp_term_taxonomy tt 
  SET tt.count = (
      SELECT COUNT(tr.object_id)
      FROM wp_term_relationships tr
      INNER JOIN wp_posts p ON tr.object_id = p.ID
      WHERE tr.term_taxonomy_id = tt.term_taxonomy_id
        AND p.post_status = 'publish'
        AND p.post_type = 'post'
  );
  ```

### 4.3 Step 3: Global SSL/TLS Protocol & Host Consolidation
To guarantee compliance with modern transport security standards and eliminate mixed-content browser flags, `sql/search-replace-ssl.sql` was executed with transactional safety:

- Migrated all primary options (`home`, `siteurl`) to enforce `https://sepulchralvoicefanzine.com`.
- Sanitized internal hyperlinks, embedded assets, and metadata fields across `wp_posts`, `wp_postmeta`, and `wp_comments`.
- Guarded against corruption of serialized PHP structures (`WHERE meta_value NOT LIKE 'a:%' AND meta_value NOT LIKE 'O:%'`).

---

## 5. Verification & Validation Metrics

Following the pipeline execution, systematic validation queries confirmed zero data degradation:

```sql
-- Metric 1: Verify absence of insecure HTTP references
SELECT COUNT(*) AS remaining_http_references 
FROM wp_posts 
WHERE post_content LIKE '%http://sepulchralvoicefanzine.com%'
   OR post_content LIKE '%http://%.blogspot.com%';
-- Expected Result: 0

-- Metric 2: Verify zero orphaned taxonomy relationship records
SELECT COUNT(*) AS orphaned_relationships
FROM wp_term_relationships tr
LEFT JOIN wp_term_taxonomy tt ON tr.term_taxonomy_id = tt.term_taxonomy_id
WHERE tt.term_taxonomy_id IS NULL;
-- Expected Result: 0

-- Metric 3: Verify core category assignment distribution
SELECT 
    t.name AS category_name,
    t.slug,
    tt.count AS live_post_count
FROM wp_terms t
JOIN wp_term_taxonomy tt ON t.term_id = tt.term_id
WHERE tt.taxonomy = 'category'
ORDER BY tt.count DESC;
-- Expected Result: Consistent, non-zero values across primary editorial categories
```

---

## 6. Maintenance & Operational Sign-off

- **Rollback Safety:** All migrations are encapsulated in explicit transactions (`START TRANSACTION` / `COMMIT`) with snapshot staging tables (`_bkp_*`).
- **Archive Display:** Downstream rendering is handled by `child-theme/archive.php` and `child-theme/style.css`, mapping the newly classified categories into a standardized, symmetric 4-column CSS Grid.
- **Sign-off Status:** Production Database Remediated & Validated. Data pipeline successfully executed and archived.
