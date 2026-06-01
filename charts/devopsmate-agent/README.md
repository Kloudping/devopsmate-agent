# devopsmate-agent

Secure, lightweight, real-time OpenTelemetry agent for any Kubernetes cluster
(AKS / EKS / GKE / k3s / self-managed). Ships the Datadog-style split:

- **Node agent** (DaemonSet) — host metrics, kubelet/pod metrics, container logs, app OTLP.
- **Cluster agent** (1× Deployment) — cluster metrics + k8s events (single watcher).
- **Beyla** (DaemonSet) — eBPF zero-code traces (optional, on by default).

## Install

```bash
helm repo add devopsmate https://kloudping.github.io/devopsmate-agent && helm repo update

helm upgrade --install devopsmate-agent devopsmate/devopsmate-agent \
  -n devopsmate --create-namespace \
  --set global.tenantId=<TENANT_ID> \
  --set global.env=production \
  --set gateway.endpoint=<GATEWAY_HOST:4317> \
  --set apiKey.value=<AGENT_TOKEN>
```

Keep the token out of shell history by pre-creating a Secret:

```bash
kubectl -n devopsmate create secret generic devopsmate-agent-token --from-literal=api-key=<AGENT_TOKEN>
helm upgrade --install devopsmate-agent devopsmate/devopsmate-agent -n devopsmate --create-namespace \
  --set global.tenantId=<TENANT_ID> --set gateway.endpoint=<GATEWAY_HOST:4317> \
  --set apiKey.existingSecret=devopsmate-agent-token
```

## Footprint profiles

`--set profile=minimal|standard|full` (default `standard`). Lightweight comes from
fewer/cheaper signals + capped CPU/mem (`GOMAXPROCS`/`GOMEMLIMIT`), not from slow
intervals — intervals stay short so monitoring is real-time.

| profile | mem limit | interval | scrapers | Beyla |
|---|---|---|---|---|
| minimal | 128Mi | 15s | core only | off (set `beyla.enabled=true`) |
| standard | 256Mi | 10s | + paging | on |
| full | 512Mi | 5s | + processes | on |

## Security

- Agents authenticate to the gateway with the shared **agent token** (`apiKey`) via
  the stock `bearertokenauth` extension; the gateway enforces it.
- TLS on by default. For an internal not-yet-TLS gateway set
  `gateway.tls.insecure=true` — the token is still required.

## Sending app telemetry

Point your OTLP SDK at the node-agent Service:
`OTEL_EXPORTER_OTLP_ENDPOINT=http://devopsmate-agent.devopsmate.svc.cluster.local:4318`
