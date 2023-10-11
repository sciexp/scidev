#!/usr/bin/env bash

set -Eeuo pipefail
set -x

#------
# setup
#------

zenml connect \
  --url "${ZENML_SERVER_URL}" \
  --username "${ZENML_SERVER_USERNAME}" \
  --password "${ZENML_SERVER_PASSWORD}"
zenml stack set "${ZENML_STACK_NAME}"
zenml status

#---------------------------
# export stack configuration
#---------------------------

zenml service-connector describe kubeflow-cluster
zenml service-connector describe gcp-multi-type
zenml container-registry describe gcp-registry
zenml artifact-store describe gcp-store
zenml image-builder describe kaniko
zenml data-validator describe deepchecks-data-validator
zenml experiment-tracker describe mlflow
zenml orchestrator describe kubeflow
zenml stack describe "${ZENML_STACK_NAME}"

zenml stack export "${ZENML_STACK_NAME}" stack-config.yaml
