# Orchestera public runtime images

`Dockerfile.spark` produces the single public runtime used for an Orchestera
Marimo notebook (the Spark client-mode driver) and every Spark executor it
creates. Deployments must use the published GHCR **digest**, not `latest` or a
version tag:

```text
ghcr.io/orchestera/docker-images/spark@sha256:<published-digest>
```

The runtime is currently `linux/amd64` only. It contains Apache Spark/PySpark
3.5.6, Marimo, `orchestera-lib`, S3A dependencies, and PostgreSQL/MySQL JDBC
drivers. `/opt/entrypoint.sh` remains Apache Spark's executor entrypoint;
Orchestera launches Marimo by overriding the notebook pod command.

## Validation before merge

Pull requests build and smoke-test the image without publishing it. This lets
runtime work be validated before merge. The smoke test checks the non-root
runtime paths, Spark entrypoint, Python packages, and bundled JARs:

```bash
./scripts/smoke-spark-runtime.sh orchestera-spark-runtime:ci
```

The end-to-end Kubernetes driver/executor test belongs to the Orchestera data
plane and uses the exact digest printed by the publishing workflow.

## Publication

Merges touching the runtime and explicit releases publish to public GHCR. The
workflow prints an immutable digest, SBOM, and provenance. It also tags the
source commit; version tags are only conveniences and must be resolved to a
digest before deployment.
