//go:build integration

package database_test

import (
	"context"
	"os"
	"testing"
	"time"

	"gitlab.com/homelab/sentinel/internal/database"
	"gitlab.com/homelab/sentinel/migrations"
)

func TestStoreRoundTrip(t *testing.T) {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		t.Fatal("DATABASE_URL is required for integration tests")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()

	var store *database.Store
	var err error
	for ctx.Err() == nil {
		store, err = database.Open(ctx, databaseURL)
		if err == nil && store.Ping(ctx) == nil {
			break
		}
		if store != nil {
			store.Close()
		}
		time.Sleep(500 * time.Millisecond)
	}
	if err != nil || store == nil {
		t.Fatalf("connect to PostgreSQL: %v", err)
	}
	defer store.Close()

	if err = store.Migrate(ctx, migrations.Files); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	now := time.Now().UTC().Truncate(time.Microsecond)
	observation := database.Observation{
		ID: "integration-status", Name: "Integration status", Public: true,
		Status: "operational", ObservedAt: now, LatencyMS: 17,
	}
	changed, err := store.RecordObservation(ctx, observation)
	if err != nil {
		t.Fatalf("record first observation: %v", err)
	}
	if !changed {
		t.Fatal("first observation was not recorded as a transition")
	}
	changed, err = store.RecordObservation(ctx, observation)
	if err != nil {
		t.Fatalf("record repeated observation: %v", err)
	}
	if changed {
		t.Fatal("unchanged observation created a second transition")
	}
	statuses, err := store.ListStatuses(ctx)
	if err != nil {
		t.Fatalf("list statuses: %v", err)
	}
	for _, status := range statuses {
		if status.ID == observation.ID && status.Status == observation.Status && status.LatencyMS == observation.LatencyMS {
			return
		}
	}
	t.Fatalf("recorded public status not returned: %#v", statuses)
}
