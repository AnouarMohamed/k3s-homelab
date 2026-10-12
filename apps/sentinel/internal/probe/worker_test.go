package probe

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"gitlab.com/homelab/sentinel/internal/config"
	"gitlab.com/homelab/sentinel/internal/database"
)

type memoryRecorder struct {
	mu           sync.Mutex
	observations []database.Observation
}

func (r *memoryRecorder) RecordObservation(_ context.Context, observation database.Observation) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.observations = append(r.observations, observation)
	return true, nil
}

func TestProbeClassifiesServerFailure(t *testing.T) {
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusBadGateway) }))
	defer server.Close()
	recorder := &memoryRecorder{}
	worker := New(recorder, server.Client(), []config.Target{{ID: "site", Name: "Site", URL: server.URL, Public: true}}, time.Minute, prometheus.NewRegistry())
	worker.runCycle(context.Background())
	if len(recorder.observations) != 1 || recorder.observations[0].Status != "down" {
		t.Fatalf("unexpected observations: %#v", recorder.observations)
	}
}
