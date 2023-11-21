#!/usr/bin/env bash

set -Eeuo pipefail
# set -x

#------
# setup
#------

zen connect \
  --url "${ZEN_SERVER_URL}" \
  --username "${ZEN_SERVER_USERNAME}" \
  --password "${ZEN_SERVER_PASSWORD}"
zen stack set "${ZEN_STACK_NAME}"
zen status

#---------------------------
# export stack configuration
#---------------------------

zen service-connector describe kubeflow-cluster
zen service-connector describe gcp-multi-type
zen container-registry describe gcp-registry
zen artifact-store describe gcp-store
zen image-builder describe kaniko
zen data-validator describe deepchecks-data-validator
zen experiment-tracker describe mlflow
zen model-registry describe mlflow
zen model-deployer describe mlflow
zen orchestrator describe kubeflow
zen stack describe "${ZEN_STACK_NAME}"

zen stack export "${ZEN_STACK_NAME}" stack-config.yaml
