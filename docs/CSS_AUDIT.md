# CSS Audit Report

## 1. Imports Audit
- **Files:** `app/css/style.css`
- **Status:** All imports are present.
- **Circular dependencies:** None detected.
- **Order:** Tokens -> Base -> Components -> Layouts (Correct).

## 2. Design Tokens Audit
- **Hardcoded values found:**
  - `backdrop-filter: blur(10px)` (in `cards.css`)
  - `transform: translateY(-5px)` (in `cards.css`)
  - `1px solid` (border definition)

## 3. CSS Audit
- **!important:** 0 occurrences.
- **Duplicates:** None detected.
- **Specificity:** Generally low.
- **Long selectors:** Minimal.

## 4. Components Audit
- Components do not import layouts.
- Layouts do not import components.
- Tokens are properly used as dependencies.

## 5. Repository Audit
- Orphan files identified: The search identified many Nextcloud core/app CSS files in the root, but they are unrelated to the `app/` folder (the single source of truth). No Savarez app orphan files detected in `app/`.

## 6. Metrics
- **Number of CSS files:** 18
- **Number of tokens:** 5
- **Number of selectors:** ~9 in design system core.
- **!important count:** 0
- **Hardcoded values count:** ~3 (potential for further tokenization)
- **Orphan files:** 0 (within `app/` scope)

## 7. Recommendations
- Tokenize `backdrop-filter` and `transform` values.
- Consolidate common border definitions into a token.
