CREATE TABLE IF NOT EXISTS services (
    id text PRIMARY KEY,
    display_name text NOT NULL,
    public boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS current_status (
    service_id text PRIMARY KEY REFERENCES services(id) ON DELETE CASCADE,
    status text NOT NULL CHECK (status IN ('operational', 'degraded', 'down')),
    observed_at timestamptz NOT NULL,
    latency_ms integer NOT NULL CHECK (latency_ms >= 0),
    message text NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS status_transitions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    service_id text NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    previous_status text CHECK (previous_status IN ('operational', 'degraded', 'down')),
    status text NOT NULL CHECK (status IN ('operational', 'degraded', 'down')),
    observed_at timestamptz NOT NULL,
    latency_ms integer NOT NULL CHECK (latency_ms >= 0),
    message text NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS status_transitions_service_observed_idx
    ON status_transitions (service_id, observed_at DESC);
