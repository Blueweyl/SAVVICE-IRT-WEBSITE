# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Savvice IRT Website

## Project Overview
Operations website and console for Savvice Corporation's NLEX Incident Response Team (IRT). Static site hosted on GitHub Pages with Supabase (Postgres) backend for auth and data.

**Live URL**: https://blueweyl.github.io/SAVVICE-IRT-WEBSITE/
**Repo**: https://github.com/Blueweyl/SAVVICE-IRT-WEBSITE

## Development
No build step, no package manager, no test suite. To preview changes, open the HTML files directly in a browser or serve the directory with any static file server (e.g. `npx serve` or `python -m http.server`) — auth/Supabase calls work the same either way since `supabase-config.js` points at the live Supabase project. There is no local/staging Supabase instance; all testing hits production data. Deploys happen automatically via GitHub Pages on push to `master`.

## File Structure
```
index.html          — Landing/marketing page (Savvice corporate site)
login.html          — Login + Registration + Pending approval screens
console.html        — Ops Console SPA (all views in one file, ~4000 lines)
styles.css          — Shared styles for index.html only
supabase-config.js  — Supabase client init (URL, publishable key, admin emails)
supabase-setup.sql  — Database schema (run once in Supabase SQL Editor)
```

## Tech Stack
- **Frontend**: Vanilla HTML/CSS/JS (no framework, no build step)
- **Fonts**: Inter + Inter Tight (Google Fonts CDN)
- **Backend**: Supabase (Postgres + Auth + RLS)
- **Hosting**: GitHub Pages (static)
- **Design**: Apple-console inspired, navy + orange accent (#ff6a1a)

## Supabase
- **Project**: dpxrugejdblwqiuveynm (ap-northeast-1)
- **Auth**: Email/Password
- **Tables**: `profiles`, `reports`, `attendance`, `firetruck_checklists`
- **RLS**: Enabled on all tables with `is_admin()` and `is_approved()` helper functions
- New tables added to `supabase-setup.sql` must be run manually by the user in the Supabase SQL Editor — there's no migration runner

### Admin Emails (auto-approve on registration)
Defined in `supabase-config.js` as `ADMIN_EMAILS` array:
- admin@savvice.com
- upupandawey24@gmail.com

## Console Architecture (console.html)
Single-page app with view switching. All CSS is inline in `<style>`, all JS is inline in `<script>`.

### Views (switched via `goTo(viewName)`)
- `dashboard` — KPI cards, charts (plain CSS bars, no charting library), recent activity
- `activity` — IRT incident report form, activity log, summary (3 tabs)
- `attendance` — Upload manpower CSV, mark present/absent for 59 employees
- `firetruck` — Fire truck turnover checklist (form/log/summary 3 tabs), one submission per truck per day
- `manpower` — Auto-populated from `nlex_irt_manpower` array (59 NLEX IRT employees)
- `equipment` — Empty registry (placeholder)
- `billing` — Empty billing (placeholder)
- `reports` — Empty reports (placeholder)
- `admin` — User approval panel (pending/active/rejected)

### Auth Flow
1. `login.html` handles registration + login via Supabase Auth
2. `console.html` has auth guard at top of `<script>` — redirects to login if no session
3. Profile fetched from `profiles` table, role applied via `setRole()`
4. Admin gets "Viewing as" dropdown; non-admin gets static role display
5. Sign out button in sidebar footer

### Key JS Patterns
- `sb` — Supabase client (global, from supabase-config.js)
- `currentUser` — Firebase-style auth user object
- `currentProfile` — Row from `profiles` table
- `irtReports` — Array of reports (loaded from Supabase on init)
- `attendanceData` — Array of 59 employees with status
- `nlex_irt_manpower` — Hardcoded 59-person roster from NLEX IRT Manpower Monitoring Log

### IRT Report Form (5 sections)
Matches the Google Apps Script form at the company's existing workflow:
1. General Information (date, shift, weather, team, leadman)
2. Incident Location (direction toggles, KM post, lanes, traffic flow)
3. Incident Details (vehicle, category, activity, action taken, remarks)
4. Times & Odometer (auto-calculates response/clearing/recovery time)
5. Photo Documentation (5 upload slots, preview only — not persisted)

### Fire Truck Turnover Checklist
Digitizes `QMS-SC-F178-Rev01_1224` (the company's Excel turnover form). One submission covers one truck for one full day, both shifts:
- General info: date, truck (LIMA 1/2/3), plate no.
- ~45 fixed checklist items across 4 categories (`FT_CATEGORIES` array) — each with an expected qty (reference) plus actual-qty inputs for 1st and 2nd shift
- Turnover sign-off both directions (1st→2nd, 2nd→1st: turned over by / notes / received by) plus a Roadway Supervisor validation field
- Upserts to `firetruck_checklists` on conflict `(date, truck)`, so resubmitting the same truck/day edits that row instead of duplicating it

### Dark Mode
Toggle button in Daily Activity view. CSS class `dark-mode` on `.content`. Preference saved to localStorage key `savvice_dark_mode`.

## Data Flow
- **Reports**: Form submit → `saveReportToSupabase()` → Supabase `reports` table → `loadReportsFromSupabase()` refreshes `irtReports` array
- **Attendance**: Mark present/absent → `saveAttendanceToSupabase()` → Supabase `attendance` table (one doc per date, records as JSONB)
- **Fire Truck Checklist**: Form submit → `saveFTToSupabase()` → Supabase `firetruck_checklists` table (upsert on `date,truck`, items as JSONB) → `loadFTChecklistsFromSupabase()` refreshes `ftChecklists` array
- **Users**: Registration → Supabase Auth + `profiles` table insert → Admin approves via `profiles` update

## Export
- **CSV**: `exportLogsCSV()`, `exportSummaryCSV()`, `exportAttendance()` — generates CSV blob and triggers download
- **PDF**: `exportLogsPDF()`, `exportSummaryPDF()` — opens new window with formatted HTML table, triggers `window.print()`

## Conventions
- No build tools, no npm, no bundler — everything runs directly in browser
- Supabase SDK loaded via CDN: `@supabase/supabase-js@2`
- console.html is ~4070 lines total (CSS + HTML + JS all inline in one file)
- Toast notifications via `showToast(msg, type)`
- Empty states show centered icon + message text
