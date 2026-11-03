-- ============================================================================
-- WebTask Manager — Complete Supabase PostgreSQL Setup & Seed Script
-- Run this inside Supabase Dashboard -> SQL Editor -> New Query
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users_database (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks_database (status);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks_database (assigned_to);
CREATE INDEX IF NOT EXISTS idx_updates_status ON public.website_updates_log (status);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON public.audit_logs (timestamp DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.website_updates_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public access to users_database" ON public.users_database;
DROP POLICY IF EXISTS "Allow public access to tasks_database" ON public.tasks_database;
DROP POLICY IF EXISTS "Allow public access to website_updates_log" ON public.website_updates_log;
DROP POLICY IF EXISTS "Allow public access to audit_logs" ON public.audit_logs;

CREATE POLICY "Allow public access to users_database" ON public.users_database FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access to tasks_database" ON public.tasks_database FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access to website_updates_log" ON public.website_updates_log FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access to audit_logs" ON public.audit_logs FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Enable Realtime on all 4 tables
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'users_database') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users_database;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'tasks_database') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks_database;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'website_updates_log') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.website_updates_log;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'audit_logs') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_logs;
  END IF;
END $$;

-- Initial Users Seed
INSERT INTO public.users_database (id, name, email, password, role, department, status, last_login) VALUES
  ('USR-01', 'Sadia Islam', 'sadia@webtask.io', 'admin123', 'Admin', 'Product & Admin', 'Active', '2025-02-19 10:15'),
  ('USR-02', 'Tanvir Hasan', 'tanvir@webtask.io', 'dev123', 'Developer', 'Frontend Engineering', 'Active', '2025-02-19 09:40'),
  ('USR-03', 'Rafiq Ahmed', 'rafiq@webtask.io', 'dev123', 'Developer', 'Backend & Payments', 'Active', '2025-02-19 10:00'),
  ('USR-04', 'Nusrat Jahan', 'nusrat@webtask.io', 'qa123', 'QA', 'Quality Assurance', 'Active', '2025-02-18 16:20'),
  ('USR-05', 'Guest Visitor', 'viewer@webtask.io', 'view123', 'Viewer', 'Stakeholder', 'Active', '2025-02-19 08:30')
ON CONFLICT (id) DO NOTHING;
