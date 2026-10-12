package database

import (
	"context"
	"fmt"
	"io/fs"
	"sort"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Status struct {
	ID         string    `json:"id"`
	Name       string    `json:"name"`
	Status     string    `json:"status"`
	ObservedAt time.Time `json:"observedAt"`
	LatencyMS  int       `json:"latencyMs"`
}

type Observation struct {
	ID         string
	Name       string
	Public     bool
	Status     string
	ObservedAt time.Time
	LatencyMS  int
	Message    string
}

type Reader interface {
	Ping(context.Context) error
	ListStatuses(context.Context) ([]Status, error)
}

type Store struct {
	pool *pgxpool.Pool
}

func Open(ctx context.Context, databaseURL string) (*Store, error) {
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse database configuration: %w", err)
	}
	config.MaxConns = 8
	config.MinConns = 1
	config.MaxConnLifetime = 30 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("open database pool: %w", err)
	}
	return &Store{pool: pool}, nil
}

func (s *Store) Close() { s.pool.Close() }

func (s *Store) Ping(ctx context.Context) error { return s.pool.Ping(ctx) }

func (s *Store) ListStatuses(ctx context.Context) ([]Status, error) {
	rows, err := s.pool.Query(ctx, `
SELECT s.id, s.display_name, c.status, c.observed_at, c.latency_ms
FROM services AS s
JOIN current_status AS c ON c.service_id = s.id
WHERE s.public = true
ORDER BY s.display_name`)
	if err != nil {
		return nil, fmt.Errorf("query status: %w", err)
	}
	defer rows.Close()

	statuses, err := pgx.CollectRows(rows, pgx.RowToStructByPos[Status])
	if err != nil {
		return nil, fmt.Errorf("collect status: %w", err)
	}
	return statuses, nil
}

func (s *Store) RecordObservation(ctx context.Context, observation Observation) (bool, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return false, fmt.Errorf("begin observation: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if _, err = tx.Exec(ctx, `
INSERT INTO services (id, display_name, public) VALUES ($1, $2, $3)
ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name, public = EXCLUDED.public`,
		observation.ID, observation.Name, observation.Public); err != nil {
		return false, fmt.Errorf("upsert service: %w", err)
	}

	var previous string
	err = tx.QueryRow(ctx, `SELECT status FROM current_status WHERE service_id = $1 FOR UPDATE`, observation.ID).Scan(&previous)
	changed := false
	if err != nil && err != pgx.ErrNoRows {
		return false, fmt.Errorf("read current status: %w", err)
	}
	if err == pgx.ErrNoRows || previous != observation.Status {
		changed = true
		var previousValue any
		if err != pgx.ErrNoRows {
			previousValue = previous
		}
		if _, err = tx.Exec(ctx, `
INSERT INTO status_transitions (service_id, previous_status, status, observed_at, latency_ms, message)
VALUES ($1, $2, $3, $4, $5, $6)`, observation.ID, previousValue, observation.Status,
			observation.ObservedAt, observation.LatencyMS, observation.Message); err != nil {
			return false, fmt.Errorf("insert transition: %w", err)
		}
	}

	if _, err = tx.Exec(ctx, `
INSERT INTO current_status (service_id, status, observed_at, latency_ms, message)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (service_id) DO UPDATE SET status = EXCLUDED.status,
observed_at = EXCLUDED.observed_at, latency_ms = EXCLUDED.latency_ms, message = EXCLUDED.message`,
		observation.ID, observation.Status, observation.ObservedAt, observation.LatencyMS,
		observation.Message); err != nil {
		return false, fmt.Errorf("upsert current status: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return false, fmt.Errorf("commit observation: %w", err)
	}
	return changed, nil
}

func (s *Store) Migrate(ctx context.Context, migrations fs.FS) error {
	connection, err := s.pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("acquire migration connection: %w", err)
	}
	defer connection.Release()
	if _, err = connection.Exec(ctx, `SELECT pg_advisory_lock(hashtext('homelab-sentinel-migrations'))`); err != nil {
		return fmt.Errorf("lock migrations: %w", err)
	}
	defer func() {
		_, _ = connection.Exec(context.Background(), `SELECT pg_advisory_unlock(hashtext('homelab-sentinel-migrations'))`)
	}()
	if _, err = connection.Exec(ctx, `CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())`); err != nil {
		return fmt.Errorf("create migration ledger: %w", err)
	}
	entries, err := fs.ReadDir(migrations, ".")
	if err != nil {
		return fmt.Errorf("list migrations: %w", err)
	}
	sort.Slice(entries, func(i, j int) bool { return entries[i].Name() < entries[j].Name() })
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".sql") {
			continue
		}
		var applied bool
		if err = connection.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = $1)`, entry.Name()).Scan(&applied); err != nil {
			return fmt.Errorf("check migration %s: %w", entry.Name(), err)
		}
		if applied {
			continue
		}
		content, readErr := fs.ReadFile(migrations, entry.Name())
		if readErr != nil {
			return fmt.Errorf("read migration %s: %w", entry.Name(), readErr)
		}
		tx, beginErr := connection.Begin(ctx)
		if beginErr != nil {
			return fmt.Errorf("begin migration %s: %w", entry.Name(), beginErr)
		}
		if _, err = tx.Exec(ctx, string(content)); err == nil {
			_, err = tx.Exec(ctx, `INSERT INTO schema_migrations (version) VALUES ($1)`, entry.Name())
		}
		if err != nil {
			_ = tx.Rollback(ctx)
			return fmt.Errorf("apply migration %s: %w", entry.Name(), err)
		}
		if err = tx.Commit(ctx); err != nil {
			return fmt.Errorf("commit migration %s: %w", entry.Name(), err)
		}
	}
	return nil
}
