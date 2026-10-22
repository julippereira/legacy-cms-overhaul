# Sepulchral Voice Fanzine — Legacy Data Migration & Editorial CMS Architecture

End-to-end legacy migration pipeline, taxonomy restructuring, and front-end customization for the historical archive of **Sepulchral Voice** fanzine (an independent underground Heavy Metal publication active since 2007).

This project encompassed the extraction and sanitization of unstructured data from Google Blogger, relational metadata remodeling within WordPress, hosting infrastructure provisioning, and reverse engineering the **Full Frame** theme via a custom Child Theme (PHP Core Hooks & Modern CSS Grid).

---

## 1. Challenge Overview

The Sepulchral Voice archive holds nearly two decades of reviews, interviews, gig reports, and underground heavy metal historical documentation. The legacy infrastructure hosted on Blogger imposed severe constraints on scalability, layout control, and data governance.

### Core Technical Bottlenecks:
- **Corrupted Taxonomy on Ingestion:** The default Blogger-to-WordPress exporter converted thousands of flat labels directly into standalone primary categories, resulting in an unnormalized, bloated taxonomy.
- **Loss of Temporal Hierarchy:** Lack of structured chronological partitioning (by year and month) for archival exploration.
- **Monolithic Legacy Layout:** The parent theme (*Full Frame*) relied on legacy float/clear mechanics, hard-coded wrapper max-widths, and rigid core hooks that prevented balanced grid layouts and responsive pagination.

---

## 2. Solution Architecture & Data Pipeline
```
┌──────────────────┐       ┌────────────────────────┐       ┌────────────────────────┐
│  Google Blogger  │ ----> │  Extract & Transform   │ ----> │ WordPress Core (MySQL) │
│ (XML / 2007-2026)│       │ (Initial Sanitization) │       │   (Clean Taxonomies)   │
└──────────────────┘       └────────────────────────┘       └────────────────────────┘
│
▼
┌──────────────────────────┐       ┌────────────────────────┐       ┌────────────────────────┐
│   UI/UX: Full Frame      │ <---- │ PHP Hooks & Core Logic │ <---- │ Temporal Partitioning  │
│ (4-Col Grid / No-Floats) │       │ (Archive / Pagination) │       │ (Year / Month / Macro) │
└──────────────────────────┘       └────────────────────────┘       └────────────────────────┘
```

### 2.1. Taxonomy Modeling & Sanitization
1. **Dimensional Metadata Conversion (Categories to Tags):** Executed database scripting and taxonomy conversion routines to reclassify thousands of flat labels into contextual *Post Tags*, eliminating indexing redundancies.
2. **Hierarchical Macro-Category Schema:** Restructured the publishing model around well-defined editorial entities:
   - `Edições` (Print Zine Issues)
   - `Entrevistas` (Interviews)
   - `Notícias` (News & Press Releases)
   - `Shows` (Live Gig Coverage)
   - `Arquivos do Site` (Historical Archives)
3. **Temporal Archival Indexing:** Implemented date-based partitioning by year and month to allow fast navigation across legacy archives without query performance penalties.

---

## 3. Theme Engineering & Front-end Overhaul (Child Theme)

To transform the interface into a brutalist, balanced black-and-white editorial catalog, the parent theme core underwent key structural overrides:

### 3.1. Archive Loop Restructuring (`archive.php`)
- **Sequential Layout Removal:** Deprecated the native linear stream layout in favor of an independent card grid with a strict `1:1 aspect-ratio` container and aligned metadata.
- **Dynamic Excerpt Sanitation:** Standardized teaser lengths using explicit token trimming (`wp_trim_words`) paired with unified inline calls-to-action (`Read more →`), preventing vertical tile misalignments.

### 3.2. WordPress Hook Overrides (`functions.php`)
- **Archive Title Prefix Stripping:** Programmatically removed default WordPress label prefixes (`Category:`, `Archives:`) via the `get_the_archive_title_prefix` filter.
- **Pre-query Optimization:** Intercepted the main query lifecycle through `pre_get_posts` to lock `posts_per_page` to multiples of 4 (12 or 16 posts) strictly on taxonomy archives, preventing orphan grid slots and 404 pagination errors on `paged` routes.
- **Decoupled Footer Injection:** Unhooked the native hardcoded action `fullframe_footer_content` and injected a custom dynamic component featuring the historical date range (`2007 - Present`) and custom publisher credentials.

### 3.3. Style Modernization & CSS Inheritance Break (`style.css`)
- **Modern CSS Grid Adoption:** Eliminated theme-level float clearings (`.clearfix:after`, manual floats) and enforced `grid-template-columns: repeat(4, minmax(0, 1fr))` with `min-width: 0` constraints to eliminate overflow and keep columns aligned.
- **Edge-to-Edge UI (100vw Viewport Scaling):** Bypassed the hardcoded 1280px container constraints of `.wrapper` using negative viewport-relative horizontal margins (`calc(-50vw + 50%)`) to achieve full-bleed header imagery and footer elements.

---

## 4. Tech Stack & Infrastructure

- **CMS & Application Layer:** WordPress 6.x, PHP 8.x
- **Front-end & Styling:** Modern CSS3 (CSS Grid, Flexbox, Media Queries, Viewport Units)
- **Database:** MySQL (Relational cleanup across `wp_terms`, `wp_term_taxonomy`, and `wp_term_relationships`)
- **Infrastructure & Hosting:** DNS Zone management, SSL certificate enforcement, and web server configuration on Hostinger

---

## 5. Repository Structure

```text
├── child-theme/
│   ├── archive.php           # 4-column full-width responsive grid archive template
│   ├── functions.php         # pre_get_posts query hooks, title filters, and footer overrides
│   └── style.css             # Float clearing overrides, CSS Grid rules, and full-bleed layout
├── docs/
│   ├── migration-pipeline.md # Step-by-step documentation for Blogger data extraction
│   └── screenshots/          # Before/after UI comparisons and grid responsiveness
└── README.md
```

## 6. Key Outcomes

Historical Preservation: 100% of data generated since 2007 was preserved and migrated into a clean, normalized relational model.

Optimized Information Architecture: Consolidated hundreds of redundant category labels into 5 clear macro-categories supported by controlled vocabulary tags.

Visual Symmetry & Stability: Fast, responsive layout with uniform card heights regardless of the original image dimensions.

