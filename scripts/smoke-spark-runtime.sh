#!/usr/bin/env bash
set -euo pipefail

image=${1:?usage: smoke-spark-runtime.sh <image>}

# This intentionally does not start a Kubernetes cluster or a Spark job. It
# verifies the immutable runtime contract before the image is published; the
# data-plane integration test proves the client-mode driver/executor path.
docker run --rm --entrypoint /bin/sh "${image}" -ceu '
  test -x /opt/entrypoint.sh
  test -w /workspace
  test -w "$HOME"
  test -f "$SPARK_HOME/jars/hadoop-aws-3.3.4.jar"
  test -f "$SPARK_HOME/jars/aws-java-sdk-bundle-1.12.746.jar"
  test -f "$SPARK_HOME/jars/postgresql-42.7.4.jar"
  test -f "$SPARK_HOME/jars/mysql-connector-j-9.1.0.jar"
  test "$(python -c "import pyspark; print(pyspark.__version__)")" = "3.5.6"
  python -c "import marimo, orchestera; assert marimo.__version__ == \"0.24.2\"; print(orchestera.__name__)"
  spark-submit --version 2>&1 | grep -F "version 3.5.6"
'
