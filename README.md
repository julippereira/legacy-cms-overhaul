# Sepulchral Voice Fanzine — Legacy CMS Overhaul & Archive Standardization

Technical documentation covering the restoration, structural modernization, database remediation, and visual standardization of the **Sepulchral Voice Fanzine** editorial portal (WordPress / Full Frame Child Theme).

---

## 📌 Context & Objectives

This project rescued and stabilized the digital infrastructure of an underground print publication, migrating the legacy environment to end-to-end HTTPS/SSL, sanitizing mixed-content database references, and refactoring historical release archives into a modern, symmetric CSS Grid layout.

### Key Deliverables:
- **Security & Data Sanitation:** Provisioned SSL/TLS certificates and executed automated SQL routines to remediate mixed-content URL strings across core WordPress tables.
- **Editorial Archive Standardization:** Overrode the legacy blog index flow via a custom `archive.php` template combined with a 4-column CSS Grid (`.archive-gallery-grid`).
- **Edge-to-Edge Visual Identity:** Implemented a panoramic full-bleed header banner (`100vw`), eliminating letterboxing and native parent-theme black borders.
- **Custom Institutional Footer:** Stripped third-party theme attribution links, integrating a continuous editorial copyright notice (**Copyright © 2007 – 2026 Sepulchral Voice**) alongside direct technical development attribution.

### 🔄 Upstream Migration Heritage (Blogger / Blogspot)
The portal's digital archive originated on the **Google Blogger** platform before transitioning to self-hosted WordPress. This legacy upstream pipeline introduced significant technical debt:
- **Hardcoded Image Assets & Canonical Links:** Lingering references to `*.blogspot.com` domains and legacy Google UserContent CDNs.
- **Permalink & Slug Inconsistencies:** Nested `/yyyy/mm/post-title.html` historical permalink structures conflicting with modern rewrite rules.
- **Taxonomy Flattening:** Blogger's single-tier "labels" were imported into WordPress without relational hierarchies, causing duplicate entries, untyped tags, and broken term post counts.
---

## 🏗️ Architecture & Component Design

The overhaul follows a clean separation of concerns across template rendering, visual styling, data migration routines, and operational documentation:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        LEGACY INGESTION PIPELINE                       │
│  Google Blogger XML Export  ──> WordPress Importer (Historical Ingest) │
│  Raw Label Import           ──> Fragmented Taxonomy & Nested Slugs     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                         DATA & STORAGE LAYER                           │
│  sql/search-replace-ssl.sql ──> HTTPS Migration & Host Remapping       │
│  sql/taxonomy-migration.sql ──> Term Consolidation & Count Resync      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│  child-theme/archive.php    ──> Custom Loop & CSS Grid DOM             │
│  child-theme/style.css      ──> Layout Overrides (Full-Bleed, Grid)    │
│  child-theme/functions.php  ──> Asset Enqueue & Hook Filters (Footer)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       DOCUMENTATION & AUDIT                            │
│  docs/migration-pipeline.md ──> Detailed Data Transformation Runbook   │
│  docs/screenshots/          ──> Visual Verification Deliverables       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📸 Visual Assets (Screenshots)

### 1. Editorial Archive Grid (Desktop)
Standardized multi-column layout displaying album releases and news items with normalized typography and cover dimensions.

![Editorial Archive Grid](docs/screenshots/desktop-archive-grid.png)

### 2. Historical Taxonomy & Categorized Archive
Chronological release archives filtered by category and metadata taxonomies.

![Categorized Historical Archive](docs/screenshots/desktop-taxonomy-archive.png)

### 3. Edge-to-Edge Panoramic Header
Full-bleed header banner layout spanning the entire viewport width.

![Panoramic Header](docs/screenshots/header-full-bleed.png)

### 4. Institutional Custom Footer
Streamlined editorial footer with persistent copyright and clean attribution.

![Custom Footer](docs/screenshots/footer-custom.png)

---

## 🛠️ Tech Stack

- **CMS Engine:** WordPress
- **Base Theme:** Full Frame (Catch Themes)
- **Custom Layer:** Dedicated Child Theme (`archive.php`, `functions.php`, `style.css`), CSS Grid, Flexbox
- **Database & Hosting:** PHP 8.x, MySQL / MariaDB, Hostinger / LiteSpeed Cache

---

## 💻 Implementation Highlights

