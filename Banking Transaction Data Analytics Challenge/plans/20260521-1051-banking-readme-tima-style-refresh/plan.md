---
title: "Banking Docs TIMA-Style Refresh Plan"
description: "Refresh Banking project docs to mirror TIMA README presentation patterns without changing Banking content."
status: completed
priority: P2
effort: 2h
branch: main
tags: [documentation, readme, powerbi, portfolio]
created: 2026-05-21
---

# Overview
- Goal: restyle Banking project docs to borrow TIMA's presentation format only: strong intro, table of contents, highlights table, repo structure, run flow, dashboard section.
- Preserve: Banking metrics, Banking file paths, existing screenshots/assets, local Power BI Desktop handoff, and the user-provided public Power BI URL verbatim.

# Scope
- Primary file: `README.md`
- Sync files: `docs/publish.md`, `docs/deployment-guide.md`
- Optional only if cross-links drift: `docs/visualization.md`

# Style Delta From TIMA
- Add concise hero/subtitle and short project tagline.
- Reorder README into: overview, highlights, dataset snapshot, repository structure, workflow/how to run, dashboard, findings, limitations/next steps.
- Use compact tables where they improve scan speed; reuse Banking facts only.
- Keep Banking domain language; remove any chance of TIMA loan/SQL Server/modeling content leaking in.

# Data Flow
- Input: current Banking README + publish/deployment docs + current asset/file inventory.
- Transform: map Banking content into TIMA-like structure, tighten wording, keep links/metrics literal.
- Output: refreshed Markdown docs only; no edits to CSV, `.pbix`, screenshots, or scripts.

# Phases
1. Audit current README sections against TIMA structure and freeze Banking source facts.
2. Rewrite `README.md` structure and copy using Banking metrics/files only.
3. Align `docs/publish.md` and `docs/deployment-guide.md` terminology with the new README structure.
4. Validate links, metrics, file paths, and Power BI wording; fix drift.

# Dependencies / Ownership
- Blocker before rewrite: confirm canonical Banking metrics from current `README.md`.
- `README.md` owns structure; sync docs must follow after README wording settles.
- Single-owner sequence only; no parallel edits on the same files.

# Risks
- High: accidental TIMA content leakage. Mitigation: grep for `TIMA|loan|SQL Server|XGBoost|CRM`.
- Medium: metric/file drift during rewrite. Mitigation: copy metrics and paths from current Banking docs verbatim, then diff-check.
- Medium: broken relative links after section moves. Mitigation: validate every Markdown link target locally.

# Backward Compatibility / Rollback
- Keep existing file names and relative asset paths unchanged so GitHub rendering and local Power BI instructions still work.
- Rollback: revert only `README.md`, `docs/publish.md`, `docs/deployment-guide.md`, and optionally `docs/visualization.md`; no data migration needed.

# Validation
- Verify README still reports: `20,000` transactions, `8,025` customers, USD totals, fee totals, and high-fee count exactly.
- Verify referenced files still exist: `powerbi/*.pbix`, `docs/assets/screenshots/*`, `docs/assets/reports/banking-transaction-analytics.pdf`, `docs/assets/exports/*`.
- Verify the public Power BI URL matches the user-provided URL exactly.
- Run content grep to confirm no unrelated TIMA strings remain.
- Preview Markdown for heading order, tables, and image rendering.

# Success Criteria
- README feels closer to TIMA presentation style while staying 100% Banking-specific.
- Only documentation files change.
- All existing Banking links, metrics, and asset references remain valid.

**Status:** DONE
**Summary:** Concise implementation plan completed for a TIMA-style documentation refresh that preserves Banking facts/files and adds the user-provided Power BI publication URL.
**Concerns/Blockers:** None.
