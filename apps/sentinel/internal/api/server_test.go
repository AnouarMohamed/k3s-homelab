package api

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"gitlab.com/homelab/sentinel/internal/database"
)

type fakeStore struct {
	pingErr  error
	statuses []database.Status
}

func (f fakeStore) Ping(context.Context) error                              { return f.pingErr }
func (f fakeStore) ListStatuses(context.Context) ([]database.Status, error) { return f.statuses, nil }

func TestStatusResponseDoesNotExposeTargetURLs(t *testing.T) {
	handler := New(fakeStore{statuses: []database.Status{{ID: "site", Name: "Site", Status: "operational", ObservedAt: time.Unix(1, 0), LatencyMS: 12}}}, prometheus.NewRegistry())
	request := httptest.NewRequest(http.MethodGet, "/api/v1/status", nil)
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
	var body map[string]any
	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if recorder.Header().Get("Content-Security-Policy") == "" {
		t.Fatal("missing content security policy")
	}
}

func TestReadinessFailsClosed(t *testing.T) {
	handler := New(fakeStore{pingErr: errors.New("database unavailable")}, prometheus.NewRegistry())
	request := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("unexpected status: %d", recorder.Code)
	}
}
