-- ============================================================================
-- WebTask Manager — Complete Supabase PostgreSQL Setup & Seed Script
-- ============================================================================
-- Instructions:
-- 1. Open your Supabase Project Dashboard (https://supabase.com/dashboard)
-- 2. Go to "SQL Editor" -> Click "New query"
-- 3. Paste this entire script and click "Run" (or press Ctrl/Cmd + Enter)
-- ============================================================================

-- 1. USERS DATABASE TABLE (RBAC Authentication & Team Directory)
CREATE TABLE IF NOT EXISTS public.users_database (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'Viewer' CHECK (role IN ('Admin', 'Developer', 'QA', 'Viewer')),
  department TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive')),
  last_login TEXT DEFAULT '-',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TASKS DATABASE TABLE (Kanban Board & Task Records)
CREATE TABLE IF NOT EXISTS public.tasks_database (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  page TEXT NOT NULL DEFAULT '/',
  category TEXT NOT NULL DEFAULT 'Feature',
  status TEXT NOT NULL DEFAULT 'To Do' CHECK (status IN ('To Do', 'In Progress', 'Review', 'Completed')),
  priority TEXT NOT NULL DEFAULT 'Medium' CHECK (priority IN ('High', 'Medium', 'Low')),
  assigned_to TEXT DEFAULT 'Unassigned',
  version TEXT DEFAULT 'v1.0.0',
  due_date TEXT DEFAULT '',
  last_updated TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. WEBSITE UPDATES LOG TABLE (Deployment & Release Changelog)
CREATE TABLE IF NOT EXISTS public.website_updates_log (
  id TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  title TEXT NOT NULL,
  page TEXT NOT NULL DEFAULT '/all',
  date TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Live' CHECK (status IN ('Live', 'Staging', 'Rollback')),
  summary TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. AUDIT LOGS TABLE (Security & Activity Tracker)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  user_name TEXT NOT NULL,
  user_role TEXT NOT NULL,
  action_type TEXT NOT NULL,
  target_item TEXT NOT NULL,
  details TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'Low' CHECK (severity IN ('High', 'Medium', 'Low')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users_database (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks_database (status);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks_database (assigned_to);
CREATE INDEX IF NOT EXISTS idx_updates_status ON public.website_updates_log (status);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON public.audit_logs (timestamp DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) & POLICIES FOR FRONTEND ANON/AUTHENTICATED CLIENT
-- ============================================================================
ALTER TABLE public.users_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.website_updates_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies safely before recreating
DROP POLICY IF EXISTS "Allow public access to users_database" ON public.users_database;
DROP POLICY IF EXISTS "Allow public access to tasks_database" ON public.tasks_database;
DROP POLICY IF EXISTS "Allow public access to website_updates_log" ON public.website_updates_log;
DROP POLICY IF EXISTS "Allow public access to audit_logs" ON public.audit_logs;

CREATE POLICY "Allow public access to users_database"
  ON public.users_database FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow public access to tasks_database"
  ON public.tasks_database FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow public access to website_updates_log"
  ON public.website_updates_log FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow public access to audit_logs"
  ON public.audit_logs FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- ENABLE REALTIME SUBSCRIPTIONS ON ALL 4 TABLES
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'users_database'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users_database;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'tasks_database'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks_database;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'website_updates_log'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.website_updates_log;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'audit_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_logs;
  END IF;
END $$;

-- ============================================================================
-- SEED DATA: INITIAL TEAM USERS (RBAC Roles)
-- ============================================================================
INSERT INTO public.users_database (id, name, email, password, role, department, status, last_login)
VALUES
  ('USR-01', 'Sadia Islam', 'sadia@webtask.io', 'admin123', 'Admin', 'Product & Admin', 'Active', '2025-02-19 10:15'),
  ('USR-02', 'Tanvir Hasan', 'tanvir@webtask.io', 'dev123', 'Developer', 'Frontend Engineering', 'Active', '2025-02-19 09:40'),
  ('USR-03', 'Rafiq Ahmed', 'rafiq@webtask.io', 'dev123', 'Developer', 'Backend & Payments', 'Active', '2025-02-19 10:00'),
  ('USR-04', 'Nusrat Jahan', 'nusrat@webtask.io', 'qa123', 'QA', 'Quality Assurance', 'Active', '2025-02-18 16:20'),
  ('USR-05', 'Guest Visitor', 'viewer@webtask.io', 'view123', 'Viewer', 'Stakeholder', 'Active', '2025-02-19 08:30')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  password = EXCLUDED.password,
  role = EXCLUDED.role,
  department = EXCLUDED.department,
  status = EXCLUDED.status;

-- ============================================================================
-- SEED DATA: INITIAL TASKS
-- ============================================================================
INSERT INTO public.tasks_database (id, title, page, category, status, priority, assigned_to, version, due_date, last_updated, notes)
VALUES
  ('TSK-101', 'Redesign Hero Section (হোমপেজ হিরো সেকশন রিডিজাইন)', '/home', 'UI/UX', 'Completed', 'High', 'Nusrat Jahan', 'v1.2.0', '2025-02-10', '2025-02-10 14:30', 'Modernized typography, CTA buttons, and responsive grid alignment.'),
  ('TSK-102', 'Fix Mobile Menu Navigation (মোবাইল মেনু ন্যাভিগেশন ফিক্স)', '/header', 'Bug Fix', 'Completed', 'High', 'Tanvir Hasan', 'v1.2.0', '2025-02-12', '2025-02-11 17:45', 'Resolved hamburger toggle freeze and touch event overlay on iOS Safari.'),
  ('TSK-103', 'Integrate Payment Gateway (পেমেন্ট গেটওয়ে ইন্টিগ্রেশন)', '/checkout', 'Feature', 'In Progress', 'High', 'Rafiq Ahmed', 'v1.2.1', '2025-02-25', '2025-02-18 11:15', 'Integrating Stripe Elements API and webhooks for 3D Secure verification.'),
  ('TSK-104', 'Add User Reviews Section (ব্যবহারকারী রিভিউ উইজেট)', '/products', 'Feature', 'In Progress', 'Medium', 'Nusrat Jahan', 'v1.2.1', '2025-02-28', '2025-02-17 16:20', 'Creating star rating component and verified buyer badge styling.'),
  ('TSK-105', 'Optimize Image Loading (ইমেজ অপ্টিমাইজেশন WebP)', '/all', 'Performance', 'Review', 'Medium', 'Tanvir Hasan', 'v1.2.1', '2025-02-22', '2025-02-19 09:40', 'Implemented WebP conversion and lazy loading attributes across all templates.'),
  ('TSK-106', 'SEO Meta Tags Update (ব্লগ ডায়নামিক এসইও মেটা ট্যাগ)', '/blog', 'SEO', 'Review', 'Low', 'Sadia Islam', 'v1.2.1', '2025-02-24', '2025-02-18 15:50', 'Updated Open Graph images, canonical tags, and structured schema markup.'),
  ('TSK-107', 'Checkout Form Autocomplete & Validation', '/checkout', 'Bug Fix', 'To Do', 'Medium', 'Rafiq Ahmed', 'v1.3.0', '2025-03-05', '2025-02-19 10:00', 'Add postal code autofill and inline client-side error states.'),
  ('TSK-108', 'Dark Mode Theme Switcher (ডার্ক মোড থিম সুইচার)', '/all', 'UI/UX', 'To Do', 'Low', 'Sadia Islam', 'v1.3.0', '2025-03-12', '2025-02-19 10:15', 'CSS variables setup for dark color scheme and local storage persistence.')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  page = EXCLUDED.page,
  category = EXCLUDED.category,
  status = EXCLUDED.status,
  priority = EXCLUDED.priority,
  assigned_to = EXCLUDED.assigned_to,
  version = EXCLUDED.version,
  due_date = EXCLUDED.due_date,
  last_updated = EXCLUDED.last_updated,
  notes = EXCLUDED.notes;

-- ============================================================================
-- SEED DATA: INITIAL WEBSITE UPDATES LOG
-- ============================================================================
INSERT INTO public.website_updates_log (id, version, title, page, date, status, summary)
VALUES
  ('LOG-01', 'v1.1.0', 'Core Platform Launch', '/all', '2025-01-15', 'Live', 'Initial release of marketing pages, basic catalog, and responsive layouts.'),
  ('LOG-02', 'v1.1.5', 'Checkout SSL Patch', '/checkout', '2025-01-28', 'Live', 'Enhanced transport security headers and SSL handshake certificate renewal.'),
  ('LOG-03', 'v1.2.0', 'Mobile UX Enhancements', '/home', '2025-02-14', 'Live', 'Deployed new hero visual hierarchy and resolved iOS navigation drawer bugs.'),
  ('LOG-04', 'v1.2.1', 'Payment Gateway & Media Optimization', '/checkout', '2025-02-26', 'Staging', 'Staging build with Stripe 3DS sandbox and WebP responsive image pipeline.'),
  ('LOG-05', 'v1.1.8', 'Legacy Analytics Script Rollback', '/blog', '2025-02-02', 'Rollback', 'Reverted blocking tracking tag causing page speed regression and console errors.')
ON CONFLICT (id) DO UPDATE SET
  version = EXCLUDED.version,
  title = EXCLUDED.title,
  page = EXCLUDED.page,
  date = EXCLUDED.date,
  status = EXCLUDED.status,
  summary = EXCLUDED.summary;

-- ============================================================================
-- SEED DATA: INITIAL AUDIT LOGS
-- ============================================================================
INSERT INTO public.audit_logs (id, timestamp, user_name, user_role, action_type, target_item, details, severity)
VALUES
  ('AUD-208', '2025-02-19 10:00:22', 'Rafiq Ahmed', 'Backend Engineer', 'TASK_CREATE', 'TSK-107', 'Created checkout form autocomplete and validation task targeted for release v1.3.0.', 'Medium'),
  ('AUD-207', '2025-02-19 09:40:05', 'Tanvir Hasan', 'Frontend Engineer', 'STATUS_CHANGE', 'TSK-105', 'Submitted image optimization pull request for review with WebP lazy loading metrics.', 'Low'),
  ('AUD-206', '2025-02-18 15:50:10', 'Sadia Islam', 'SEO Specialist', 'STATUS_CHANGE', 'TSK-106', 'Moved SEO meta tags update to ''Review'' pending Open Graph tag audit.', 'Low'),
  ('AUD-205', '2025-02-18 11:15:30', 'Rafiq Ahmed', 'Backend Engineer', 'CONFIG_CHANGE', 'TSK-103', 'Configured Stripe webhook endpoints and sandbox secret keys for 3D Secure checkout flow.', 'High'),
  ('AUD-204', '2025-02-17 16:20:45', 'Nusrat Jahan', 'UI/UX Designer', 'TASK_UPDATE', 'TSK-104', 'Updated task notes with star rating SVG assets and buyer badge CSS specs.', 'Low'),
  ('AUD-203', '2025-02-15 09:00:00', 'Tanvir Hasan', 'Tech Lead', 'RELEASE_DEPLOY', 'v1.2.0', 'Deployed release package v1.2.0 containing hero section and mobile nav fixes to production.', 'Medium'),
  ('AUD-202', '2025-02-11 17:45:20', 'Tanvir Hasan', 'Frontend Engineer', 'STATUS_CHANGE', 'TSK-102', 'Marked navigation bug fix as ''Completed'' and verified on iOS Safari test devices.', 'Low'),
  ('AUD-201', '2025-02-10 14:30:15', 'Nusrat Jahan', 'UI/UX Designer', 'STATUS_CHANGE', 'TSK-101', 'Changed status from ''In Progress'' to ''Completed'' after hero banner redesign sign-off.', 'Low')
ON CONFLICT (id) DO UPDATE SET
  timestamp = EXCLUDED.timestamp,
  user_name = EXCLUDED.user_name,
  user_role = EXCLUDED.user_role,
  action_type = EXCLUDED.action_type,
  target_item = EXCLUDED.target_item,
  details = EXCLUDED.details,
  severity = EXCLUDED.severity;
