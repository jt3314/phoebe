-- Energy Todo App - Supabase Schema
-- Migrated from InstantDB

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE project_type AS ENUM ('personal', 'professional');
CREATE TYPE project_status AS ENUM ('active', 'completed', 'archived');
CREATE TYPE milestone_status AS ENUM ('pending', 'in_progress', 'completed');
CREATE TYPE task_status AS ENUM ('pending', 'scheduled', 'completed');
CREATE TYPE conflict_type AS ENUM ('impossible_deadline', 'overbooked_day', 'dependency_loop');
CREATE TYPE conflict_severity AS ENUM ('critical', 'warning');

-- ============================================================
-- TABLES
-- ============================================================

-- 1. Cycles
CREATE TABLE cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  length INTEGER NOT NULL CHECK (length BETWEEN 1 AND 99),
  day1_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_cycles_user_id ON cycles(user_id);

-- 2. Cycle Effort Points
CREATE TABLE cycle_effort_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  day_number INTEGER NOT NULL CHECK (day_number BETWEEN 1 AND 99),
  effort_points INTEGER NOT NULL CHECK (effort_points >= 0),
  UNIQUE(cycle_id, day_number)
);
CREATE INDEX idx_cep_cycle_id ON cycle_effort_points(cycle_id);

-- 3. Weekend Overrides
CREATE TABLE weekend_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  effort_points INTEGER NOT NULL CHECK (effort_points >= 0),
  UNIQUE(cycle_id, date)
);
CREATE INDEX idx_wo_cycle_id ON weekend_overrides(cycle_id);

-- 4. Projects
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  deadline DATE,
  priority INTEGER NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
  type project_type NOT NULL DEFAULT 'personal',
  weekend_enabled BOOLEAN NOT NULL DEFAULT false,
  status project_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_projects_user_id ON projects(user_id);

-- 5. Milestones
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  target_date DATE,
  status milestone_status NOT NULL DEFAULT 'pending',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_milestones_project_id ON milestones(project_id);

-- 6. Tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  effort_points INTEGER NOT NULL DEFAULT 1 CHECK (effort_points >= 0),
  time_estimate INTEGER, -- minutes
  scheduled_date DATE,
  completed_date DATE,
  status task_status NOT NULL DEFAULT 'pending',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_milestone_id ON tasks(milestone_id);
CREATE INDEX idx_tasks_scheduled_date ON tasks(scheduled_date);

-- 7. Task Dependencies
CREATE TABLE task_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  depends_on_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  UNIQUE(task_id, depends_on_task_id),
  CHECK (task_id != depends_on_task_id)
);
CREATE INDEX idx_td_task_id ON task_dependencies(task_id);

-- 8. Milestone Dependencies
CREATE TABLE milestone_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  milestone_id UUID NOT NULL REFERENCES milestones(id) ON DELETE CASCADE,
  depends_on_milestone_id UUID NOT NULL REFERENCES milestones(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  UNIQUE(milestone_id, depends_on_milestone_id),
  CHECK (milestone_id != depends_on_milestone_id)
);
CREATE INDEX idx_md_milestone_id ON milestone_dependencies(milestone_id);

-- 9. Standalone Tasks
CREATE TABLE standalone_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  effort_points INTEGER NOT NULL DEFAULT 1 CHECK (effort_points >= 0),
  scheduled_date DATE,
  completed_date DATE,
  status task_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_standalone_user_id ON standalone_tasks(user_id);
CREATE INDEX idx_standalone_scheduled_date ON standalone_tasks(scheduled_date);

-- 10. Fixed Events
CREATE TABLE fixed_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  effort_cost INTEGER NOT NULL DEFAULT 0 CHECK (effort_cost >= 0),
  date DATE NOT NULL,
  recurring_pattern JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_fixed_events_user_id ON fixed_events(user_id);
CREATE INDEX idx_fixed_events_date ON fixed_events(date);

-- 11. Sleep Checks
CREATE TABLE sleep_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  slept_poorly BOOLEAN NOT NULL DEFAULT false,
  effort_reduction INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, date)
);
CREATE INDEX idx_sleep_checks_user_date ON sleep_checks(user_id, date);

-- 12. Scheduling Conflicts
CREATE TABLE scheduling_conflicts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  type conflict_type NOT NULL,
  description TEXT NOT NULL,
  affected_dates JSONB, -- array of ISO date strings
  severity conflict_severity NOT NULL DEFAULT 'warning',
  suggestion TEXT,
  resolved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_conflicts_user_id ON scheduling_conflicts(user_id);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cycles_updated_at BEFORE UPDATE ON cycles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER milestones_updated_at BEFORE UPDATE ON milestones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER standalone_tasks_updated_at BEFORE UPDATE ON standalone_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER fixed_events_updated_at BEFORE UPDATE ON fixed_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER conflicts_updated_at BEFORE UPDATE ON scheduling_conflicts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_effort_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekend_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestone_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE standalone_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduling_conflicts ENABLE ROW LEVEL SECURITY;

-- Cycles: direct user_id check
CREATE POLICY cycles_all ON cycles
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Cycle Effort Points: via cycle's user_id
CREATE POLICY cep_all ON cycle_effort_points
  FOR ALL USING (cycle_id IN (SELECT id FROM cycles WHERE user_id = auth.uid()))
  WITH CHECK (cycle_id IN (SELECT id FROM cycles WHERE user_id = auth.uid()));

-- Weekend Overrides: via cycle's user_id
CREATE POLICY wo_all ON weekend_overrides
  FOR ALL USING (cycle_id IN (SELECT id FROM cycles WHERE user_id = auth.uid()))
  WITH CHECK (cycle_id IN (SELECT id FROM cycles WHERE user_id = auth.uid()));

-- Projects: direct user_id check
CREATE POLICY projects_all ON projects
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Milestones: via project's user_id
CREATE POLICY milestones_all ON milestones
  FOR ALL USING (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()))
  WITH CHECK (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()));

-- Tasks: via project's user_id
CREATE POLICY tasks_all ON tasks
  FOR ALL USING (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()))
  WITH CHECK (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()));

-- Task Dependencies: via project's user_id
CREATE POLICY td_all ON task_dependencies
  FOR ALL USING (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()))
  WITH CHECK (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()));

-- Milestone Dependencies: via project's user_id
CREATE POLICY md_all ON milestone_dependencies
  FOR ALL USING (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()))
  WITH CHECK (project_id IN (SELECT id FROM projects WHERE user_id = auth.uid()));

-- Standalone Tasks: direct user_id check
CREATE POLICY standalone_all ON standalone_tasks
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Fixed Events: direct user_id check
CREATE POLICY fixed_events_all ON fixed_events
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Sleep Checks: direct user_id check
CREATE POLICY sleep_checks_all ON sleep_checks
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Scheduling Conflicts: direct user_id check
CREATE POLICY conflicts_all ON scheduling_conflicts
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- ENABLE REALTIME
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE cycles;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE standalone_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE sleep_checks;
ALTER PUBLICATION supabase_realtime ADD TABLE projects;
