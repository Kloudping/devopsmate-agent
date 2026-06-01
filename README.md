# devopsmate-agent

Official OpenTelemetry **agent** distribution for [DevopsMate](https://devopsmate.io) —
secure, lightweight, real-time telemetry (metrics, logs, traces, eBPF) for any
Kubernetes cluster (AKS / EKS / GKE / k3s / self-managed), plus raw manifests for
VM/Docker installs.

This repo is published as a **Helm repository** via GitHub Pages:
<https://kloudping.github.io/devopsmate-agent>

## Install (Kubernetes)

```bash
helm repo add devopsmate https://kloudping.github.io/devopsmate-agent && helm repo update

helm upgrade --install devopsmate-agent devopsmate/devopsmate-agent \
  -n devopsmate --create-namespace \
  --set global.tenantId=<TENANT_ID> \
  --set global.env=production \
  --set profile=standard \
  --set gateway.endpoint=<GATEWAY_HOST:4317> \
  --set apiKey.value=<AGENT_TOKEN>
```

See [charts/devopsmate-agent/README.md](charts/devopsmate-agent/README.md) for all
values, footprint profiles, and the secret-based token variant.

## Layout

```
charts/devopsmate-agent/   Helm chart (node agent + cluster agent + Beyla eBPF, RBAC, Secret)
manifests/                 Raw manifests (otel-agent-k8s, otel-agent-vm, beyla-ebpf-daemonset)
.github/workflows/         chart-releaser -> publishes to gh-pages (the Helm repo)
```

## Publishing (maintainers)

`chart-releaser` runs on every push to `master` that changes `charts/**` (or via
**Actions -> Run workflow**). It packages the chart, creates a GitHub Release, and
updates `index.yaml` on the `gh-pages` branch.

One-time setup:
1. Push to `master` (or run the workflow manually) to create the `gh-pages` branch.
2. **Settings -> Pages -> Source: Deploy from a branch -> `gh-pages` / root.**
3. Bump `charts/devopsmate-agent/Chart.yaml` `version:` for each release (chart-releaser
   only publishes new versions).

## Security

Agents authenticate to the DevopsMate gateway with a shared **agent token**
(`apiKey`) via the stock `bearertokenauth` extension; the gateway enforces it.
The token must equal the gateway's `DEVOPSMATE_AGENT_TOKEN`. Transport is TLS by
default.
