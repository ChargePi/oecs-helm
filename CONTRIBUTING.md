# Contributing

## Repo layout

Two independent, independently-versioned charts under `charts/`:

- `charts/oecs-hub` — has subchart dependencies (Memgraph, Valkey).
- `charts/oecs-scraper` — no subchart dependencies.

Each chart's own `README.md` documents its values.

## Making changes

1. `helm dependency update charts/oecs-hub` if you touched anything under `charts/oecs-hub` (pulls the Memgraph/Valkey subchart archives; not needed for `oecs-scraper`).
2. `helm lint charts/<chart>`
3. `helm template ci charts/<chart>` — check the rendered output for what you changed. If you touched the Postgres/Kafka/Memgraph/Valkey wiring, also render with the relevant `*.internal.enabled=false` to check the external-dependency path.
4. Update the chart's `README.md` if you added/renamed a values key.
5. Bump `version` in the chart's `Chart.yaml` for any change that affects rendered output (`appVersion` tracks the app image tag, `version` tracks the chart itself).

## CI

Every PR runs `helm-lint.yaml` (lint + template matrix) and `helm-k3d-deploy.yaml` (throwaway install against a real k3d cluster with the CloudNativePG/Strimzi operators installed) for both charts. Both must pass before merging.

## Releases

Publishing to GHCR (`helm-release.yaml`) runs on a published GitHub Release and packages both charts using the release tag as the chart/app version, independent of whatever is in `Chart.yaml`. Tag as `vX.Y.Z`.

## License

By contributing, you agree your contributions are licensed under this repo's [MIT license](LICENSE.md).
