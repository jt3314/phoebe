-- Phoebe-only events (self-care blocks, energy check-ins, rest blocks)
CREATE TABLE phoebe_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    event_type TEXT NOT NULL DEFAULT 'self_care',
    date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    effort_cost INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for date-range queries
CREATE INDEX idx_phoebe_events_user_date ON phoebe_events(user_id, date);

-- RLS
ALTER TABLE phoebe_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own Phoebe events"
    ON phoebe_events FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
