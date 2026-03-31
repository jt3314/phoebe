-- Google Calendar events cache
CREATE TABLE google_calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    google_event_id TEXT NOT NULL,
    summary TEXT NOT NULL DEFAULT 'Untitled event',
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    date DATE NOT NULL,
    effort_cost INTEGER NOT NULL DEFAULT 1,
    is_all_day BOOLEAN NOT NULL DEFAULT false,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, google_event_id)
);

-- Index for date-range queries
CREATE INDEX idx_google_calendar_events_user_date ON google_calendar_events(user_id, date);

-- RLS
ALTER TABLE google_calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own Google Calendar events"
    ON google_calendar_events FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
