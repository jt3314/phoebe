-- Phoebe: New features migration
-- Adds: cycle phases/seasons, reminders/tips, notes, feature interests, scheduling direction

-- ============================================================
-- ALTER EXISTING TABLES
-- ============================================================

-- Add scheduling direction and seasons toggle to cycles
ALTER TABLE cycles ADD COLUMN IF NOT EXISTS scheduling_direction TEXT NOT NULL DEFAULT 'early';
ALTER TABLE cycles ADD COLUMN IF NOT EXISTS show_seasons BOOLEAN NOT NULL DEFAULT false;

-- Add recurring_pattern to tasks and standalone_tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS recurring_pattern JSONB;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS recurring_override_date TEXT;
ALTER TABLE standalone_tasks ADD COLUMN IF NOT EXISTS recurring_pattern JSONB;
ALTER TABLE standalone_tasks ADD COLUMN IF NOT EXISTS recurring_override_date TEXT;

-- ============================================================
-- NEW TABLES
-- ============================================================

-- Feature interest surveys (BBT, Sport)
CREATE TABLE feature_interests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_type TEXT NOT NULL, -- 'bbt' or 'sport'
  responses JSONB NOT NULL DEFAULT '{}',
  notify_on_launch BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_fi_user ON feature_interests(user_id);

-- Daily notes (user notes tied to specific dates)
CREATE TABLE daily_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, date)
);
CREATE INDEX idx_dn_user_date ON daily_notes(user_id, date);

-- Cycle notes (recurring notes tied to cycle days)
CREATE TABLE cycle_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_day INTEGER NOT NULL CHECK (cycle_day BETWEEN 1 AND 99),
  content TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, cycle_day)
);
CREATE INDEX idx_cn_user ON cycle_notes(user_id);

-- Reminder sources (tip packs)
CREATE TABLE reminder_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  url TEXT,
  icon TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Individual reminders/tips
CREATE TABLE reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID NOT NULL REFERENCES reminder_sources(id) ON DELETE CASCADE,
  category TEXT NOT NULL DEFAULT 'overview', -- overview, energy, fitness, food
  title TEXT NOT NULL,
  body TEXT,
  cycle_day_min INTEGER, -- null = show any day
  cycle_day_max INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_reminders_source ON reminders(source_id);

-- User reminder source preferences
CREATE TABLE user_reminder_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_id UUID NOT NULL REFERENCES reminder_sources(id) ON DELETE CASCADE,
  enabled BOOLEAN NOT NULL DEFAULT true,
  UNIQUE(user_id, source_id)
);
CREATE INDEX idx_urs_user ON user_reminder_sources(user_id);

-- ============================================================
-- TRIGGERS
-- ============================================================

CREATE TRIGGER daily_notes_updated_at BEFORE UPDATE ON daily_notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER cycle_notes_updated_at BEFORE UPDATE ON cycle_notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE feature_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reminder_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY fi_all ON feature_interests
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY dn_all ON daily_notes
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY cn_all ON cycle_notes
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Reminder sources are global (readable by all authenticated users)
CREATE POLICY rs_read ON reminder_sources FOR SELECT USING (true);

-- Reminders are global (readable by all authenticated users)
CREATE POLICY rem_read ON reminders FOR SELECT USING (true);

CREATE POLICY urs_all ON user_reminder_sources
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ============================================================
-- ENABLE REALTIME
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE daily_notes;
ALTER PUBLICATION supabase_realtime ADD TABLE cycle_notes;
