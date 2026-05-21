# Publish

## Status

Published Power BI portfolio handoff ready.

## Public Dashboard

[View the published Power BI dashboard](https://app.powerbi.com/view?r=eyJrIjoiNjgyMTFlMGUtZGI1YS00NGMyLTk0ZmEtODUxODRlMzE2NWYzIiwidCI6IjM3MGZiM2I4LTMzMDYtNDg5MC05MDYzLWNjMDhiZTc4ODI1NyIsImMiOjEwfQ%3D%3D)

## Publish Notes

- Preferred public portfolio surfaces: GitHub repository plus Power BI public report link.
- Visualization tool: Power BI.
- Deploy target: Power BI Service public report plus local Power BI Desktop handoff.
- Prepared data contract: `docs/assets/exports/fact-banking-transactions-star.csv`.
- Validation report: `docs/validation-report.md`.
- Deployment guide: `docs/deployment-guide.md`.

## Power BI Delivery

- Public viewers should use the published Power BI URL above.
- Local reviewers can open the `.pbix` report in Power BI Desktop from `powerbi/`.
- Keep Power Query notes, DAX measure definitions, and screenshots in `docs/`.
- Treat service refresh settings, gateway configuration, workspace IDs, credentials, and tokens as private operational configuration outside source control.

## Checklist

1. Validate docs completeness.
2. Confirm project workspace is commit-ready.
3. Include Power BI `.pbix` files under `powerbi/`.
4. Include screenshots under `docs/assets/screenshots/`.
5. Verify no credentials, gateway secrets, refresh tokens, or private workspace settings are in source files.
6. Confirm daily historical FX rates and `FXRateDate` are visible in the audit/drillthrough layer.
7. Run `python tools/build-banking-star-schema.py` and confirm validation totals.
8. Confirm README links to the published Power BI dashboard.

## Unresolved Questions

- None.
