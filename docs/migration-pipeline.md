# Data Migration & Taxonomy Normalization Pipeline

This document details the step-by-step extraction, sanitization, relational remodeling, and ingestion pipeline used to migrate the **Sepulchral Voice Fanzine** historical archive (2007–2026) from Google Blogger to WordPress.

---

## 1. Extraction Phase (Blogger Export)

### 1.1 Source Ingestion
The source platform (Google Blogger) exported the entire content body into an Atom XML format containing posts, pages, comments, and inline metadata:
* **Export File:** `blog-MM-DD-YYYY.xml`
* **Data Volume:** Hundreds of long-form articles, review features, and interview records accumulated across 19 years.
* **Format:** Flat XML document containing nested `<entry>` nodes.

### 1.2 Data Anomalies Identified at Source:
1. **Unconstrained Taxonomies:** Blogger labels were represented as unconstrained `<category scheme="http://www.blogger.com/atom/ns#" term="..."/>` tags.
2. **Missing Post-Type Differentiation:** Static pages, drafts, published posts, and comments coexisted within the same XML stream.
3. **Hardcoded Legacy Assets:** Static asset URLs referencing deprecated Picasa/Google UserContent CDNs (`bp.blogspot.com`).

---

## 2. Ingestion & Initial Import (WordPress Importer)

The initial ingestion was executed using the native Blogger-to-WordPress ingestion engine within a staging environment.

### The Primary Ingestion Bottleneck:
The default importer converted every single Blogger label into an isolated, first-class WordPress **Category** (`taxonomy = 'category'`).
* **Resulting Failure State:** More than 1,000 flat, redundant categories were created.
* **Impact:** Loss of dimensional hierarchy, unusable navigation, and critical database bloat across the `wp_terms` and `wp_term_taxonomy` tables.

---

## 3. Taxonomy Normalization & Sanitization

To restore information architecture integrity, data remodeling was split into three stages:

### 3.1 Bulk Conversion: Categories $\to$ Tags
Using automated database routines and the WordPress Taxonomy Converter, all flat labels imported from Blogger were converted from primary categories into contextual tags:
* Changed metadata relationships from `taxonomy = 'category'` to `taxonomy = 'post_tag'`.
* Preserved the original tagging granularity for search engine discovery and entity indexing.

```sql
-- Schema alignment conceptual example:
-- Relinking orphan terms to the post_tag taxonomy
UPDATE wp_term_taxonomy 
SET taxonomy = 'post_tag' 
WHERE taxonomy = 'category' 
  AND term_id NOT IN (/* Protected Macro-Category IDs */);
