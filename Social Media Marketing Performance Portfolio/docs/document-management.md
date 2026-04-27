# Document Management

## Status

Project docs are normalized under `projects/social-media-marketing-performance-portfolio/docs/`.

## Current Doc Set

- `project-brief.md`
- `project-plan.md`
- `data-preparation.md`
- `visualization.md`
- `publish.md`
- `design-guidelines.md`
- `document-management.md`

## Asset Locations

- Source workbook: `docs/assets/user-files/`
- Prepared exports: `docs/assets/exports/`
- Screenshots: `docs/assets/screenshots/`

## Latest Sync

- Updated project brief and plan for the Onyx June 2024 challenge.
- Locked full workbook as dashboard default; challenge scope remains available in the data model, not as a dashboard filter.
- Documented country derivation from the source `Region` field.
- Documented `promotion_type` derivation from `Content_Type`.
- Refreshed data-preparation notes for scope, geography, promotion type, and correlation mart outputs.
- Refreshed visualization notes for the Metabase path, 7 active filters, and 28-card dashboard.
- Refreshed publish notes for Supabase and Metabase handoff.

## Notes

- Project outputs are intentionally kept inside the project workspace.
- Local stack files live in project root and `postgres/` because they are runtime assets, not loose docs artifacts.
- The local Metabase app and public dashboard are reachable; future dashboard reseeding needs valid admin credentials.

## Unresolved Questions

- None.
