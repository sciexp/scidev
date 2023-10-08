#!/usr/bin/env bash

set -Eeuo pipefail
set -x

#------
# setup
#------

# connect to remote zenml instance
zenml connect \
  --url "${ZENML_SERVER_URL}" \
  --username "${ZENML_SERVER_USERNAME}" \
  --password "${ZENML_SERVER_PASSWORD}"
zenml status

# set kubeflow kube context
kubectl config current-context
kubectl config use-context "${KUBEFLOW_KUBE_CONTEXT}"
kubectl config current-context

zenml service-connector describe kubeflow-cluster || \
zenml service-connector register kubeflow-cluster \
  --type kubernetes \
  --auto-configure
zenml service-connector update kubeflow-cluster \
  --description "Kubeflow cluster" \
  --label auto=true \
  --label purpose=kubeflow
zenml service-connector verify kubeflow-cluster

# set kube context
kubectl config current-context
kubectl config use-context "${ZENML_KUBE_CONTEXT}"
kubectl config current-context

# setup gcp service connector
# requires GOOGLE_APPLICATION_CREDENTIALS to specify
# the path to a service account key json file
zenml service-connector describe gcp-multi-type || \
zenml service-connector register gcp-multi-type \
  --type gcp \
  --auth-method service-account \
  --project_id="${GCP_PROJECT_ID}" \
  --auto-configure
zenml service-connector update gcp-multi-type \
  --description "Multipurpose GCP connector" \
  --label auto=true \
  --label purpose=multi
zenml service-connector verify gcp-multi-type

#--------------------------
# register stack components
#--------------------------

# register container-registry
gcloud auth configure-docker "${ZENML_CONTAINER_REGISTRY_PREFIX}"
zenml container-registry describe gcp-registry || \
zenml container-registry register \
  gcp-registry --flavor=gcp \
  --uri="${ZENML_CONTAINER_REGISTRY_URI}"
zenml container-registry connect gcp-registry --connector gcp-multi-type

# register artifact-store
zenml artifact-store describe gcp-store || \
zenml artifact-store register \
  gcp-store --flavor=gcp \
  --path="${ZENML_ARTIFACT_STORE_PATH}"
zenml artifact-store connect gcp-store --connector gcp-multi-type

# register image-builder
zenml image-builder describe kaniko || \
zenml image-builder register kaniko \
  --flavor=kaniko \
  --kubernetes_context="${ZENML_KUBE_CONTEXT}" \
  --kubernetes_namespace="kaniko" \
  --service_account_name="kaniko"

# register pipeline orchestrator
zenml orchestrator describe kubeflow || \
zenml orchestrator register kubeflow \
  --flavor=kubeflow \
  --kubeflow_hostname="${KUBEFLOW_HOSTNAME}"
zenml orchestrator connect kubeflow --connector kubeflow-cluster

#--------------------------
# register integrated stack
#--------------------------

zenml stack describe "${ZENML_STACK_NAME}" || \
zenml stack register "${ZENML_STACK_NAME}" \
  --orchestrator=kubeflow \
  --container_registry=gcp-registry \
  --artifact-store=gcp-store \
  --image_builder=kaniko

zenml stack set "${ZENML_STACK_NAME}"
