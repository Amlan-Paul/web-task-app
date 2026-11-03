# WebTask Manager

A lightweight, browser-based website task and release management dashboard. The application uses a static HTML frontend, Cloudflare Pages Functions for centralized Supabase configuration, and Supabase PostgreSQL for shared data storage and Realtime updates.

> **Project status:** This README documents the current implementation in `index.html` and `functions/api/config.js`. It also calls out security limitations that should be addressed before using real or sensitive team data.

---

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Deployment](#deployment)
- [Cloudflare Environment Variables](#cloudflare-environment-variables)
- [Supabase Database Setup](#supabase-database-setup)
- [First Run and Data Initialization](#first-run-and-data-initialization)
- [Authentication and Roles](#authentication-and-roles)
- [How Data Is Stored and Synchronized](#how-data-is-stored-and-synchronized)
- [Application Modules](#application-modules)
- [Administration and Maintenance](#administration-and-maintenance)
- [Troubleshooting](#troubleshooting)
- [Security Notes and Production Checklist](#security-notes-and-production-checklist)
- [Known Implementation Limitations](#known-implementation-limitations)

---

## Features

### Task management
- Kanban board with four workflow states: `To Do`, `In Progress`, `Review`, and `Completed`.
- Task creation, editing, deletion (permission-dependent), and status changes.
- Drag-and-drop task movement where permitted.
- Task fields include title, website page/path, category, status, priority, assignee, target version, due date, last-updated time, and notes.
- Search by task, page/path, or person.
- Filters for assignee, category, and priority.
- Quick filter for the current user's assigned tasks.
- Responsive board and table/list views.

### Website update and release log
- Record version, title, affected page/path, release date, deployment status, and summary.
- Supported release statuses: `Live`, `Staging`, and `Rollback`.
- Filter update records by status.
- Create and delete permissions depend on the current role.

### Analytics
- Dashboard analytics and team workload overview based on application data.

### Audit log
- Records application activities such as logins, task changes, configuration actions, and other tracked events.
- Filter audit entries by action and severity.
- Severity values: `Low`, `Medium`, and `High`.

### Team and role management
- Admin interface for creating, editing, activating/deactivating, and deleting team accounts.
- Roles: `Admin`, `Developer`, `QA`, and `Viewer`.
- Department and last-login information.

### Supabase integration
- Centralized project URL and public API key supplied through Cloudflare Pages environment variables.
- PostgreSQL storage for users, tasks, release logs, and audit logs.
- Manual connection diagnostic.
- Manual initial/local-data seeding action.
- Supabase Realtime subscription to database changes.
- Local browser cache for application data and remembered login state.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, JavaScript |
| UI styling | Tailwind CSS utility classes |
| Database | Supabase PostgreSQL |
| Database API | Supabase JS client / PostgREST fallback |
| Live synchronization | Supabase Realtime |
| Hosting | Cloudflare Pages |
| Server-side configuration | Cloudflare Pages Functions |
| Configuration endpoint | `GET /api/config` |

The application is currently implemented as a primarily single-page frontend in `index.html`.

---

## Architecture

```text
Visitor's browser
       |
       | loads the app
       v
Cloudflare Pages
  ├── index.html
  └── Functions
       └── GET /api/config
                |
                | reads server-side environment variables
                v
       SUPABASE_URL
       SUPABASE_ANON_KEY
                |
                | public client configuration
                v
       Browser initializes Supabase client
                |
                ├── Supabase PostgREST
                |      └── PostgreSQL tables
                |
                └── Supabase Realtime
                       └── database change notifications
```

### Why the configuration endpoint exists

A static HTML file cannot directly read Cloudflare's server-side environment variables. The Pages Function reads those variables and returns the Supabase project URL and **public anon/publishable key** to the browser.

This endpoint is intentionally read-only. It does not provide a way to update Cloudflare configuration from the website.

### Configuration endpoint

- Method: `GET`
- Path: `/api/config`
- Example: `https://YOUR-PAGES-DOMAIN.pages.dev/api/config`
- Successful response:

```json
{
  "url": "https://YOUR-PROJECT-REF.supabase.co",
  "anonKey": "YOUR_SUPABASE_PUBLIC_ANON_KEY"
}
```

The returned anon/publishable key is designed for browser use. Never put a Supabase `service_role` key or secret key in this endpoint or in frontend code.

---

## Project Structure

```text
webtask-manager/
├── index.html
├── functions/
│   └── api/
│       └── config.js
└── README.md
```

- `index.html` — application UI, login screen, role-based interface, task/release/team management, Supabase client logic, and local cache.
- `functions/api/config.js` — Cloudflare Pages Function that exposes the public Supabase client configuration.
- `README.md` — project documentation.

If your repository contains other files, keep them as required by your deployment workflow.

---

## Requirements

Before deployment, prepare:

1. A Cloudflare account with a Pages project.
2. A Supabase account and project.
3. The Supabase project URL.
4. The Supabase anon/public (or publishable) API key.
5. Node.js and npm if deploying with Wrangler CLI.

---

## Deployment

### Option A — Git integration (recommended)

1. Put `index.html` and the `functions/` directory in the root of your Git repository.
2. Push the repository to GitHub or another supported Git provider.
3. In Cloudflare Dashboard, open **Workers & Pages**.
4. Create or open the Pages project and connect the repository.
5. Configure the build settings for a static site:
   - Framework preset: `None` (if no framework is used).
   - Build command: leave empty if no build step is required.
   - Build output directory: the directory containing `index.html` and the `functions/` directory. For a repository-root deployment, use the root directory as the build output where supported by the project setup.
6. Add the environment variables described below.
7. Deploy the project.
8. Verify the configuration endpoint and then open the application.

**Important:** Cloudflare Pages Functions must be included in the deployed Pages project. Uploading only `index.html` using the dashboard's drag-and-drop static upload does not deploy the `functions/` directory.

### Option B — Wrangler CLI

Install Wrangler and authenticate:

```bash
npm install -g wrangler
wrangler login
```

From the directory containing `index.html` and `functions/`, deploy the project:

```bash
wrangler pages deploy . --project-name YOUR_PAGES_PROJECT_NAME
```

Replace `YOUR_PAGES_PROJECT_NAME` with the exact Cloudflare Pages project name.

If your project uses a build output folder, deploy that folder instead. Ensure the `functions/` directory is placed where Cloudflare Pages expects it relative to the deployed output.

### After deployment

1. Open `https://YOUR-PAGES-DOMAIN.pages.dev/api/config`.
2. Confirm that the response contains `url` and `anonKey`.
3. Open the WebTask Manager.
4. Log in and open **Supabase Config**.
5. Use **Connection Test** to check the four database tables.
6. Confirm that the connection status indicates Supabase is connected.

---

## Cloudflare Environment Variables

In Cloudflare Dashboard:

**Workers & Pages → your Pages project → Settings → Variables and Secrets**

Add the following variables:

| Variable | Value | Purpose |
|---|---|---|
| `SUPABASE_URL` | `https://YOUR-PROJECT-REF.supabase.co` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon/public or publishable key | Browser client key |

Add them to the **Production** environment. If you use Preview deployments, configure the corresponding Preview environment too.

After changing environment variables, redeploy the Pages project if Cloudflare requires a new deployment for the changes to take effect.

### Do not add these to the frontend configuration

- `SUPABASE_SERVICE_ROLE_KEY`
- Supabase secret keys
- Database passwords
- Personal access tokens

The current frontend uses the public anon/publishable key. Database access must be protected by correctly designed Supabase security policies.

---

## Supabase Database Setup

### 1. Create a Supabase project

Create a project in the Supabase Dashboard. Keep the database password private.

### 2. Create the application tables

The current application expects these four tables in the `public` schema:

| Table | Purpose |
|---|---|
| `users_database` | Team accounts and role information |
| `tasks_database` | Website tasks and Kanban records |
| `website_updates_log` | Release and website update history |
| `audit_logs` | Application activity history |

The full SQL schema and seed script is embedded in the current `index.html` under **Supabase Config → Supabase SQL Schema & Seed Script**. An Admin can copy or download it from that section.

To run it:

1. Open Supabase Dashboard.
2. Select the project.
3. Open **SQL Editor**.
4. Create a new query.
5. Copy the schema script from the application.
6. Review its security policies before running it.
7. Run the SQL.
8. Return to the application and run **Connection Test**.

### 3. Table fields used by the application

#### `users_database`

| Column | Type / expected content |
|---|---|
| `id` | Text primary key |
| `name` | Text |
| `email` | Unique text |
| `password` | Text in the current implementation |
| `role` | `Admin`, `Developer`, `QA`, or `Viewer` |
| `department` | Text |
| `status` | `Active` or `Inactive` |
| `last_login` | Text |
| `created_at` | Timestamp |

#### `tasks_database`

| Column | Type / expected content |
|---|---|
| `id` | Text primary key |
| `title` | Text |
| `page` | Text; defaults to `/` |
| `category` | Text |
| `status` | `To Do`, `In Progress`, `Review`, or `Completed` |
| `priority` | `High`, `Medium`, or `Low` |
| `assigned_to` | Text |
| `version` | Text |
| `due_date` | Text |
| `last_updated` | Text |
| `notes` | Text |
| `created_at` | Timestamp |

#### `website_updates_log`

| Column | Type / expected content |
|---|---|
| `id` | Text primary key |
| `version` | Text |
| `title` | Text |
| `page` | Text |
| `date` | Text |
| `status` | `Live`, `Staging`, or `Rollback` |
| `summary` | Text |
| `created_at` | Timestamp |

#### `audit_logs`

| Column | Type / expected content |
|---|---|
| `id` | Text primary key |
| `timestamp` | Text |
| `user_name` | Text |
| `user_role` | Text |
| `action_type` | Text |
| `target_item` | Text |
| `details` | Text |
| `severity` | `High`, `Medium`, or `Low` |
| `created_at` | Timestamp |

The SQL embedded in the application also creates indexes and enables Supabase Realtime for the four tables.

---

## First Run and Data Initialization

The frontend contains initial sample records for users, tasks, release updates, and audit entries.

When Supabase is configured:

1. The application requests `/api/config`.
2. It initializes the Supabase client using the returned public configuration.
3. It attempts to fetch records from the four Supabase tables.
4. If remote records exist, those records populate the application state.
5. The browser also maintains a local cache for faster reloads and fallback behavior.

### Initial data seeding

The **Push Data to Supabase** action in the Supabase Config area upserts the currently loaded local application records into the four Supabase tables.

Before using it:

- Confirm that the correct Supabase project is configured.
- Create the tables first.
- Review the local records.
- Back up existing database data.
- Understand that upsert uses each record's `id` as the conflict key and can update matching rows.

Do not use the seed action casually on a database that already contains important production records.

### Local browser storage

The current app stores cached application data and (when Remember Me is enabled) the current user state in browser `localStorage`.

This means:
- Browser cache is local to that browser/profile/device.
- Clearing browser site data may remove the cache and remembered login.
- Shared data across devices depends on successful Supabase synchronization.
- Local cache is not a substitute for database backups.

The Supabase URL and public key are no longer stored in browser `localStorage`; they are loaded from `/api/config`.

---

## Authentication and Roles

The current application has a custom, frontend-managed login flow. It checks the entered email/password against the user records loaded from Supabase or the local fallback records.

### Supported roles

| Role | Main access |
|---|---|
| **Admin** | All tabs; task, release, user, audit, and configuration management |
| **Developer** | Kanban, task list, updates, analytics, and audit; can create/edit/move tasks and create updates |
| **QA** | Kanban, task list, updates, analytics, and audit; can create/edit/move tasks and create updates |
| **Viewer** | Read-only access to Kanban, task list, updates, and analytics |

The exact permissions are defined in `ROLE_PERMISSIONS` inside `index.html`.

### Account status

- `Active` — login is allowed.
- `Inactive` — login is rejected.

### Important authentication warning

This is **not Supabase Auth**. The current login and role checks are implemented in browser JavaScript. They control the user interface but do not independently secure database requests.

Do not treat the current role system as a security boundary for sensitive or private data. See [Security Notes and Production Checklist](#security-notes-and-production-checklist).

---

## How Data Is Stored and Synchronized

### Supabase tables

The frontend reads and writes these tables:

- `users_database`
- `tasks_database`
- `website_updates_log`
- `audit_logs`

The frontend uses Supabase JS when the library is available and includes a direct PostgREST fallback.

### Realtime

The app subscribes to PostgreSQL change events and refreshes data when a change notification is received.

Realtime requires:
- Realtime enabled for the relevant tables/publication.
- Correct Supabase permissions and policies.
- A working browser connection.

Realtime is a convenience for keeping open clients updated; it does not replace proper authorization or conflict handling.

### Manual synchronization

- Use the header **Sync** control to refresh from Supabase.
- Use **Connection Test** in the Supabase Config area to inspect connectivity and table availability.
- Use **Push Data to Supabase** only for an intentional initial/manual seed.

---

## Application Modules

| Module | Description |
|---|---|
| Kanban Board | Workflow columns and task movement |
| Task List | Tabular task view |
| Update Log | Release notes and deployment history |
| Analytics | Task and team metrics |
| Audit Log | Activity records and filters |
| Team & Roles | User account and role administration |
| Supabase Config | Connection diagnostics, SQL setup script, and data seeding |

### Task categories

The current filter UI includes:
- UI/UX
- Bug Fix
- Feature
- Performance
- SEO

### Task priorities

- High
- Medium
- Low

### Task workflow statuses

- To Do
- In Progress
- Review
- Completed

---

## Administration and Maintenance

### Change Supabase project

1. Open Cloudflare Dashboard.
2. Select the Pages project.
3. Open **Settings → Variables and Secrets**.
4. Update `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
5. Trigger a new deployment if needed.
6. Open `/api/config` and verify the returned project URL.
7. Run the application's Connection Test.

### Add or update a team member

Use **Team & Roles** while logged in as Admin. Set the person's name, email, role, department, and account status.

**Security note:** The current implementation stores/checks passwords in its own application table. This must be replaced with Supabase Auth or a trusted server-side authentication system before real accounts are used.

### Backups

Use Supabase's available database backup/export facilities and retain independent backups before schema changes, bulk imports, or seed operations. Cloudflare Pages deployment does not back up Supabase database records.

### Restore demo data

The Supabase Config area includes a **Restore Default Demo Data** action. This restores the frontend's built-in sample state. It is not a database backup restore. Review the action and current data before using it.

---

## Troubleshooting

### `/api/config` returns 404

- Confirm `functions/api/config.js` is included in the deployed project.
- Confirm the Pages project was deployed using Git integration or Wrangler with Functions support.
- Uploading only `index.html` through drag-and-drop does not deploy Pages Functions.
- Confirm the endpoint path is exactly `/api/config`.

### `/api/config` returns 503

The Function cannot find one or both required variables.

- Check `SUPABASE_URL`.
- Check `SUPABASE_ANON_KEY`.
- Confirm they are configured for the correct environment (Production or Preview).
- Redeploy if necessary.

### `/api/config` returns 500

The Function rejects a malformed Supabase URL or a key that appears to be a service-role/secret key.

- Use the project URL format `https://YOUR-PROJECT-REF.supabase.co`.
- Use the anon/public or publishable key.
- Never use a service-role or secret key in this application.

### Supabase connection test fails

Check:

1. The URL and public key returned by `/api/config`.
2. Whether all four tables exist with the expected names.
3. Whether the table columns match the schema.
4. Whether RLS policies permit the intended operation.
5. Whether the browser console and Supabase API response show a permission or schema error.
6. Whether Realtime is enabled if live updates are not arriving.

### Login does not work

- Confirm the user row exists in `users_database`.
- Confirm the email matches.
- Confirm the account status is `Active`.
- Confirm the app can read the users table.
- If the database is empty, inspect the seed process and initial account setup.

### Changes do not appear on another device

- Confirm both devices use the same deployed Pages site and Supabase project.
- Confirm the write request succeeded.
- Confirm the destination table has the new record.
- Check RLS and Realtime configuration.
- Run a manual Sync.

### Old browser data appears

The app keeps a local cache. Clear the site's browser storage only after confirming that the latest intended records are safely stored in Supabase. Clearing local storage can remove cached data and remembered login state.

---

## Security Notes and Production Checklist

> **Important: the current SQL setup script is permissive and the current custom login is not production-grade authentication. Do not put sensitive or confidential team data into this deployment until the security model is redesigned and tested.**

The SQL script currently embedded in `index.html` enables RLS but creates `FOR ALL` policies for both `anon` and `authenticated` with unconditional `USING (true)` and `WITH CHECK (true)` on all four tables. This effectively allows public-key clients broad read/write access. Enabling RLS alone does not make those policies secure.

The current implementation also:
- Stores user passwords as plain text in `users_database`.
- Includes sample/demo user credentials in frontend source and seed SQL.
- Performs login matching and role-based access checks in browser JavaScript.
- Uses the public Supabase key for direct browser database requests.
- Stores cached users and other application records in browser `localStorage`.

### Before production use, complete all of the following

- [ ] Replace the custom password system with Supabase Auth or a trusted server-side authentication flow.
- [ ] Never store plaintext passwords. Use a mature authentication provider; do not invent a client-side password hashing scheme.
- [ ] Remove demo accounts and sample credentials from production data and frontend bundles.
- [ ] Design least-privilege RLS policies based on authenticated user identity and role claims stored in a trusted, non-user-editable location.
- [ ] Remove unconditional public `FOR ALL` policies.
- [ ] Prevent ordinary users from reading or changing other users' password/authentication data.
- [ ] Enforce authorization in the database or trusted server-side functions, not only by hiding UI buttons/tabs.
- [ ] Restrict who can create, edit, delete, or promote users to Admin.
- [ ] Review audit-log write permissions and prevent clients from forging privileged audit entries.
- [ ] Keep service-role and secret keys only in trusted server-side environments; never expose them to the browser.
- [ ] Test policies with separate anonymous, Viewer, QA, Developer, and Admin accounts.
- [ ] Configure backups and test restoration.
- [ ] Review browser storage and session expiry behavior.
- [ ] Add appropriate rate limiting and abuse protection to authentication endpoints.

The `SUPABASE_ANON_KEY` is intentionally public in a browser application. Security must come from Supabase Auth, strict RLS, and server-side authorization—not from hiding the anon key.

---

## Known Implementation Limitations

These are properties of the current source, not promises of future behavior:

1. The app is a single-page HTML/JavaScript application; it does not currently use a frontend build framework.
2. Authentication is custom and client-managed, not Supabase Auth.
3. Role permissions are enforced in the UI code and are not sufficient database authorization.
4. The embedded SQL policies are permissive and must be replaced for production security.
5. Passwords are currently plain text in the application database and demo seed.
6. Browser `localStorage` contains cached records and optional remembered user state.
7. Realtime refreshes data after database changes, but advanced concurrent-edit conflict resolution is not documented as implemented.
8. The Pages Function only returns public Supabase client configuration. It does not proxy database operations or provide private server-side authorization.

---

## License and Contributions

No license or contribution workflow is defined in the current project source. Add a `LICENSE` file and contribution guidelines if the project will be distributed or developed collaboratively.

---

## Quick Reference

| Item | Value |
|---|---|
| Main frontend | `index.html` |
| Pages Function | `functions/api/config.js` |
| Config endpoint | `/api/config` |
| Required Cloudflare variables | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| Database | Supabase PostgreSQL |
| Required tables | `users_database`, `tasks_database`, `website_updates_log`, `audit_logs` |
| Roles | Admin, Developer, QA, Viewer |
| Hosting | Cloudflare Pages |
