package api

import (
	"context"
	"embed"
	"encoding/json"
	"io/fs"
	"log/slog"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"gitlab.com/homelab/sentinel/internal/database"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

//go:embed assets
var assets embed.FS

type Server struct {
	store    database.Reader
	requests *prometheus.CounterVec
}

func New(store database.Reader, registry *prometheus.Registry) http.Handler {
	server := &Server{
		store: store,
		requests: prometheus.NewCounterVec(prometheus.CounterOpts{
			Name: "sentinel_api_requests_total",
			Help: "Total Sentinel API requests by route and response class.",
		}, []string{"route", "class"}),
	}
	registry.MustRegister(server.requests)
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", server.health)
	mux.HandleFunc("GET /readyz", server.ready)
	mux.HandleFunc("GET /api/v1/status", server.status)
	mux.Handle("GET /metrics", promhttp.HandlerFor(registry, promhttp.HandlerOpts{}))
	assetFS, err := fs.Sub(assets, "assets")
	if err != nil {
		panic(err)
	}
	mux.Handle("GET /", http.FileServer(http.FS(assetFS)))
	return securityHeaders(otelhttp.NewHandler(mux, "sentinel-http"))
}

func (s *Server) health(w http.ResponseWriter, _ *http.Request) {
	s.requests.WithLabelValues("healthz", "2xx").Inc()
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *Server) ready(w http.ResponseWriter, request *http.Request) {
	ctx, cancel := context.WithTimeout(request.Context(), 2*time.Second)
	defer cancel()
	if err := s.store.Ping(ctx); err != nil {
		s.requests.WithLabelValues("readyz", "5xx").Inc()
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "unavailable"})
		return
	}
	s.requests.WithLabelValues("readyz", "2xx").Inc()
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (s *Server) status(w http.ResponseWriter, request *http.Request) {
	ctx, cancel := context.WithTimeout(request.Context(), 3*time.Second)
	defer cancel()
	statuses, err := s.store.ListStatuses(ctx)
	if err != nil {
		slog.ErrorContext(ctx, "list statuses", "error", err)
		s.requests.WithLabelValues("status", "5xx").Inc()
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "status unavailable"})
		return
	}
	s.requests.WithLabelValues("status", "2xx").Inc()
	writeJSON(w, http.StatusOK, map[string]any{"services": statuses, "generatedAt": time.Now().UTC()})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(value); err != nil {
		slog.Error("encode response", "error", err)
	}
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		w.Header().Set("Content-Security-Policy", "default-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
		w.Header().Set("Referrer-Policy", "no-referrer")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		next.ServeHTTP(w, request)
	})
}
