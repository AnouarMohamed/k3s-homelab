package migrations

import (
	"strings"
	"testing"
)

func TestInitialMigrationIsEmbedded(t *testing.T) {
	content, err := Files.ReadFile("001_create_status_tables.sql")
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}
	for _, table := range []string{"services", "current_status", "status_transitions"} {
		if !strings.Contains(string(content), "TABLE IF NOT EXISTS "+table) {
			t.Fatalf("migration does not create %s", table)
		}
	}
}