### 1. Database URL Remediation (`sql/search-replace-ssl.sql`)
Eliminated browser mixed-content warnings post-SSL provisioning without dynamic rewriting plugins, applying transactional SQL routines with serialized string protection (`NOT LIKE 'a:%' AND NOT LIKE 'O:%'`):

```sql
-- Site URL Configuration
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com') 
WHERE option_name IN ('home', 'siteurl');

-- Post & Page Content Strings
UPDATE wp_posts 
SET post_content = REPLACE(post_content, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com');

-- Post Metadata & Custom Fields (Non-serialized only)
UPDATE wp_postmeta 
SET meta_value = REPLACE(meta_value, 'http://sepulchralvoicefanzine.com', 'https://sepulchralvoicefanzine.com')
WHERE meta_value NOT LIKE 'a:%' AND meta_value NOT LIKE 'O:%';
```

### 2. Taxonomy Consolidation (`sql/taxonomy-migration.sql`)
Standardized historical slugs, eliminated orphaned term taxonomies, and synchronized live post counters across categories and tags.

### 3. Symmetric Archive Grid (`child-theme/style.css` & `archive.php`)
Replaced the single-column stacked blog flow with a robust 4-column CSS Grid:

```css
/* Standardized Editorial 4-Column Grid */
.archive-gallery-grid {
    display: grid !important;
    grid-template-columns: repeat(4, minmax(0, 1fr)) !important;
    gap: 24px !important;
    width: 100% !important;
    margin: 30px auto !important;
    box-sizing: border-box !important;
}

.archive-gallery-grid .gallery-post-thumbnail img {
    width: 100% !important;
    aspect-ratio: 1 / 1 !important;
    object-fit: cover !important;
    display: block !important;
}
```

### 4. Edge-to-Edge Panoramic Header (`child-theme/style.css`)
Broke out of native container restrictions to ensure full-bleed image presentation across high-resolution displays:

```css
#header-featured-image {
    width: 100vw !important;
    position: relative !important;
    left: 50% !important;
    right: 50% !important;
    margin-left: -50vw !important;
    margin-right: -50vw !important;
    overflow: hidden !important;
}
```

---

## 📝 Known Issues & Technical Roadmap

### Mobile Navigation Drawer (Technical Debt / Backlog)
- **Root Cause Analysis:** The parent theme tightly couples legacy DOM-manipulation scripts (`Sidr.js`) with rigid inline styles on `#fixed-header`. During mobile refactoring, automated breakpoints conflicted with fixed positioning rules, causing duplicate drawer triggers and text overlap.
- **Architectural Decision:** To safeguard desktop production stability and preserve the newly implemented archive grid, aggressive CSS overrides were paused for this release cycle.
- **Planned Refactor:** Dequeue `fullframe-custom.js` via `wp_dequeue_script()` and override the template in `header.php` to deploy a lightweight, dependency-free CSS-first mobile drawer.

---

## 📂 Repository Structure

```text
.
├── child-theme/
│   ├── archive.php           # Custom template loop for standardized archive layout
│   ├── functions.php         # Hooks, asset management, and footer filters
│   └── style.css             # CSS Grid layout, typography, and full-bleed overrides
├── docs/
│   ├── migration-pipeline.md # Detailed data pipeline runbook and validation logs
│   └── screenshots/          # Visual verification deliverables
│       ├── desktop-archive-grid.png
│       ├── desktop-taxonomy-archive.png
│       ├── footer-custom.png
│       └── header-full-bleed.png
├── sql/
│   ├── search-replace-ssl.sql # URL remediation queries for HTTPS migration
│   └── taxonomy-migration.sql # Category deduplication and count synchronization
├── .gitignore
└── README.md
```

---

## 🚀 Deployment & Environment Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/julianareginap/legacy-cms-overhaul.git
   ```
2. **Deploy the Child Theme:**
   * Copy `child-theme/` to `wp-content/themes/full-frame-child/`.
   * Activate the child theme via **Appearance > Themes**.
3. **Execute Database Migrations:**
   * Run `sql/search-replace-ssl.sql` and `sql/taxonomy-migration.sql` in phpMyAdmin or via WP-CLI.
4. **Purge Cache:**
   * Clear Hostinger Server Cache and LiteSpeed Cache to ensure updated CSS rules take immediate effect.

---

## 📄 License
This project documentation and custom child-theme overrides are released under the [MIT License](LICENSE).
