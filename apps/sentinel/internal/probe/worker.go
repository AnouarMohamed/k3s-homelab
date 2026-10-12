package probe

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"gitlab.com/homelab/sentinel/internal/config"
	"gitlab.com/homelab/sentinel/internal/database"
	"go.opentelemetry.io/otel"
)

type Recorder interface {
	RecordObservation(context.Context, database.Observation) (bool, error)
}

type Worker struct {
	recorder    Recorder
	client      *http.Client
	targets     []config.Target
	interval    time.Duration
	up          *prometheus.GaugeVec
	duration    *prometheus.HistogramVec
	transitions *prometheus.CounterVec
}

func New(recorder Recorder, client *http.Client, targets []config.Target, interval time.Duration, registry *prometheus.Registry) *Worker {
	worker := &Worker{
		recorder: recorder, client: client, targets: targets, interval: interval,
		up:          prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "sentinel_probe_up", Help: "Whether the latest service probe succeeded."}, []string{"service"}),
		duration:    prometheus.NewHistogramVec(prometheus.HistogramOpts{Name: "sentinel_probe_duration_seconds", Help: "Service probe latency.", Buckets: prometheus.DefBuckets}, []string{"service"}),
		transitions: prometheus.NewCounterVec(prometheus.CounterOpts{Name: "sentinel_status_transitions_total", Help: "Recorded service health transitions."}, []string{"service", "status"}),
	}
	registry.MustRegister(worker.up, worker.duration, worker.transitions)
	return worker
}

func (w *Worker) Run(ctx context.Context) error {
	w.runCycle(ctx)
	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			w.runCycle(ctx)
		}
	}
}

func (w *Worker) runCycle(ctx context.Context) {
	for _, target := range w.targets {
		if ctx.Err() != nil {
			return
		}
		w.probe(ctx, target)
	}
}

func (w *Worker) probe(ctx context.Context, target config.Target) {
	ctx, span := otel.Tracer("sentinel-worker").Start(ctx, "probe "+target.ID)
	defer span.End()
	started := time.Now()
	status, message := "operational", ""
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.URL, nil)
	if err == nil {
		var response *http.Response
		response, err = w.client.Do(request)
		if err == nil {
			_, _ = io.CopyN(io.Discard, response.Body, 4096)
			_ = response.Body.Close()
			if response.StatusCode >= 500 {
				status, message = "down", fmt.Sprintf("HTTP %d", response.StatusCode)
			} else if response.StatusCode >= 400 {
				status, message = "degraded", fmt.Sprintf("HTTP %d", response.StatusCode)
			}
		}
	}
	if err != nil {
		status, message = "down", "request failed"
	}
	duration := time.Since(started)
	up := 0.0
	if status == "operational" {
		up = 1
	}
	w.up.WithLabelValues(target.ID).Set(up)
	w.duration.WithLabelValues(target.ID).Observe(duration.Seconds())
	changed, recordErr := w.recorder.RecordObservation(ctx, database.Observation{
		ID: target.ID, Name: target.Name, Public: target.Public, Status: status,
		ObservedAt: time.Now().UTC(), LatencyMS: int(duration.Milliseconds()), Message: message,
	})
	if recordErr != nil {
		slog.ErrorContext(ctx, "record observation", "service", target.ID, "error", recordErr)
		return
	}
	if changed {
		w.transitions.WithLabelValues(target.ID, status).Inc()
		slog.InfoContext(ctx, "service status changed", "service", target.ID, "status", status)
	}
}
