# OpenTelemetry Collector

The collector accepts OTLP over gRPC and HTTP, applies memory limiting and batching,
adds the cluster resource attribute, and forwards traces to Tempo. Applications should
target its cluster Service. Operate it through Argo CD and test it with
`make validate-observability`.
