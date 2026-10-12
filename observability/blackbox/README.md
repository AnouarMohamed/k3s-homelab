# Blackbox exporter

This component performs bounded HTTP health probes for selected internal services. It
has no public route and accepts probe requests only inside the cluster. Operate it
through Argo CD and test its rendered deployment and Probe CR with
`make validate-observability`.
