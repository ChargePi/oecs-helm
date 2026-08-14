# oecs-helm-charts

Helm charts for the OECS platform services.

| Chart      | Path                                 | Source repo                                                                       |
|------------|---------------------------------------|-----------------------------------------------------------------------------------|
| `oecs-hub` | [`charts/oecs-hub`](charts/oecs-hub) | [oecs-registry](https://github.com/ChargePi/oecs-registry) (Go module `oecs-hub`) |

Each chart is independently installable and versioned. See each chart's own `README.md` for its full values reference.

## Cluster prerequisites

`oecs-hub` can optionally provision its own PostgreSQL via CloudNativePG instead of bundling a database Deployment
directly. If you enable `postgresql.internal.enabled`, install the operator **once per cluster** before installing
the chart:

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg -n cnpg-system --create-namespace
```

Redis-compatible caching and the Memgraph graph database are bundled as regular Helm subchart dependencies (Valkey
and Memgraph respectively) and don't need a separate operator.

If you'd rather point at databases you already run elsewhere, leave the operator uninstalled and set the relevant
`*.internal.enabled: false` plus the matching `*.external.*` values — see the chart's `README.md`.

## Quickstart

```bash
helm dependency update charts/oecs-hub
helm install oecs-hub charts/oecs-hub -f my-hub-values.yaml
```

## Installing from GHCR

Tagged GitHub releases publish the chart as an OCI artifact to `ghcr.io/chargepi/charts`:

```bash
helm install oecs-hub oci://ghcr.io/chargepi/charts/oecs-hub --version <x.y.z>
```

The published chart/app version is taken from the release tag (`vX.Y.Z` → `X.Y.Z`), not from
`Chart.yaml`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE.md)
