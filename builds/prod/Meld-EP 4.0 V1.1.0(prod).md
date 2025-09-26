Build: Meld-EP 4.0 V1.1.0(prod).apk
Date: 09-26-2025 14:58:46 UTC

## Major Highlights
- Enabled automatic data refresh whenever a screen gains focus or the user navigates to it.
- Added a pull-to-refresh message at the top of screens that support pull-to-refresh.
- Integrated a reusable rich-text input component and implemented it across the app.
- Added rich-text support in **My Task & Activity > Card > View > Activity Details**.
- Calendar / Time Buddy: new Calendar screen, ICS URL input card, fetch & display ICS data in cards, month/year filters, and create timesheet directly from a meeting (preview subject → select Project > Module > Task > Activity → add timesheet line).
- Added status dropdown in **My Task & Activity** card (change activity status); prevented adding timesheet entries for non-Open activities and prevented changing status to **Open** until activity details are added.
- Replaced **Start/End Date** with **Created/Updated Date** in View Task Activity.

## UI / UX Improvements
- Standardized naming conventions (is/has for booleans, …List for collections, clear handler names, load/build/update patterns) — code-style only, no behavior changes.
- Aligned and grouped imports consistently (Flutter / third-party first, then project imports).
- Reorganized file structure with consistent sections: Variable Declarations, Lifecycle, API Calls & Data Ops, Actions & Event Handlers, UI, UI Helpers, Model for improved readability.
- Improved Apply Leave bottom card: made **Employee Name** header visible and prevented the **Save** button from blocking content.
- Started work to show only necessary header options in Rich Text Field across screens.

## Bug Fixes & Quality
- Fixed project → module filter linkage so selecting a Project updates its Module list correctly. (#9965)
- Fixed reversed text input in Timesheet textbox. (#10015)
- Fixed Timesheet dropdown showing limited values and improved dropdown filtering. (#10016)
- Restored timesheet validation and required-field handling. (#10017)
- Sorted Task dropdown values alphabetically. (#10018)
- Fixed sequential loading and parent-child clearing for Timesheet / My Tasks & Activities filters. (#10019)
- Fixed Leave Type dropdown not closing after selection. (#10026)
- Fixed multiple UI/report issues: missing info icons, placeholder visibility, field colors, edit note bug, forgot-password link not clickable. (#9962, #9963, #9964, #9970, #9972, #9973, #9974)
- Resolved invalid ICS key redirect handling. (#10067)
- Fixed Android 13 navigation issues (manifest and dependency adjustments).

