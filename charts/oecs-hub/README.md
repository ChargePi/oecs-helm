# oecs-hub

Helm chart for OECS hub (source repo `oecs-registry`, Go module `oecs-hub`) — a gRPC registry
service for EV charger/manufacturer data, plus an optional (disabled by default) React/nginx
web frontend.

## Prerequisites

- Kubernetes >= 1.27 (uses native gRPC liveness/readiness probes)
- Helm >= 3.8
- If `postgresql.internal.enabled` (default `true`): the [CloudNativePG](https://cloudnative-pg.io/) operator installed cluster-wide:
  ```bash
  helm repo add cnpg https://cloudnative-pg.github.io/charts
  helm upgrade --install cnpg cnpg/cloudnative-pg -n cnpg-system --create-namespace
  ```
- `helm dependency update` before first install/lint (pulls the bundled Memgraph and Valkey subcharts).

## Known caveat

`oecs-registry/build/service/Dockerfile` currently builds a nonexistent `./cmd/service` path
and its `HEALTHCHECK` assumes an HTTP endpoint that doesn't exist (the service is gRPC-only on
ports 50051/50052). This chart's defaults target the *intended* shape (`./cmd/app` and
`./cmd/migrate`, gRPC health checks) — fix that Dockerfile in the source repo before
`image.repository`/`image.tag` will resolve to a working image.

## Config and secrets

Non-sensitive settings live under `config.*` in `values.yaml` and are rendered into a
ConfigMap as `config.yaml`, mounted at `configMountPath` (default
`/usr/oecs-hub/config`, one of oecs-hub's own absolute config search paths).

Sensitive fields (`secrets.database.dsn`, `secrets.redis.password`,
`secrets.memgraph.username`/`password`, `secrets.profiling.*`) each support:

```yaml
secrets:
  database:
    dsn:
      value: ""                 # chart creates/owns a Secret key for this
      existingSecret: ""        # OR: read from a Secret you manage yourself
      existingSecretKey: "dsn"
```

Leave both `value` and `existingSecret` empty to omit that env var entirely. Anything not
modeled explicitly can be injected via `extraEnv` / `extraEnvFrom`.

## Bundled dependencies (optional, externally-configurable)

| Values key | Default | Behavior when enabled | Behavior when disabled |
|---|---|---|---|
| `postgresql.internal.enabled` | `true` | Creates a CloudNativePG `Cluster`; DSN is auto-sourced from the operator-generated `<fullname>-postgresql-app` Secret's `uri` key (overrides `secrets.database.dsn`). | Set `secrets.database.dsn.value` or `.existingSecret` yourself. |
| `memgraph.enabled` | `true` | Bundles the `memgraph/memgraph` subchart; `config.memgraph.address` auto-derived as `bolt://<release>-memgraph:7687`. | Set `memgraph.address` to your external Bolt endpoint, plus `secrets.memgraph.username`/`password` if needed. |
| `valkey.enabled` | `true` | Bundles the `valkey/valkey` subchart (Redis-protocol cache); `config.redis.address` auto-derived as `<release>-valkey:6379`. | Set `valkey.address` to your external Redis/Valkey endpoint, plus `secrets.redis.password` if needed. |

Extra keys under the `memgraph:` / `valkey:` blocks (besides `enabled`/`address`) pass straight
through to those subcharts' own `values.yaml` — see their upstream docs for the full schema.

## Admin gRPC API

`oecs-hub`'s admin gRPC service (port 50052) has **no built-in authentication**. This chart
always deploys it as `ClusterIP` (never overridable to `LoadBalancer`/`NodePort`) and installs
a `NetworkPolicy` (`adminGrpc.networkPolicy.enabled: true` by default) restricting ingress to
pods in the same namespace. Add `adminGrpc.networkPolicy.extraIngressRules` for a dedicated
ops/admin namespace if needed. Never front it with the chart's `ingress.yaml` (that only
targets the public gRPC-Web port).

## Web frontend

`web.enabled` is `false` by default — the frontend isn't wired up to the real gRPC-Web API yet
(see the `web/` source in oecs-registry). Enable it once that's ready.
