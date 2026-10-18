# BOSS Zhipin Selected Field Export v2.5.0

> This is IthaiT's personal fork of [eatmoreduck/boss-zhipin-scraper](https://github.com/eatmoreduck/boss-zhipin-scraper). Version `2.5.0` identifies this custom fork, not an official upstream release. Original authorship and the MIT license are retained.

Clone this repository; its default `master` branch contains the custom version:

```bash
git clone https://github.com/IthaiT/boss-zhipin-scraper.git
cd boss-zhipin-scraper
```

Export only the 32 user-approved job fields to JSON and CSV. Descriptions, responsibilities, requirements, and company introductions are copied from the source text without AI rewriting. Missing values remain empty; skills remain a source array.

## Usage

```bash
python scripts/boss_cdp_raw.py --check
# Only when CDP is unavailable; use --setup-edge for Edge
python scripts/boss_cdp_raw.py --setup-chrome
python scripts/boss_cdp_raw.py --keyword "嵌入式软件工程师" --city 深圳 --pages 3 --output jobs.json
```

Python 3.10+, `requests`, and `websocket-client` are required. The default output is `jobs.json` plus `jobs.csv`, with the same 32 fields per job. JSON retains keyword, city, total, and a `jobs` array at the top level. `--format json` writes JSON only; `--detail-output` is an optional extra copy with the same fields.

## Fields

```text
city title company salary
location experience_education_tags experience_requirement education_requirement
company_scale company_stage company_industry company_welfare
boss_title boss_active_status job_link job_description
job_responsibilities job_requirements skills work_address
recruiter_name company_full_name company_link company_description
graduation_time application_deadline days_per_week minimum_months
job_id captured_at capture_status capture_reason
```

Skills come from the listing API. Detailed addresses, registered company names, company descriptions, graduation requirements, deadlines, and recruiter activity are copied from labelled detail sections. Responsibilities and requirements are extracted only beneath explicit headings. Ambiguous sections remain empty while the full description is retained. Source text spaces and line breaks are preserved.

No raw payloads, whole-page text, duplicate aliases, avatars, logos, tracking parameters, or unapproved job fields are written to output. Temporary browser context remains internal. Every listed job remains in the export, including failures and jobs not attempted. Status is `success`, `partial`, `failed`, or `not_attempted`, with a reason.

CSV uses UTF-8 BOM and stores skill arrays as JSON strings. Default exports do not run legacy `job_summary.py`, statistics, or prompts. No local resume files are read.

Capture runs page by page: read a listing page, process details for its new jobs, publish cumulative JSON/CSV, then load the next page. Reopen the same CSV after each page to read completed details. `--no-detail` updates listings per page; `--max-details` counts across the whole city, and duplicate jobs are not revisited.

CSV snapshots are written completely before atomic replacement, so readers see a complete file. Existing readers may retain an older snapshot and should reopen or refresh. If Windows/Excel locks the destination, the previous CSV stays intact and the latest complete data is saved as `jobs.csv.pending`; each subsequent save retries publication. If still locked at completion, close the reader and replace the CSV with the pending file.

The dedicated persistent profile is `~/.boss-zhipin-scraper/chrome-profile`; main-browser data is not copied by default. Use `--copy-login-state` only when explicitly requested. `--reset-chrome-profile` clears the dedicated login; `--stop-chrome` / `--stop-edge` close only the dedicated profile. Default result directory: `~/.boss-zhipin-scraper/job-result/`.

At most 10 batches per run, with existing request intervals. Manual verification and login walls stop further visits after saving approved fields and remaining-job statuses. `--no-detail` exports listings only; an explicit `--max-details N` retains excess jobs as unattempted.

```bash
python -m unittest tests.test_chrome_setup tests.test_job_summary
python scripts/boss_cdp_raw.py --smoke-test
```
