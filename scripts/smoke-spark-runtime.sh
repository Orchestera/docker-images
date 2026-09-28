#!/usr/bin/env bash
set -euo pipefail

image=${1:?usage: smoke-spark-runtime.sh <image>}

# This intentionally does not start a Kubernetes cluster or a Spark job. It
# verifies the immutable runtime contract before the image is published; the
# data-plane integration test proves the client-mode driver/executor path.
docker run --rm --entrypoint /bin/sh "${image}" -ceu '
  test -x /opt/entrypoint.sh
  # Pod Security restricted pins runAsUser 185 (orchestera-lib, sparklith-next).
  test "$(id -u):$(id -g)" = "185:185"
  test -w /workspace
  test -w "$HOME"
  test -f "$SPARK_HOME/jars/hadoop-aws-3.3.4.jar"
  test -f "$SPARK_HOME/jars/aws-java-sdk-bundle-1.12.746.jar"
  test -f "$SPARK_HOME/jars/postgresql-42.7.4.jar"
  test -f "$SPARK_HOME/jars/mysql-connector-j-9.1.0.jar"
  test "$(python -c "import pyspark; print(pyspark.__version__)")" = "3.5.6"
  python -c "import marimo, orchestera; assert marimo.__version__ == \"0.24.2\"; print(orchestera.__name__)"
  test "$(python -c "from importlib.metadata import version; print(version(\"orchestera-lib\"))")" = "0.1.0a8"
  # Karpenter must not evict live executors mid-job.
  python -c "from orchestera.kubernetes.pod_spec_builder import build_executor_pod_spec as b; assert b(application_name=\"s\", in_cluster=True, namespace=\"t\")[\"metadata\"][\"annotations\"] == {\"karpenter.sh/do-not-disrupt\": \"true\"}"
  # The notebook AI chat panel: provider clients and the MCP client.
  test "$(python -c "from importlib.metadata import version; print(version(\"pydantic-ai-slim\"))")" = "2.51.0"
  python -c "import mcp, pydantic_ai, anthropic, openai, google.genai; from marimo._server.ai.mcp import get_mcp_client"
  spark-submit --version 2>&1 | grep -F "version 3.5.6"
'
