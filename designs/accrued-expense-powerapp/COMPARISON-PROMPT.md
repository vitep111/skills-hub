# Prompt for a comparison design (paste into any AI model)

> Sanitized — no real company, people, employee IDs, department codes, or
> vendor names. All example data is fictional (Contoso / Northwind / Fabrikam
> style placeholders). Do NOT attach the original legacy screenshot unless you
> have masked the identifying details in it first.

```
You are a senior UI/UX designer. I am modernizing a legacy internal finance
web system called "Accrued Expense" and rebuilding it as a Microsoft Power Apps
CANVAS app. I want you to redesign the UI to be modern, clean, and more usable,
while keeping ALL existing functionality. Then output a single self-contained
HTML file mockup so I can see the design (static draft — buttons do not need to
work). Use only fictional placeholder data (e.g. Contoso, Northwind, Fabrikam)
for any names, vendors, or IDs.

=== HARD CONSTRAINT ===
Every element you design MUST be buildable with native Power Apps canvas
controls (Label, Text input, Dropdown, Combo box, Date picker, Toggle,
Checkbox, Radio, Slider, Button, Icon, Image, Gallery, editable Gallery,
Data table, Edit/Display Form + DataCards, Attachments control, Containers
for layout, Charts, PDF viewer). No CSS/JS-only widgets that Power Apps can't
reproduce. Use only fonts native to Power Apps (Segoe UI, Open Sans, Lato,
Arial). Annotate each major element with the Power Apps control that builds it.

=== THE LEGACY SYSTEM (what exists today) ===
A single dense form page with a left sidebar. Purpose: record expenses that
have been incurred but not yet invoiced, then route them through a multi-step
approval chain.

Left sidebar = role-based menu (each is a different reviewer/queue):
  Requester, Accounts Receivable, PSL Officer, PSL Manager, Line Manager,
  Budget Holder, Cost Controller, Cost Controller Manager,
  Accrued Expense Tracking, Reverse Accrued Tracking.

Main form sections:
1. Request Information: Name + Employee ID (with lookup), Accrued Expense No.
   (auto), Department (auto), Budget Holder (dropdown), Type (dropdown:
   Corporate/JV/etc.), "Import Universal File" checkbox.
2. "Expenditures incurred as of [Month Year] and not yet invoiced" — a wide,
   horizontally-scrolling line-item TABLE. Columns include: Item #, Project
   (dropdown), Company Code/Profit Center, Contract/PO/SO/Inv. No., Vendor No.,
   Vendor Name, Description, Amount, Currency, plus more columns off-screen
   (e.g. tax, amount incl. tax, GL account). Each row can add a per-line
   attachment. Buttons: Choose File / Upload File, Template (download),
   Calculate (totals).
3. Attachment: browse/upload; PDF, JPEG, Excel; max 4 MB per file.
4. Remark: large multi-line text box.
5. Action buttons: Save Draft, Reset, Submit, Cancel, Export Excel.
6. "Accrued Expense: Action Workflow" (collapsible) — the approval chain.
7. "Accrued Expense: Action History" (collapsible) — audit log.

=== WHAT I WANT YOU TO DO ===
1. Keep every field, button, and capability above — nothing may be lost.
2. You MAY add, rename, regroup, or split fields to improve clarity, and add
   supporting screens (e.g. a dashboard/overview, a role-based approval queue,
   a tracking view) if they improve the workflow.
3. Modernize the patterns, for example:
   - Turn the wide scrolling table into a clean editable Gallery with a live
     running total, inline validation, and per-line attachment.
   - Turn the sidebar role items into ONE context-aware "My Approvals" queue
     driven by the signed-in user's role (still supporting every role in the
     routing).
   - Visualize the approval chain as a horizontal stepper and the history as a
     vertical timeline.
   - Replace any hardcoded period text with a proper accounting-period
     month/year picker.
   - Add status chips (Draft/Pending/Approved/Returned), search, and KPI cards.
4. Ensure accessibility & polish: text contrast >= 4.5:1, visible focus states,
   hover transitions 150-300ms, SVG icons (NO emoji as icons), touch targets
   >= 44px, responsive down to tablet, honors prefers-reduced-motion.

=== VISUAL DIRECTION ===
Modern enterprise/finance look. Professional, calm, data-dense but not
cluttered. Suggested palette: teal primary (#0D9488), slate neutrals, semantic
status colors (amber=pending, green=approved, red=rejected/returned). If you
prefer a different palette, justify it briefly. Rounded corners, soft shadows,
clear section headers.

=== DELIVERABLE ===
- One self-contained HTML file (inline CSS/JS, no external CDNs, inline SVG
  icons). Multiple screens shown, switchable via the left nav.
- A short toggle or legend that reveals the Power Apps control mapping per
  element.
- After the HTML, list: (a) fields you added/changed and why, (b) the full
  Power Apps control mapping, (c) any assumptions you made.

Use fictional placeholder data throughout. Make reasonable assumptions for any
missing detail and state them.
```
